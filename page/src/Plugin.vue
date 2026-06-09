<template>
  <div class="pa-4">
    <v-skeleton-loader v-if="loading" :loading="true" type="card" />
    <div v-else style="margin-bottom: 80px">
      <!-- Header -->
      <div class="mb-6">
        <h2 class="text-h5 font-weight-bold mb-2">{{ $t('plugin_nethogs.title') }}</h2>
        <p class="text-body2 text-medium-emphasis">{{ $t('plugin_nethogs.description') }}</p>
      </div>

      <!-- Main Action Card -->
      <v-card class="mb-6" elevation="2">
        <v-card-title class="bg-light d-flex align-center flex-wrap gap-3">
          <v-icon large color="primary">mdi-speedometer</v-icon>
          <span>{{ $t('plugin_nethogs.installation') }}</span>
          <v-spacer />
          <v-btn 
            v-if="!isInstalled"
            color="primary" 
            size="large"
            :loading="nethogInstallRunning" 
            @click="installNethogs"
            :disabled="nethogInstallRunning"
          >
            <v-icon start>mdi-download</v-icon>
            {{ $t('plugin_nethogs.install') }}
          </v-btn>
          <v-btn 
            v-else
            color="success" 
            size="large"
            disabled
          >
            <v-icon start>mdi-check-circle</v-icon>
            {{ $t('plugin_nethogs.already_installed') }}
          </v-btn>
        </v-card-title>

        <!-- Status/Output -->
        <v-card-text class="pa-4">
          <div v-if="nethogInstallMessage" class="mb-4">
            <v-alert 
              :type="installStatus"
              :icon="`mdi-${getStatusIcon()}`"
              variant="tonal"
              class="mb-3"
            >
              <div class="text-body2">
                {{ getStatusMessage() }}
              </div>
            </v-alert>

            <!-- Output Box -->
            <div 
              v-if="showOutput"
              class="bg-surface-dark pa-3 rounded text-monospace text-caption"
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
            >
              {{ nethogInstallMessage }}
            </div>
          </div>
          <div v-else class="text-caption text-medium-emphasis">
            {{ $t('plugin_nethogs.initial_prompt') }}
          </div>
        </v-card-text>
      </v-card>

      <!-- Info Sections -->
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
                <li>{{ $t('plugin_nethogs.package_nethogs_docs') }}</li>
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
              <p class="mb-2">
                {{ $t('plugin_nethogs.installer_runs_at') }}
              </p>
              <ul style="margin: 0; padding-left: 20px;">
                <li>{{ $t('plugin_nethogs.plugin_installation') }}</li>
                <li>{{ $t('plugin_nethogs.system_start') }}</li>
                <li>{{ $t('plugin_nethogs.os_updates') }}</li>
              </ul>
            </v-card-text>
          </v-card>
        </div>
      </div>

      <!-- Links -->
      <v-card class="mt-4" elevation="1">
        <v-card-text class="pa-3 text-center">
          <a href="https://github.com/netoptimizer/nethogs" target="_blank" class="text-decoration-none mx-2">
            <v-icon small>mdi-github</v-icon>
            {{ $t('plugin_nethogs.github_repository') }}
          </a>
          <span class="text-medium-emphasis mx-2">•</span>
          <a href="https://github.com/netoptimizer/nethogs/issues" target="_blank" class="text-decoration-none mx-2">
            <v-icon small>mdi-help-circle-outline</v-icon>
            {{ $t('plugin_nethogs.support') }}
          </a>
        </v-card-text>
      </v-card>
    </div>
  </div>
</template>

<script setup>
import { getCurrentInstance, ref, onMounted, computed } from 'vue';

const loading = ref(true);
const nethogInstallRunning = ref(false);
const nethogInstallMessage = ref('');
const lastExitCode = ref(null);
const timedOut = ref(false);
const isInstalled = ref(false);

const instance = getCurrentInstance();

const t = (key, params = {}) => {
  const translate = instance?.proxy?.$t;
  if (typeof translate === 'function') {
    return translate(key, params);
  }

  return key;
};

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

const getAuthHeaders = () => ({
  Authorization: 'Bearer ' + localStorage.getItem('authToken'),
});

const checkInstallationStatus = async () => {
  try {
    const res = await fetch('/api/v1/mos/plugins/query', {
      method: 'POST',
      headers: { ...getAuthHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({
        command: 'which',
        args: ['nethogs'],
        timeout: 10,
        parse_json: false,
      }),
    });

    const data = await res.json();
    isInstalled.value = res.ok && data.exit_code === 0;
  } catch (e) {
    console.debug('Could not check installation status:', e);
    isInstalled.value = false;
  }
};

const installNethogs = async () => {
  nethogInstallRunning.value = true;
  nethogInstallMessage.value = '';
  lastExitCode.value = null;
  timedOut.value = false;

  try {
    const res = await fetch('/api/v1/mos/plugins/query', {
      method: 'POST',
      headers: { ...getAuthHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({
        command: 'mos-nethogs-install',
        args: [],
        timeout: 600,
        parse_json: false,
      }),
    });

    const data = await res.json();

    if (!res.ok) {
      nethogInstallMessage.value = data.output || data.message || t('plugin_nethogs.install_failed');
      lastExitCode.value = typeof data.exit_code === 'number' ? data.exit_code : 1;
      timedOut.value = Boolean(data.timed_out);
      return;
    }

    nethogInstallMessage.value = data.output || t('plugin_nethogs.install_complete');
    lastExitCode.value = typeof data.exit_code === 'number' ? data.exit_code : 0;
    timedOut.value = Boolean(data.timed_out);
    
    // Re-check installation status after successful install
    if (lastExitCode.value === 0) {
      await checkInstallationStatus();
    }
  } catch (e) {
    console.error('Failed to install Nethogs:', e);
    nethogInstallMessage.value = `${t('plugin_nethogs.error_prefix')}: ${e.message}`;
    lastExitCode.value = 1;
  } finally {
    nethogInstallRunning.value = false;
  }
};

onMounted(async () => {
  try {
    await checkInstallationStatus();
  } catch (error) {
    console.error('Failed to check installation status:', error);
    isInstalled.value = false;
  } finally {
    loading.value = false;
  }
});
</script>

<style scoped>
:deep(.bg-light) {
  background-color: rgba(0, 0, 0, 0.04);
}

:deep(.bg-surface-dark) {
  background-color: #1e1e1e;
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
