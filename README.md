# CUDA Sentinel

CUDA Sentinel is an early-stage operations console and installer prototype for
detecting CUDA/NVIDIA health issues and proposing targeted remediation.

## Repository Contents

- `Cuda Sentinel — Mvp Dashboard (demo).py` and `Cuda_Sentinel—Mvp_Dashboard.py`
  contain the same React/TypeScript dashboard demo. The `.py` suffix is legacy
  and the file is not executable Python.
- `install_cuda_sentinel_v0.1.5.sh` is the current installer candidate. Older
  `v0.1.x` scripts are retained for historical comparison.
- `cuda_sentinel/` contains the initial Python agent/API runtime boundary.
- `requirements.txt` and `pyproject.toml` define the Python service dependencies.

## Current Installer Limitation

The installer still expects the deployable application payload at
`/opt/cuda-sentinel/agent.py`; packaging that runtime into the installer is the
next deployment milestone. The checked-in Python runtime is the source of truth
for the API/agent implementation.

Run the installer on a supported Debian/Ubuntu host only after placing the
runtime files in `/opt/cuda-sentinel`:

```bash
sudo bash install_cuda_sentinel_v0.1.5.sh
```

The installer requires root privileges, `systemd`, and NVIDIA tooling. Do not
run it on a development workstation as a substitute for a test environment.

## Runtime Development

Install dependencies and run the API locally:

```bash
python -m pip install -r requirements.txt
python -m cuda_sentinel.api
```

The initial API exposes `/v1/health`, `/v1/services`, `/v1/events`, and
`/v1/proposals`. Remediation requests are approval-gated, allowlist-checked,
and dry-run only until the audited executor milestone is complete.

## Development Status

The dashboard remains mocked, while the runtime foundation now has unit tests.
See
[`ROADMAP.md`](ROADMAP.md) for the implementation sequence and release gates.
