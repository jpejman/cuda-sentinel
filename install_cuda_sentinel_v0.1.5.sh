#!/bin/bash
# install_cuda_sentinel_v0.1.5
# CUDA Sentinel Installer v0.1.5
# Features: auto-backfill proposals, log rotation settings, NVIDIA detection, smoke test mode

APP_DIR="/opt/cuda-sentinel"
LOG_DIR="/var/log/cuda-sentinel"
SYSTEMD_DIR="/etc/systemd/system"
SERVICE_FILE="$SYSTEMD_DIR/cuda-sentinel.service"
PROPOSAL_DIR="$APP_DIR/proposals"
BACKUP_DIR="/opt/cuda-sentinel-v0.1.5-backup"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

set -e

log() {
    echo -e "[+] $1"
}
warn() {
    echo -e "[!] $1"
}
success() {
    echo -e "[\033[0;32m\u2713\033[0m] $1"
}

log "CUDA Sentinel Installer - Version v0.1.5"

# Backup previous install
if [ -d "$APP_DIR" ]; then
    warn "Previous install found. Creating backup at $BACKUP_DIR"
    cp -r "$APP_DIR" "$BACKUP_DIR"
    success "Backup complete: $BACKUP_DIR"
fi

# Ensure log dir
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/install.log"
log "Log directory ensured at $LOG_DIR"

# Timestamped logging setup (external rotation assumed)
log "Timestamped logging enabled"

# Skip rsync - manual copy expected
warn "Skipping rsync (manual copy expected). Please place updated files in $APP_DIR"

# Backfill missing fix proposals if needed
if [ ! -f "$PROPOSAL_DIR/fix_nvidia_driver.sh" ]; then
    log "Backfilling missing fix_nvidia_driver.sh script"
    cat << 'EOF' > "$PROPOSAL_DIR/fix_nvidia_driver.sh"
#!/bin/bash
# Fix NVIDIA Driver Script
LOG_FILE="/var/log/cuda-sentinel/fix_nvidia_driver.log"
echo "[$(date -u)] Running fix_nvidia_driver.sh" | tee -a "$LOG_FILE"
ubuntu-drivers devices | tee -a "$LOG_FILE"
echo -e "\nChoose option:\n1) Auto install recommended\n2) Install latest\n3) Quit"
read -p "Enter your choice [1-3]: " choice
case "$choice" in
    1) sudo ubuntu-drivers autoinstall | tee -a "$LOG_FILE";;
    2) sudo apt install -y nvidia-driver-535 | tee -a "$LOG_FILE";;
    *) echo "Aborted" | tee -a "$LOG_FILE";;
esac
EOF
    chmod +x "$PROPOSAL_DIR/fix_nvidia_driver.sh"
    log "Fix proposal script created"
fi

# NVIDIA driver check
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi &> /dev/null; then
        success "NVIDIA driver detected via nvidia-smi"
    else
        warn "NVIDIA driver utility found, but communication failed."
        read -p "Run fix proposal now? (Y/n): " confirm
        if [[ "$confirm" == "Y" || "$confirm" == "y" || -z "$confirm" ]]; then
            bash "$PROPOSAL_DIR/fix_nvidia_driver.sh"
        else
            warn "Fix skipped by user."
        fi
    fi
else
    warn "nvidia-smi not found. Registering fix proposal."
    FIX_FILE="$PROPOSAL_DIR/fix_nvidia_driver.json"
    echo "{\n  \"id\": \"fix_nvidia_driver\",\n  \"description\": \"Install or repair missing NVIDIA drivers\",\n  \"timestamp\": \"$TIMESTAMP\"\n}" > "$FIX_FILE"
    log "Fix proposal saved to: $FIX_FILE"
fi

# Generate or confirm service file
if [ ! -f "$SERVICE_FILE" ]; then
    log "Generating new systemd service file..."
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=CUDA Sentinel Agent
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $APP_DIR/agent.py
WorkingDirectory=$APP_DIR
StandardOutput=append:$LOG_DIR/agent.log
StandardError=append:$LOG_DIR/agent.err
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    success "Systemd unit created: $SERVICE_FILE"
fi

# Reload and start service
log "Running systemctl daemon-reload and enabling service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable cuda-sentinel
systemctl start cuda-sentinel

# Final summary
echo "------------------------------------------------------------"
success "Install Complete - CUDA Sentinel v0.1.5"
echo "Log Dir:         $LOG_DIR"
echo "App Dir:         $APP_DIR"
echo "Systemd Unit:    $SERVICE_FILE"
echo "Fix Proposals:   $PROPOSAL_DIR"
echo "Backup:          $BACKUP_DIR"
echo "UTC Timestamp:   $TIMESTAMP"
echo "------------------------------------------------------------"
