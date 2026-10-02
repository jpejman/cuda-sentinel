# Linux systemd Deployment

CUDA Sentinel runs as two systemd services:

- `cuda-sentinel-api.service`: local FastAPI API on `127.0.0.1:5001`.
- `cuda-sentinel.service`: kernel-event agent publishing to the API.

The installer creates `/opt/cuda-sentinel/venv`, installs repository
requirements there, creates state under `/var/lib/cuda-sentinel`, and writes
logs under `/var/log/cuda-sentinel`.

## Install

Run on a supported Debian/Ubuntu GPU host from the repository checkout:

```bash
sudo bash install_cuda_sentinel_v0.1.5.sh
```

The installer is not a driver installer. Missing or unhealthy NVIDIA tooling is
recorded as a proposal; driver changes require a separate operator decision.

## Configure Operator Authentication

Before production use, set a secret bearer token in both generated units. Do
not commit the token:

```bash
sudo systemctl edit cuda-sentinel-api.service
sudo systemctl edit cuda-sentinel.service
```

Add to each override:

```ini
[Service]
Environment=SENTINEL_OPERATOR_TOKEN=replace-with-a-secret
```

Then reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart cuda-sentinel-api.service cuda-sentinel.service
```

## Verify

```bash
sudo systemctl is-active cuda-sentinel-api.service
sudo systemctl is-active cuda-sentinel.service
curl --fail http://127.0.0.1:5001/v1/health
curl --fail http://127.0.0.1:5001/v1/metrics
sudo journalctl -u cuda-sentinel-api.service -n 100 --no-pager
sudo journalctl -u cuda-sentinel.service -n 100 --no-pager
```

## Upgrade And Rollback

The installer creates a timestamped backup under `/opt/` before replacing the
application directory. Stop services before a manual rollback, restore the
desired backup, then reload and restart both units:

```bash
sudo systemctl stop cuda-sentinel.service cuda-sentinel-api.service
sudo systemctl daemon-reload
sudo systemctl start cuda-sentinel-api.service cuda-sentinel.service
```

Validate `/v1/health`, `/v1/metrics`, and service logs after every upgrade.

## Operational Boundaries

- Live remediation is disabled; proposals are dry-run only.
- The agent requires kernel diagnostics access and should move to a
  least-privilege service account after host-specific `dmesg` policy testing.
- The API binds to loopback. Put it behind an authenticated reverse proxy for
  remote dashboard access.
- Do not place tokens, credentials, or `.env` files in the repository.
