#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
SCRIPT_VERSION="2026-06-09"

# Core package for nethogs
PACKAGES=(
  nethogs
  iftop
  vnstat
  bmon
)

log() {
  echo "[mos-nethogs] $*"
}

report_system_info() {
  log "System Information:"
  log "  Kernel: $(uname -r)"
  log "  Hostname: $(hostname)"
  if command -v lsb_release >/dev/null 2>&1; then
    log "  Distribution: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
  fi
}

detect_network_interfaces() {
  local ifaces
  ifaces="$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v '^lo$' | tr '\n' ',' | sed 's/,$//')"

  if [[ -n "${ifaces}" ]]; then
    log "Network Interface(s) detected: ${ifaces}"
    return
  fi

  log "No network interfaces detected."
}

if [[ "${EUID}" -ne 0 ]]; then
  log "This script must be run as root."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  log "apt-get is not available. Nethogs installation skipped."
  exit 1
fi

log "Installer version: ${SCRIPT_VERSION}"
report_system_info
detect_network_interfaces

log "Updating package lists..."
if ! apt-get update >/dev/null 2>&1; then
  log "Error during apt-get update (dpkg locked?). Will retry later."
  exit 0
fi

AVAILABLE_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    AVAILABLE_PACKAGES+=("$pkg")
  else
    log "Package not available, skipping: $pkg"
  fi
done

if [[ "${#AVAILABLE_PACKAGES[@]}" -eq 0 ]]; then
  log "No installable packages found."
  exit 0
fi

log "Installing Nethogs and network monitoring tools..."
if ! apt-get install -y --no-install-recommends "${AVAILABLE_PACKAGES[@]}" 2>&1; then
  log "Error during installation (dpkg locked?). Will retry later."
  exit 0
fi

log "Installation completed successfully."
log "You can now use nethogs to monitor network traffic:"
log "  nethogs          - Per-process network monitor"
log "  iftop -i eth0    - Interactive network bandwidth monitor"
log "  vnstat           - Network traffic statistics"
log "  bmon             - Visual bandwidth monitor"
log ""
log "To run nethogs, use: sudo nethogs"

exit 0
