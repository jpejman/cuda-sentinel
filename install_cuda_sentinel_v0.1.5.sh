#!/bin/bash
# install_cuda_sentinel_v0.1.5-patch1.sh
# CUDA Sentinel Installer v0.1.5-patch1
# Fixes: proposal directory creation, full directory scaffolding, safer systemd generation,
# improved logging, NVIDIA driver validation, smoke-test readiness.

set -Eeuo pipefail

APP_DIR="/opt/cuda-sentinel"
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/cuda-sentinel"
SYSTEMD_DIR="/etc/systemd/system"
SERVICE_FILE="$SYSTEMD_DIR/cuda-sentinel.service"
API_SERVICE_FILE="$SYSTEMD_DIR/cuda-sentinel-api.service"
PROPOSAL_DIR="$APP_DIR/proposals"
UTILS_DIR="$APP_DIR/utils"
FIXPROPOSAL_DIR="$APP_DIR/fix_proposals"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BACKUP_DIR="/opt/cuda-sentinel-v0.1.5-backup-${TIMESTAMP}"

log() {
    echo "[+] $1"
}
warn() {
    echo "[!] $1" >&2
}
success() {
    echo "[+] $1"
}

if [[ "${EUID}" -ne 0 ]]; then
    warn "Run this installer as root, for example: sudo bash $0"
    exit 1
fi

for required_command in cp date mkdir python3 systemctl; do
    if ! command -v "${required_command}" >/dev/null 2>&1; then
        warn "Required command not found: ${required_command}"
        exit 1
    fi
done

echo
log "CUDA Sentinel Installer - Version v0.1.5-patch1"
echo

# ----------------------------------------------------
# STEP 1 — BACKUP EXISTING INSTALL
# ----------------------------------------------------
if [ -d "$APP_DIR" ]; then
    warn "Previous installation detected. Creating backup at $BACKUP_DIR"
    cp -a "$APP_DIR" "$BACKUP_DIR"
    success "Backup created: $BACKUP_DIR"
fi

# ----------------------------------------------------
# STEP 2 — ENSURE REQUIRED DIRECTORIES
# ----------------------------------------------------
log "Ensuring required directory structure..."

mkdir -p "$APP_DIR" \
         "$PROPOSAL_DIR" \
         "$UTILS_DIR" \
         "$FIXPROPOSAL_DIR"

success "Directory tree ensured: $APP_DIR"

# ----------------------------------------------------
# STEP 3 — ENSURE LOG DIRECTORY
# ----------------------------------------------------
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/install.log"
success "Log directory ready at: $LOG_DIR"

# ----------------------------------------------------
# STEP 4 — INSTALL APPLICATION RUNTIME
# ----------------------------------------------------
if [[ ! -d "$SOURCE_DIR/cuda_sentinel" ]]; then
    warn "Runtime package missing from installer source: $SOURCE_DIR/cuda_sentinel"
    exit 1
fi
cp -a "$SOURCE_DIR/cuda_sentinel" "$APP_DIR/"
if [[ ! -f "$APP_DIR/cuda_sentinel/agent_runner.py" ]]; then
    warn "Runtime agent entrypoint missing after installation."
    exit 1
fi
success "Runtime package installed."

# ----------------------------------------------------
# STEP 5 — BACKFILL FIX PROPOSAL IF MISSING
# ----------------------------------------------------
if [ ! -f "$PROPOSAL_DIR/fix_nvidia_driver.sh" ]; then
    log "Backfilling missing fix_nvidia_driver.sh..."

    cat << 'EOF' > "$PROPOSAL_DIR/fix_nvidia_driver.sh"
#!/bin/bash
# fix_nvidia_driver.sh — repairs missing or broken NVIDIA drivers

LOG_FILE="/var/log/cuda-sentinel/fix_nvidia_driver.log"
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Running fix_nvidia_driver.sh" | tee -a "$LOG_FILE"

ubuntu-drivers devices | tee -a "$LOG_FILE"

echo -e "\nChoose option:\n1) Auto install recommended\n2) Install latest driver (535)\n3) Quit"
read -p "Enter choice [1-3]: " choice

case "$choice" in
    1) sudo ubuntu-drivers autoinstall | tee -a "$LOG_FILE" ;;
    2) sudo apt install -y nvidia-driver-535 | tee -a "$LOG_FILE" ;;
    *) echo "Aborted." | tee -a "$LOG_FILE" ;;
esac
EOF

    chmod +x "$PROPOSAL_DIR/fix_nvidia_driver.sh"
    success "Fix proposal created: fix_nvidia_driver.sh"
else
    success "fix_nvidia_driver.sh already present"
fi

# ----------------------------------------------------
# STEP 6 — NVIDIA DRIVER CHECK
# ----------------------------------------------------
log "Checking NVIDIA driver availability..."

if ! command -v nvidia-smi &> /dev/null; then
    warn "nvidia-smi not found. Creating proposal JSON entry."

    echo "{
  \"id\": \"fix_nvidia_driver\",
  \"description\": \"Install or repair missing NVIDIA drivers\",
  \"timestamp\": \"$TIMESTAMP\"
}" > "$PROPOSAL_DIR/fix_nvidia_driver.json"

    success "Proposal saved: fix_nvidia_driver.json"
else
    if nvidia-smi &>/dev/null; then
        success "NVIDIA driver detected and functional."
    else
        warn "nvidia-smi exists but GPU communication failed."
        read -r -p "Run fix_nvidia_driver.sh now? (Y/n): " ans
        if [[ "$ans" =~ ^[Yy]$ || -z "$ans" ]]; then
            bash "$PROPOSAL_DIR/fix_nvidia_driver.sh"
        else
            warn "Driver fix skipped."
        fi
    fi
fi

# ----------------------------------------------------
# STEP 7 — SYSTEMD SERVICE FILE
# ----------------------------------------------------
if [ ! -f "$SERVICE_FILE" ]; then
    log "Creating systemd service file at $SERVICE_FILE..."

    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=CUDA Sentinel Agent
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m cuda_sentinel.agent_runner
WorkingDirectory=$APP_DIR
Environment=PYTHONPATH=$APP_DIR
Environment=SENTINEL_EVENTS_URL=http://127.0.0.1:5001/v1/events
Environment=SENTINEL_STATE_DIR=/var/lib/cuda-sentinel
Environment=LOG_LEVEL=INFO
Environment=SENTINEL_OPERATOR_TOKEN=
StandardOutput=append:$LOG_DIR/agent.log
StandardError=append:$LOG_DIR/agent.err
Restart=on-failure
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ReadWritePaths=$APP_DIR $LOG_DIR /var/lib/cuda-sentinel

[Install]
WantedBy=multi-user.target
EOF

    success "Systemd unit created."
else
    success "Systemd unit already exists."
fi

if [ ! -f "$API_SERVICE_FILE" ]; then
    log "Creating API systemd service file at $API_SERVICE_FILE..."

    cat << EOF > "$API_SERVICE_FILE"
[Unit]
Description=CUDA Sentinel API
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m uvicorn cuda_sentinel.api:app --host 127.0.0.1 --port 5001
WorkingDirectory=$APP_DIR
Environment=PYTHONPATH=$APP_DIR
StandardOutput=append:$LOG_DIR/api.log
StandardError=append:$LOG_DIR/api.err
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ReadWritePaths=$APP_DIR $LOG_DIR /var/lib/cuda-sentinel

[Install]
WantedBy=multi-user.target
EOF

    success "API systemd unit created."
else
    success "API systemd unit already exists."
fi

# ----------------------------------------------------
# STEP 8 — RELOAD + ENABLE + START SERVICE
# ----------------------------------------------------
log "Reloading systemd and enabling service..."
systemctl daemon-reload
systemctl enable cuda-sentinel-api
systemctl enable cuda-sentinel

log "Starting cuda-sentinel-api..."
if systemctl start cuda-sentinel-api; then
    success "cuda-sentinel-api started successfully."
else
    warn "API service failed to start. Check: $LOG_DIR/api.err"
fi

log "Starting cuda-sentinel..."
if systemctl start cuda-sentinel; then
    success "cuda-sentinel started successfully."
else
    warn "Service failed to start. Check: $LOG_DIR/agent.err"
fi

# ----------------------------------------------------
# FINAL SUMMARY
# ----------------------------------------------------
echo "------------------------------------------------------------"
success "CUDA Sentinel v0.1.5-patch1 installation complete"
echo "App Directory:     $APP_DIR"
echo "Log Directory:     $LOG_DIR"
echo "Service File:      $SERVICE_FILE"
echo "Fix Proposals:     $PROPOSAL_DIR"
echo "Backup Directory:  $BACKUP_DIR"
echo "UTC Timestamp:     $TIMESTAMP"
echo "------------------------------------------------------------"
echo
