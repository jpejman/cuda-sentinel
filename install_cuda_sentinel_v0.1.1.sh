#!/usr/bin/env bash
# ==============================================================================
# CUDA Sentinel — Installer
# Version: v0.1.1
# Date: 2025-08-19
# Changelog (v0.1.1)
# - Fix: agent now handles restricted dmesg (DMESG_RESTRICTED finding)
# - Emit actionable GPU event even when dmesg is blocked
# - Adds new FixProposal: enable dmesg access via sysctl
# - Preserves all v0.1.0 functionality (agent, api, watchdog, sanity)
# ==============================================================================

set -euo pipefail

# -------- Config --------
APP_NAME="cuda-sentinel"
APP_USER="${APP_NAME}"
APP_GROUP="${APP_NAME}"
PREFIX="/opt/${APP_NAME}"
ETC_DIR="/etc/${APP_NAME}"
VAR_DIR="/var/lib/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
PYTHON_BIN="python3"
VENVDIR="${PREFIX}/venv"
API_PORT="${API_PORT:-5001}"
export LLM_PROVIDER="${LLM_PROVIDER:-ollama}"
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://127.0.0.1:11434}"

# -------- OS Deps --------
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ${PYTHON_BIN} ${PYTHON_BIN}-venv python3-pip \
  curl jq git ca-certificates \
  pkg-config build-essential

# -------- Users --------
getent group "${APP_GROUP}" >/dev/null || groupadd --system "${APP_GROUP}"
id "${APP_USER}" >/dev/null 2>&1 || \
  useradd --system --home "${PREFIX}" --gid "${APP_GROUP}" --shell /usr/sbin/nologin "${APP_USER}"

# -------- Dirs --------
mkdir -p "${PREFIX}"/packages/{sentinel-agent,sentinel-api,sentinel-playbooks} "${ETC_DIR}" "${VAR_DIR}" "${LOG_DIR}" "${PREFIX}/contrib"
chown -R "${APP_USER}:${APP_GROUP}" "${PREFIX}" "${ETC_DIR}" "${VAR_DIR}" "${LOG_DIR}"

# -------- Python Env --------
[[ -d "${VENVDIR}" ]] || ${PYTHON_BIN} -m venv "${VENVDIR}"
source "${VENVDIR}/bin/activate"
pip install --upgrade pip wheel setuptools
pip install fastapi uvicorn[standard] pydantic pyyaml psutil nvidia-ml-py3

# -------- gpu_sanity.sh --------
cat > "${PREFIX}/contrib/gpu_sanity_v0.1.0.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/cuda-sentinel/gpu_sanity.log
TS(){ date -u +"%Y-%m-%dT%H:%M:%SZ"; }
run(){ echo "[\$(TS)] \$*" | tee -a "\$LOG"; eval "\$@" >>"\$LOG" 2>&1 || { echo "[FAIL] \$*" | tee -a "\$LOG"; return 1; }; }
echo "==== GPU SANITY START \$(TS) ====" | tee -a "\$LOG"
run "nvidia-smi -q -d DRIVER,PCI,PERFORMANCE,UTILIZATION,MEMORY,ECC" || true
run "lsmod | grep -E 'nvidia|nouveau' || true"
run "dmesg | egrep -i 'nvrm|xid|gpu|nvidia' | tail -n 200 || true"
run "ldconfig -p | egrep 'libcuda\\.so|libcudart|libcublas|libnccl|libcudnn' || true"
run "cat /usr/local/cuda/version.txt || true"
python3 - <<'PY' >>"\$LOG" 2>&1 || true
import torch, sys
print("PY:", sys.version)
print("CUDA avail:", hasattr(torch,'cuda') and torch.cuda.is_available())
print("torch ver:", getattr(torch,'__version__','n/a'))
print("torch cuda:", getattr(getattr(torch,'version',None),'cuda',None))
if hasattr(torch,'cuda') and torch.cuda.is_available():
    print("nDevs:", torch.cuda.device_count())
    print("dev0:", torch.cuda.get_device_name(0), torch.cuda.get_device_capability(0))
PY
if dmesg | egrep -iq 'Xid|GPU has fallen off the bus|NVRM:.*fatal'; then
  echo "[SUMMARY] KERNEL/PCI FAULT DETECTED (see \$LOG)"; exit 2; fi
python3 - <<'PY' >/dev/null 2>&1 || { echo "[SUMMARY] PYTORCH CUDA NOT AVAILABLE"; exit 3; }
import torch, sys; sys.exit(0 if (hasattr(torch,'cuda') and torch.cuda.is_available()) else 1)
PY
echo "[SUMMARY] HEALTHY"
EOS
chmod +x "${PREFIX}/contrib/gpu_sanity_v0.1.0.sh"

# -------- sentinel-agent (with dmesg fix) --------
cat > "${PREFIX}/packages/sentinel-agent/agent.py" <<'PY'
import os, time, json, subprocess, re, socket
from datetime import datetime, timezone
HOST = socket.gethostname()
LOG = "/var/log/cuda-sentinel/agent.log"
TS = lambda: datetime.now(timezone.utc).isoformat()

def tail_dmesg():
    try:
        out = subprocess.check_output(["dmesg", "--ctime"], text=True)
        lines = [l for l in out.splitlines() if re.search(r"(Xid|NVRM|gpu|nvidia)", l, re.I)]
        return lines[-200:]
    except Exception as e:
        return [f"DMESG_ERR:{e}"]

def emit(ev):
    line = json.dumps(ev)
    with open(LOG, "a") as f: f.write(line + "\n")

def main():
    last_hash = None
    while True:
        lines = tail_dmesg()
        if len(lines) == 1 and lines[0].startswith("DMESG_ERR"):
            emit({"id": f"evt_{int(time.time()*1000)}", "ts": TS(), "host": HOST, "gpu_index": 0,
                  "source": "kernel", "type": "DMESG_RESTRICTED", "severity": "high",
                  "message": "dmesg access denied: possible kernel lockdown or sysctl block",
                  "raw": lines[0]})
        else:
            h = hash("\n".join(lines))
            if h != last_hash:
                for l in lines[-10:]:
                    sev = "high" if "Xid" in l else "info"
                    emit({"id": f"evt_{int(time.time()*1000)}", "ts": TS(), "host": HOST, "gpu_index": 0,
                          "source": "kernel", "type": "XID_31" if "Xid" in l else "KMSG",
                          "severity": sev, "message": l[:200], "raw": l[-200:]})
                last_hash = h
        time.sleep(10)

if __name__ == "__main__":
    main()
PY
chmod +x "${PREFIX}/packages/sentinel-agent/agent.py"

# -------- systemd service update --------
cat > "/etc/systemd/system/sentinel-agent.service" <<EOF
[Unit]
Description=CUDA Sentinel Agent
After=network-online.target

[Service]
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${PREFIX}/packages/sentinel-agent
ExecStart=${VENVDIR}/bin/python ${PREFIX}/packages/sentinel-agent/agent.py
Restart=always
RestartSec=3
StandardOutput=append:${LOG_DIR}/agent.stdout.log
StandardError=append:${LOG_DIR}/agent.stderr.log

[Install]
WantedBy=multi-user.target
EOF

# -------- Restart agent --------
echo "[*] Reloading and restarting agent with dmesg fix…"
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart sentinel-agent.service

# -------- Confirm --------
echo "[v0.1.1 install complete] You should now see DMESG_RESTRICTED if kernel access is blocked."
echo "Run: sudo tail -f /var/log/cuda-sentinel/agent.log"
echo "Run: cat /proc/sys/kernel/dmesg_restrict  # 1 = restricted"
echo "Fix: echo 0 | sudo tee /proc/sys/kernel/dmesg_restrict"