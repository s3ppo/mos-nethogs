<template>
  <div>
    <h2 class="mb-4">Processes</h2>
    <v-skeleton-loader v-if="loading" :loading="true" type="table" />
    <div v-else style="margin-bottom: 80px">
      <v-card class="pa-0">
        <v-card-title class="d-flex align-center gap-2 flex-wrap">
          <span class="text-body-1">{{ processes.length }} processes</span>
          <v-spacer />
          <v-text-field
            v-model="search"
            density="compact"
            hide-details
            placeholder="Filter..."
            prepend-inner-icon="mdi-magnify"
            style="max-width: 220px"
            clearable
          />
        </v-card-title>
        <v-card-text class="pa-0">
          <v-table density="compact" fixed-header height="600px">
            <thead>
              <tr>
                <th
                  v-for="col in columns"
                  :key="col.field"
                  :style="col.sortable ? 'cursor: pointer; user-select: none' : ''"
                  @click="col.sortable ? toggleSort(col.field) : null"
                >
                  {{ col.label }}
                  <v-icon v-if="sortField === col.field" size="x-small">
                    {{ sortDesc ? 'mdi-arrow-down' : 'mdi-arrow-up' }}
                  </v-icon>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="proc in filteredProcesses" :key="proc.pid">
                <td>{{ proc.pid }}</td>
                <td>{{ proc.tty }}</td>
                <td>{{ proc.state }}</td>
                <td>{{ proc.time }}</td>
                <td class="text-truncate" style="max-width: 320px">{{ proc.name }}</td>
              </tr>
              <tr v-if="filteredProcesses.length === 0">
                <td colspan="5" class="text-center text-grey pa-4">No processes found</td>
              </tr>
            </tbody>
          </v-table>
        </v-card-text>
      </v-card>

      <v-alert v-if="error" type="error" class="mt-4" density="compact">{{ error }}</v-alert>
    </div>

    <v-dialog v-model="settingsDialog.value" max-width="400">
      <v-card class="pa-0">
        <v-card-title>Settings</v-card-title>
        <v-card-text>
          <v-form>
            <v-text-field
              v-model.number="settingsDialog.interval"
              label="Update interval (seconds)"
              type="number"
              min="1"
              @blur="validateInterval"
            />
          </v-form>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn color="onPrimary" @click="settingsDialog.value = false">Cancel</v-btn>
          <v-btn color="onPrimary" @click="saveSettings" :loading="settingsDialog.saving">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-fab color="primary" style="position: fixed; bottom: 32px; right: 32px; z-index: 1000" size="large" icon @click="openSettingsDialog">
      <v-icon>mdi-cog</v-icon>
    </v-fab>
  </div>
</template>

<script setup>
import { ref, computed, reactive, onMounted, onUnmounted } from 'vue';

const loading = ref(true);
const error = ref(null);
const processes = ref([]);
const search = ref('');
const sortField = ref('pid');
const sortDesc = ref(false);
const settings = ref({ interval: 5 });
let pollInterval = null;

const settingsDialog = reactive({
  value: false,
  interval: 5,
  saving: false,
});

const columns = [
  { field: 'pid', label: 'PID', sortable: true },
  { field: 'tty', label: 'TTY', sortable: false },
  { field: 'state', label: 'STAT', sortable: false },
  { field: 'time', label: 'TIME', sortable: false },
  { field: 'name', label: 'COMMAND', sortable: false },
];

const getAuthHeaders = () => ({
  Authorization: 'Bearer ' + localStorage.getItem('authToken'),
});

const validateInterval = () => {
  if (settingsDialog.interval < 1) settingsDialog.interval = 1;
};

const toggleSort = (field) => {
  if (sortField.value === field) {
    sortDesc.value = !sortDesc.value;
  } else {
    sortField.value = field;
    sortDesc.value = true;
  }
};

const filteredProcesses = computed(() => {
  let procs = [...processes.value];
  if (search.value) {
    const q = search.value.toLowerCase();
    procs = procs.filter(
      (p) =>
        String(p.pid).includes(q) ||
        (p.name ?? '').toLowerCase().includes(q)
    );
  }
  procs.sort((a, b) => {
    const va = a[sortField.value] ?? 0;
    const vb = b[sortField.value] ?? 0;
    if (typeof va === 'number' && typeof vb === 'number') {
      return sortDesc.value ? vb - va : va - vb;
    }
    return sortDesc.value
      ? String(vb).localeCompare(String(va))
      : String(va).localeCompare(String(vb));
  });
  return procs;
});

const fetchSettings = async () => {
  try {
    const res = await fetch('/api/v1/mos/plugins/settings/mos-htop', {
      headers: getAuthHeaders(),
    });
    if (res.ok) {
      const data = await res.json();
      settings.value = { interval: data.interval || 5 };
    }
  } catch (e) {
    console.error('Failed to fetch settings:', e);
  }
};

const parsePsOutput = (output) => {
  const lines = output.trim().split('\n');
  const procs = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    const parts = line.split(/\s+/);
    if (parts.length < 5 || !/^\d+$/.test(parts[0])) continue;
    procs.push({
      pid: parseInt(parts[0]),
      tty: parts[1],
      state: parts[2],
      time: parts[3],
      name: parts.slice(4).join(' '),
    });
  }
  return procs;
};

const fetchProcesses = async () => {
  try {
    const res = await fetch('/api/v1/mos/plugins/query', {
      method: 'POST',
      headers: { ...getAuthHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({
        command: 'mos-htop-query',
        args: [],
        timeout: 10,
        parse_json: true,
      }),
    });
    if (res.ok) {
      const data = await res.json();
      error.value = null;
      const output = data.output;
      if (Array.isArray(output)) {
        processes.value = output;
      } else if (Array.isArray(output?.processes)) {
        processes.value = output.processes;
      } else {
        processes.value = parsePsOutput(typeof output === 'string' ? output : JSON.stringify(output));
      }
    } else {
      const data = await res.json().catch(() => ({}));
      error.value = data.error ?? `API error: ${res.status}`;
    }
  } catch (e) {
    error.value = e.message;
    console.error('Failed to fetch processes:', e);
  }
};

const startPolling = () => {
  stopPolling();
  const interval = Math.max(1, settings.value.interval) * 1000;
  pollInterval = setInterval(fetchProcesses, interval);
};

const stopPolling = () => {
  if (pollInterval) {
    clearInterval(pollInterval);
    pollInterval = null;
  }
};

const openSettingsDialog = () => {
  settingsDialog.interval = settings.value.interval;
  settingsDialog.saving = false;
  settingsDialog.value = true;
};

const saveSettings = async () => {
  settingsDialog.saving = true;
  validateInterval();
  try {
    const res = await fetch('/api/v1/mos/plugins/settings/mos-htop', {
      method: 'POST',
      headers: { ...getAuthHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ interval: settingsDialog.interval }),
    });
    if (res.ok) {
      settings.value = { interval: settingsDialog.interval };
      settingsDialog.value = false;
      startPolling();
    }
  } catch (e) {
    console.error('Failed to save settings:', e);
  } finally {
    settingsDialog.saving = false;
  }
};

onMounted(async () => {
  try {
    await fetchSettings();
    await fetchProcesses();
  } catch (e) {
    console.error('Failed to initialize:', e);
  } finally {
    loading.value = false;
  }
  startPolling();
});

onUnmounted(() => {
  stopPolling();
});
</script>
