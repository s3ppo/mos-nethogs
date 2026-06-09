<template>
  <div class="pa-4">
    <v-skeleton-loader v-if="loading" :loading="true" type="card" />
    <div v-else style="margin-bottom: 80px">
      <!-- Header -->
      <div class="mb-6">
        <h2 class="text-h5 font-weight-bold mb-2">{{ $t('plugin_nethogs.title') }}</h2>
        <p class="text-body2 text-medium-emphasis">{{ $t('plugin_nethogs.description') }}</p>
      </div>

      <!-- Installation Card (only when not installed) -->
      <v-card v-if="!isInstalled" class="mb-6" elevation="2">
        <v-card-title class="bg-light d-flex align-center flex-wrap gap-3">
          <v-icon large color="primary">mdi-speedometer</v-icon>
          <span>{{ $t('plugin_nethogs.installation') }}</span>
          <v-spacer />
          <v-btn
            color="primary"
            size="large"
            :loading="nethogInstallRunning"
            :disabled="nethogInstallRunning"
            @click="installNethogs"
          >
            <v-icon start>mdi-download</v-icon>
            {{ $t('plugin_nethogs.install') }}
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <div v-if="nethogInstallMessage" class="mb-4">
            <v-alert
              :type="installStatus"
              :icon="`mdi-${getStatusIcon()}`"
              variant="tonal"
              class="mb-3"
            >
              <div class="text-body2">{{ getStatusMessage() }}</div>
            </v-alert>
            <div
              v-if="showOutput"
              class="pa-3 rounded text-monospace text-caption"
              style="
                background: #1e1e1e;
                color: #00ff00;
                max-height: 200px;
                overflow-y: auto;
                border: 1px solid #444;
                font-family: 'Courier New', monospace;
                white-space: pre-wrap;
                word-break: break-word;
              "
            >{{ nethogInstallMessage }}</div>
          </div>
          <div v-else class="text-caption text-medium-emphasis">
            {{ $t('plugin_nethogs.initial_prompt') }}
          </div>
        </v-card-text>

        <!-- Info Sections -->
        <v-card-text class="pa-4 pt-0">
          <div class="row">
            <div class="col-12 col-md-6 mb-4">
              <v-card elevation="1">
                <v-card-title class="text-body2 font-weight-bold pa-3 bg-light">
                  <v-icon start small>mdi-network</v-icon>
                  {{ $t('plugin_nethogs.included_packages') }}
                </v-card-title>
                <v-card-text class="pa-3">
                  <ul class="text-caption" style="margin: 0; padding-left: 20px;">
                    <li>{{ $t('plugin_nethogs.package_nethogs') }}</li>
                    <li>{{ $t('plugin_nethogs.package_iftop') }}</li>
                    <li>{{ $t('plugin_nethogs.package_vnstat') }}</li>
                    <li>{{ $t('plugin_nethogs.package_bmon') }}</li>
                  </ul>
                </v-card-text>
              </v-card>
            </div>
            <div class="col-12 col-md-6 mb-4">
              <v-card elevation="1">
                <v-card-title class="text-body2 font-weight-bold pa-3 bg-light">
                  <v-icon start small>mdi-information-outline</v-icon>
                  {{ $t('plugin_nethogs.information') }}
                </v-card-title>
                <v-card-text class="pa-3 text-caption">
                  <p class="mb-2">{{ $t('plugin_nethogs.installer_runs_at') }}</p>
                  <ul style="margin: 0; padding-left: 20px;">
                    <li>{{ $t('plugin_nethogs.plugin_installation') }}</li>
                    <li>{{ $t('plugin_nethogs.system_start') }}</li>
                    <li>{{ $t('plugin_nethogs.os_updates') }}</li>
                  </ul>
                </v-card-text>
              </v-card>
            </div>
          </div>
        </v-card-text>
      </v-card>

      <!-- Live Traffic Card (only when installed) -->
      <v-card v-else class="mb-6" elevation="2">
        <v-card-title class="bg-light d-flex align-center flex-wrap gap-3">
          <v-icon large color="success">mdi-speedometer</v-icon>
          <div>
            <div>{{ $t('plugin_nethogs.live_traffic') }}</div>
            <div class="text-caption text-medium-emphasis font-weight-regular">
              {{ $t('plugin_nethogs.live_traffic_desc') }}
            </div>
          </div>
          <v-spacer />
          <v-chip color="success" size="small" variant="tonal">
            <v-icon start size="small">mdi-check-circle</v-icon>
            {{ $t('plugin_nethogs.already_installed') }}
          </v-chip>
          <v-btn
            :icon="polling ? 'mdi-pause' : 'mdi-play'"
            size="small"
            variant="text"
            :color="polling ? 'warning' : 'success'"
            @click="togglePolling"
          />
        </v-card-title>

        <v-card-text class="pa-0">
          <!-- Error state -->
          <div v-if="pollingError" class="pa-4">
            <v-alert type="warning" variant="tonal" density="compact">
              {{ $t('plugin_nethogs.polling_error') }}
            </v-alert>
          </div>

          <!-- Table -->
          <v-table v-else density="compact">
            <thead>
              <tr>
                <th>{{ $t('plugin_nethogs.col_program') }}</th>
                <th>{{ $t('plugin_nethogs.col_pid') }}</th>
                <th>{{ $t('plugin_nethogs.col_user') }}</th>
                <th>{{ $t('plugin_nethogs.col_interface') }}</th>
                <th class="text-right">{{ $t('plugin_nethogs.col_sent') }}</th>
                <th class="text-right">{{ $t('plugin_nethogs.col_recv') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="processes.length === 0">
                <td colspan="6" class="text-center text-caption text-medium-emphasis py-4">
                  {{ $t('plugin_nethogs.no_traffic') }}
                </td>
              </tr>
              <tr v-for="proc in processes" :key="proc.pid + proc.program">
                <td class="text-monospace text-caption">{{ shortName(proc.program) }}</td>
                <td class="text-caption">{{ proc.pid }}</td>
                <td class="text-caption">{{ proc.user }}</td>
                <td class="text-caption">{{ proc.interface }}</td>
                <td class="text-right text-caption" :class="proc.sent > 0 ? 'text-warning' : ''">
                  {{ proc.sent.toFixed(3) }}
                </td>
                <td class="text-right text-caption" :class="proc.recv > 0 ? 'text-success' : ''">
                  {{ proc.recv.toFixed(3) }}
                </td>
              </tr>
            </tbody>
          </v-table>

          <div class="pa-3 text-right text-caption text-medium-emphasis">
            {{ $t('plugin_nethogs.last_updated') }}: {{ lastUpdated }}
          </div>
        </v-card-text>
      </v-card>

      <!-- Links -->
      <v-card elevation="1">
        <v-card-text class="pa-3 text-center">
          <a href="https://github.com/netoptimizer/nethogs" target="_blank" class="text-decoration-none mx-2">
            <v-icon small>mdi-github</v-icon>
            {{ $t('plugin_nethogs.github_repository') }}
          </a>
          <span class="text-medium-emphasis mx-2">•</span>
          <a href="https://github.com/s3ppo/mos-nethogs/issues" target="_blank" class="text-decoration-none mx-2">
            <v-icon small>mdi-help-circle-outline</v-icon>
            {{ $t('plugin_nethogs.support') }}
          </a>
        </v-card-text>
      </v-card>
    </div>
  </div>
</template>

<script setup>
import { getCurrentInstance, ref, computed, onMounted, onUnmounted } from 'vue';

const POLL_INTERVAL = 3000;

const loading         = ref(true);
const isInstalled     = ref(false);
const nethogInstallRunning = ref(false);
const nethogInstallMessage = ref('');
const lastExitCode    = ref(null);
const timedOut        = ref(false);
const processes       = ref([]);
const polling         = ref(false);
const pollingError    = ref(false);
const lastUpdated     = ref('—');
let   pollTimer       = null;

const instance = getCurrentInstance();
const t = (key, params = {}) => {
  const translate = instance?.proxy?.$t;
  return typeof translate === 'function' ? translate(key, params) : key;
};

const getAuthHeaders = () => ({
  Authorization: 'Bearer ' + localStorage.getItem('authToken'),
  'Content-Type': 'application/json',
});

const showOutput = computed(() => Boolean(nethogInstallMessage.value));

const installStatus = computed(() => {
  if (timedOut.value) return 'warning';
  if (lastExitCode.value === 0) return 'success';
  if (lastExitCode.value !== null && lastExitCode.value !== 0) return 'error';
  return 'info';
});

const getStatusMessage = () => {
  if (timedOut.value) return t('plugin_nethogs.timeout', { seconds: 600 });
  if (lastExitCode.value === 0) return t('plugin_nethogs.success');
  if (lastExitCode.value !== null && lastExitCode.value !== 0) return t('plugin_nethogs.failed');
  return t('plugin_nethogs.running');
};

const getStatusIcon = () => {
  if (timedOut.value) return 'clock';
  if (lastExitCode.value === 0) return 'check-circle';
  if (lastExitCode.value !== null && lastExitCode.value !== 0) return 'alert-circle';
  return 'information';
};

const shortName = (path) => path.split('/').pop();

// ── Installation status check ──────────────────────────────────────────────
const checkInstallationStatus = async () => {
  try {
    const res = await fetch('/api/v1/mos/plugins/query', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        command: 'mos-nethogs-install',
        args: ['--check-only'],
        timeout: 10,
        parse_json: false,
      }),
    });
    // fall back: treat 2xx with exit_code 0 as installed
    // MOS may not support --check-only; we use which nethogs instead
    const res2 = await fetch('/api/v1/mos/plugins/query', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        command: 'mos-nethogs-query',
        args: [],
        timeout: 10,
        parse_json: false,
      }),
    });
    // if the query command exists and doesn't return "not installed", nethogs is there
    if (res2.ok) {
      const data = await res2.json();
      const output = data.output || '';
      isInstalled.value = !output.includes('"error"');
    } else {
      isInstalled.value = false;
    }
  } catch {
    isInstalled.value = false;
  }
};

// ── Live polling ───────────────────────────────────────────────────────────
const fetchProcesses = async () => {
  try {
    const res = await fetch('/api/v1/mos/plugins/query', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        command: 'mos-nethogs-query',
        args: [],
        timeout: 15,
        parse_json: false,
      }),
    });
    if (!res.ok) { pollingError.value = true; return; }
    const data = await res.json();
    const output = (data.output || '').trim();
    const parsed = JSON.parse(output);
    processes.value = Array.isArray(parsed) ? parsed : [];
    pollingError.value = false;
    const now = new Date();
    lastUpdated.value = now.toLocaleTimeString();
  } catch {
    pollingError.value = true;
  }
};

const startPolling = () => {
  if (pollTimer) return;
  polling.value = true;
  fetchProcesses();
  pollTimer = setInterval(fetchProcesses, POLL_INTERVAL);
};

const stopPolling = () => {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
  polling.value = false;
};

const togglePolling = () => polling.value ? stopPolling() : startPolling();

// ── Install ────────────────────────────────────────────────────────────────
const installNethogs = async () => {
  nethogInstallRunning.value = true;
  nethogInstallMessage.value = '';
  lastExitCode.value = null;
  timedOut.value = false;

  try {
    const res = await fetch('/api/v1/mos/plugins/query', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        command: 'mos-nethogs-install',
        args: [],
        timeout: 600,
        parse_json: false,
      }),
    });
    const data = await res.json();

    nethogInstallMessage.value = data.output || (res.ok ? t('plugin_nethogs.install_complete') : t('plugin_nethogs.install_failed'));
    lastExitCode.value = typeof data.exit_code === 'number' ? data.exit_code : (res.ok ? 0 : 1);
    timedOut.value = Boolean(data.timed_out);

    if (lastExitCode.value === 0) {
      await checkInstallationStatus();
      if (isInstalled.value) startPolling();
    }
  } catch (e) {
    nethogInstallMessage.value = `${t('plugin_nethogs.error_prefix')}: ${e.message}`;
    lastExitCode.value = 1;
  } finally {
    nethogInstallRunning.value = false;
  }
};

// ── Lifecycle ──────────────────────────────────────────────────────────────
onMounted(async () => {
  try {
    await checkInstallationStatus();
    if (isInstalled.value) startPolling();
  } catch {
    isInstalled.value = false;
  } finally {
    loading.value = false;
  }
});

onUnmounted(() => stopPolling());
</script>

<style scoped>
:deep(.bg-light) {
  background-color: rgba(0, 0, 0, 0.04);
}
.text-monospace {
  font-family: 'Courier New', 'Monaco', monospace;
}
a {
  color: rgb(25, 118, 210);
  text-decoration: none;
  transition: color 0.2s;
}
a:hover {
  color: rgb(13, 71, 161);
  text-decoration: underline;
}
</style>