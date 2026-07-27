#!/bin/bash
# install_cuda_sentinel_v0.1.4.sh
# CUDA Sentinel Installer with NVIDIA Driver Fix Options (v0.1.4)

APP_DIR="/opt/cuda-sentinel"
LOG_DIR="/var/log/cuda-sentinel"
SERVICE_FILE="/etc/systemd/system/cuda-sentinel.service"
BACKUP_DIR="/opt/cuda-sentinel-v0.1.3-backup"
FIX_SCRIPT="$APP_DIR/proposals/fix_nvidia_driver.sh"

set -e

# Logging function
timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "[$(timestamp)] $1"; }

# Header
clear
echo "[+] CUDA Sentinel Installer - Version v0.1.4"

# Backup existing install if present
if [ -d "$APP_DIR" ]; then
  log "Previous install found. Creating backup at $BACKUP_DIR"
  sudo cp -r "$APP_DIR" "$BACKUP_DIR"
  log "Backup complete: $BACKUP_DIR"
fi

# Ensure directories
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/agent.log" "$LOG_DIR/agent.err.log"
log "Log directory ensured at $LOG_DIR"

# Copy skipped for manual workflows
log "[~] Skipping rsync (manual copy expected). Please place updated files in $APP_DIR"

# NVIDIA check
if ! command -v nvidia-smi &>/dev/null || ! nvidia-smi &>/dev/null; then
  echo "[!] NVIDIA driver not detected."
  echo "Choose fix option:"
  echo "  1) 🛠️  Run fix proposal script now"
  echo "  2) 🧠  Install latest recommended NVIDIA driver"
  echo "  3) 🚫  Skip fix"
  read -p "Enter choice [1-3]: " CHOICE

  case "$CHOICE" in
    1)
      echo "[~] Running fix proposal script..."
      bash "$FIX_SCRIPT" | tee -a "$LOG_DIR/fix_nvidia_driver.log"
      ;;
    2)
      echo "[~] Installing latest recommended NVIDIA driver..."
      sudo apt update
      sudo apt install -y nvidia-driver-535
      sudo modprobe nvidia || true
      nvidia-smi || echo "[!] Driver install failed — please reboot manually."
      ;;
    3)
      echo "[!] Skipping driver fix at user request."
      ;;
    *)
      echo "[!] Invalid choice. Skipping fix."
      ;;
  esac
else
  log "[✓] NVIDIA driver detected via nvidia-smi"
fi

# Regenerate service file
log "[+] Writing systemd unit file..."
cat <<EOF | sudo tee "$SERVICE_FILE" >/dev/null
[Unit]
Description=CUDA Sentinel Agent
After=network.target

[Service]
Type=simple
ExecStart=$APP_DIR/agent.py
Restart=on-failure
WorkingDirectory=$APP_DIR
StandardOutput=append:$LOG_DIR/agent.log
StandardError=append:$LOG_DIR/agent.err.log

[Install]
WantedBy=multi-user.target
EOF

# Reload + enable + start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable cuda-sentinel
sudo systemctl start cuda-sentinel

# Completion message
echo "------------------------------------------------------------"
echo "[✓] Install Complete - CUDA Sentinel v0.1.4"
echo "Log Dir:         $LOG_DIR"
echo "App Dir:         $APP_DIR"
echo "Systemd Unit:    $SERVICE_FILE"
echo "Fix Proposals:   $APP_DIR/proposals"
echo "Backup:          $BACKUP_DIR"
echo "UTC Timestamp:   $(timestamp)"
echo "------------------------------------------------------------"
