#!/usr/bin/env bash
# ==============================================================================
# CUDA Sentinel — Installer
# Version: v0.1.0
# Date: 2025-08-19
# Changelog (v0.1.0)
# - Initial installer: creates directory tree, venv, deps
# - Seeds agent + API runnable stubs (FastAPI)
# - Installs gpu_sanity + lib_reconciler utilities
# - Adds systemd services: sentinel-agent, sentinel-api, gpu-watchdog
# - Safe, idempotent re-runs; no destructive ops by default
# ==============================================================================

set -euo pipefail

# -------- Config (edit as needed) --------
APP_NAME="cuda-sentinel"
APP_USER="${APP_NAME}"
APP_GROUP="${APP_NAME}"
PREFIX="/opt/${APP_NAME}"
ETC_DIR="/etc/${APP_NAME}"
VAR_DIR="/var/lib/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
PYTHON_BIN="python3"                 # 3.10+ recommended
VENVDIR="${PREFIX}/venv"
API_PORT="${API_PORT:-5001}"
# LLM defaults (can point to local Ollama etc.)
export LLM_PROVIDER="${LLM_PROVIDER:-ollama}"
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://127.0.0.1:11434}"

# -------- Root check --------
if [[ "$EUID" -ne 0 ]]; then
  echo "[ERROR] Please run as root (sudo)." >&2
  exit 1
fi

# -------- OS deps --------
echo "[*] Installing OS dependencies…"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ${PYTHON_BIN} ${PYTHON_BIN}-venv python3-pip \
  curl jq git ca-certificates \
  pkg-config build-essential
# Optional: dcgm-exporter / nv libs detected at runtime; not forced here

# -------- Users / Groups --------
if ! getent group "${APP_GROUP}" >/dev/null; then
  groupadd --system "${APP_GROUP}"
fi
if ! id "${APP_USER}" >/dev/null 2>&1; then
  useradd --system --home "${PREFIX}" --gid "${APP_GROUP}" --shell /usr/sbin/nologin "${APP_USER}"
fi

# -------- Directories --------
echo "[*] Creating directories…"
mkdir -p "${PREFIX}"/{packages,packages/sentinel-agent,packages/sentinel-api,packages/sentinel-executor,packages/sentinel-orchestrator,packages/sentinel-dashboard,packages/sentinel-playbooks,contrib}
mkdir -p "${ETC_DIR}" "${VAR_DIR}" "${LOG_DIR}"
chown -R "${APP_USER}:${APP_GROUP}" "${PREFIX}" "${ETC_DIR}" "${VAR_DIR}" "${LOG_DIR}"

# -------- Python venv --------
if [[ ! -d "${VENVDIR}" ]]; then
  echo "[*] Creating Python venv…"
  ${PYTHON_BIN} -m venv "${VENVDIR}"
fi
# shellcheck disable=SC1090
source "${VENVDIR}/bin/activate"
pip install --upgrade pip wheel setuptools

echo "[*] Installing Python runtime deps…"
# Core libs; expand as you wire more modules
pip install fastapi uvicorn[standard] pydantic pyyaml psutil nvidia-ml-py3

# -------- Seed: GPU sanity & lib reconciler --------
cat > "${PREFIX}/contrib/gpu_sanity_v0.1.0.sh" <<"EOS"
#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/cuda-sentinel/gpu_sanity.log
TS(){ date -u +"%Y-%m-%dT%H:%M:%SZ"; }
run(){ echo "[$(TS)] $*" | tee -a "$LOG"; eval "$@" >>"$LOG" 2>&1 || { echo "[FAIL] $*" | tee -a "$LOG"; return 1; } }
echo "==== GPU SANITY START $(TS) ====" | tee -a "$LOG"
run "nvidia-smi -q -d DRIVER,PCI,PERFORMANCE,UTILIZATION,MEMORY,ECC"
run "lsmod | grep -E 'nvidia|nouveau' || true"
run "dmesg | egrep -i 'nvrm|xid|gpu|nvidia' | tail -n 200 || true"
run "ldconfig -p | egrep 'libcuda\.so|libcudart|libcublas|libnccl|libcudnn' || true"
run "cat /usr/local/cuda/version.txt || true"
python3 - <<'PY' >>"$LOG" 2>&1 || true
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
  echo "[SUMMARY] KERNEL/PCI FAULT DETECTED (see $LOG)"; exit 2; fi
python3 - <<'PY' >/dev/null 2>&1 || { echo "[SUMMARY] PYTORCH CUDA NOT AVAILABLE"; exit 3; }
import torch, sys; sys.exit(0 if (hasattr(torch,'cuda') and torch.cuda.is_available()) else 1)
PY
echo "[SUMMARY] HEALTHY"
EOS
chmod +x "${PREFIX}/contrib/gpu_sanity_v0.1.0.sh"

cat > "${PREFIX}/contrib/nvidia_lib_reconciler_v0.1.0.sh" <<"EOS"
#!/usr/bin/env bash
set -euo pipefail
CUDA_ROOT="${1:-/usr/local/cuda}"
LIBS=(libcuda.so libcudart.so libcublas.so libnccl.so libcudnn.so)
for L in "${LIBS[@]}"; do
  FOUND=$(ldconfig -p | grep -m1 "$L" | awk -F'=> ' '{print $2}' | xargs || true)
  if [[ -n "$FOUND" ]]; then echo "[OK] $L -> $FOUND"; continue; fi
  CAND=$(find "$CUDA_ROOT"/ -type f -name "$L*" | sort -V | tail -n1 || true)
  if [[ -n "$CAND" ]]; then
    ln -sf "$CAND" "/usr/lib/$(basename "$CAND")" || true
    ldconfig
    echo "[FIXED] $L -> $CAND"
  else
    echo "[MISS] $L not found under $CUDA_ROOT"
  fi
done
EOS
chmod +x "${PREFIX}/contrib/nvidia_lib_reconciler_v0.1.0.sh"

# -------- Seed: Playbooks folder + example --------
cat > "${PREFIX}/packages/sentinel-playbooks/reset_gpu.yaml" <<"YAML"
id: pb.cuda.reset_gpu
match:
  any:
    - finding.kind: DEVICE_UNRESPONSIVE
    - event.type: XID_31
constraints:
  gpu.reset_supported: true
propose:
  title: "Reset GPU-{gpu_index} + restart {service}"
  impact: "~15s service blip on GPU-{gpu_index}"
  safety: ["No global reboot", "Affects only target GPU"]
  preflight:
    - "nvidia-smi -pm 1"
  steps:
    - "nvidia-smi --gpu-reset -i {gpu_index}"
    - "systemctl restart {service}"
  rollback:
    - "systemctl restart {service}"
YAML

# -------- Seed: Agent (stub) --------
cat > "${PREFIX}/packages/sentinel-agent/agent.py" <<"PY"
import os, time, json, subprocess, re, socket, sys
from datetime import datetime, timezone
HOST = socket.gethostname()
LOG = "/var/log/cuda-sentinel/agent.log"

def ts():
    return datetime.now(timezone.utc).isoformat()

def tail_dmesg():
    try:
        out = subprocess.check_output(["dmesg","--ctime"], text=True, errors="ignore")
        lines = [l for l in out.splitlines() if re.search(r"(Xid|NVRM|gpu|nvidia)", l, re.I)]
        return lines[-200:]
    except Exception as e:
        return [f"err:{e}"]

def emit_event(ev):
    line = json.dumps(ev)
    with open(LOG,"a") as f: f.write(line+"\n")
    # TODO: POST to API (/v1/ingest/event)
    # requests.post(API_URL, json=ev, timeout=2)

def main():
    print(f"[agent] start {ts()} on {HOST}", flush=True)
    last_hash = None
    while True:
        lines = tail_dmesg()
        h = hash("\n".join(lines))
        if h != last_hash:
            for l in lines[-10:]:
                sev = "info"
                if "Xid" in l: sev = "high"
                ev = {
                    "id": f"evt_{int(time.time()*1000)}",
                    "ts": ts(),
                    "host": HOST,
                    "gpu_index": 0,
                    "source": "kernel",
                    "type": "XID_31" if "Xid" in l else "KMSG",
                    "severity": sev,
                    "message": l[:200],
                    "raw": l[-200:]
                }
                emit_event(ev)
            last_hash = h
        time.sleep(10)

if __name__ == "__main__":
    main()
PY

# -------- Seed: API (FastAPI stub) --------
cat > "${PREFIX}/packages/sentinel-api/api.py" <<"PY"
import os
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timezone
import uvicorn

app = FastAPI(title="CUDA Sentinel API", version="0.1.0")

class Service(BaseModel):
    id: str; name: str; version: str; status: str; uptime: str; host: str

class Event(BaseModel):
    id: str; ts: str; host: str; gpu_index: int; source: str; type: str
    severity: str; message: str; raw: str

class Proposal(BaseModel):
    id: str; finding_id: Optional[str]; title: str; impact: str
    safety: list; preflight: list; steps: list; rollback: list; status: str

SERVICES = [
    Service(id="agent", name="sentinel-agent", version="0.1.0", status="healthy", uptime="1h 3m", host=os.uname().nodename),
    Service(id="api", name="sentinel-api", version="0.1.0", status="healthy", uptime="1h 3m", host=os.uname().nodename)
]
EVENTS: List[Event] = []
PROPOSALS = [
    Proposal(id="p1", finding_id=None, title="Reset GPU-0 + restart llm-infer",
             impact="~15s service blip on GPU-0",
             safety=["No global reboot","Affects only GPU-0"],
             preflight=["nvidia-smi -pm 1"],
             steps=["nvidia-smi --gpu-reset -i 0","systemctl restart llm-infer.service"],
             rollback=["systemctl restart llm-infer.service"], status="ready")
]

@app.get("/v1/health")
def health():
    return {"ok": True, "ts": datetime.now(timezone.utc).isoformat(), "version": "0.1.0"}

@app.get("/v1/services")
def services():
    return SERVICES

@app.get("/v1/events")
def events():
    return EVENTS[-100:]

@app.get("/v1/proposals")
def proposals():
    return PROPOSALS

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT","5001")))
PY

# -------- Systemd: Agent --------
cat > "/etc/systemd/system/sentinel-agent.service" <<SYSTEMD
[Unit]
Description=CUDA Sentinel Agent
After=network-online.target

[Service]
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${PREFIX}/packages/sentinel-agent
Environment=PYTHONUNBUFFERED=1
ExecStart=${VENVDIR}/bin/python ${PREFIX}/packages/sentinel-agent/agent.py
Restart=always
RestartSec=3
StandardOutput=append:${LOG_DIR}/agent.stdout.log
StandardError=append:${LOG_DIR}/agent.stderr.log

[Install]
WantedBy=multi-user.target
SYSTEMD

# -------- Systemd: API --------
cat > "/etc/systemd/system/sentinel-api.service" <<SYSTEMD
[Unit]
Description=CUDA Sentinel API
After=network-online.target

[Service]
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${PREFIX}/packages/sentinel-api
Environment=PORT=${API_PORT}
ExecStart=${VENVDIR}/bin/python ${PREFIX}/packages/sentinel-api/api.py
Restart=always
RestartSec=3
StandardOutput=append:${LOG_DIR}/api.stdout.log
StandardError=append:${LOG_DIR}/api.stderr.log

[Install]
WantedBy=multi-user.target
SYSTEMD

# -------- Watchdog (uses reconciler + sanity) --------
cat > "/etc/systemd/system/gpu-watchdog.service" <<SYSTEMD
[Unit]
Description=GPU Watchdog - restart on CUDA failures
After=multi-user.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
ExecStart=/bin/bash -c 'while true; do /bin/bash ${PREFIX}/contrib/gpu_sanity_v0.1.0.sh || true; sleep 30; done'
Restart=always
RestartSec=10
StandardOutput=append:${LOG_DIR}/watchdog.stdout.log
StandardError=append:${LOG_DIR}/watchdog.stderr.log

[Install]
WantedBy=multi-user.target
SYSTEMD

# -------- Permissions --------
chown -R "${APP_USER}:${APP_GROUP}" "${PREFIX}" "${LOG_DIR}" "${VAR_DIR}" "${ETC_DIR}"

# -------- Enable services --------
echo "[*] Enabling and starting services…"
systemctl daemon-reload
systemctl enable --now sentinel-api.service
systemctl enable --now sentinel-agent.service
systemctl enable --now gpu-watchdog.service

# -------- Post-install summary --------
echo "=============================================================================="
echo " CUDA Sentinel installed (v0.1.0)"
echo " API:    http://$(hostname -I | awk '{print $1}'):${API_PORT}/v1/health"
echo " Logs:   ${LOG_DIR}"
echo " Venv:   ${VENVDIR}"
echo " Binaries:"
echo "   - ${PREFIX}/contrib/gpu_sanity_v0.1.0.sh"
echo "   - ${PREFIX}/contrib/nvidia_lib_reconciler_v0.1.0.sh"
echo " Services:"
systemctl --no-pager --full status sentinel-api.service | sed -n '1,5p'
systemctl --no-pager --full status sentinel-agent.service | sed -n '1,5p'
systemctl --no-pager --full status gpu-watchdog.service   | sed -n '1,5p'
echo "=============================================================================="
echo "Next steps:"
echo "  - Wire the dashboard UI to /v1/services, /v1/events, /v1/proposals"
echo "  - Add real ingest in agent (POST to API) and flesh out orchestrator/executor"
echo "  - (Optional) Edit sudoers for controlled remediation commands (RBAC)"
echo "=============================================================================="
