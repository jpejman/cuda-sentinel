# CUDA Sentinel Roadmap

This roadmap turns the current installer and mocked dashboard into a safe,
source-backed GPU operations product. Priority is ordered by operational risk.

## Progress To Date

- Repository initialized, reconciled with GitHub, and pushed to `master`.
- Installer safety baseline completed in `install_cuda_sentinel_v0.1.5.sh`.
- AgentOps AOCL, specifications, audit, and handoff structure installed.
- v0.2 runtime foundation implemented in `cuda_sentinel/`: typed models,
  deduplicating event store, kernel event parser, FastAPI endpoints, and a
  dry-run allowlisted remediation policy.
- Four runtime unit tests and CI checks are now present.

## P0: Complete The Runtime And Safety Boundary

- Package the checked-in `cuda_sentinel` runtime into the Linux installer and
  add a documented systemd entrypoint.
- Replace mocked dashboard data with authenticated API calls and explicit
  loading, empty, stale-data, and error states.
- Add an approval identity and audit record to remediation requests.
- Add a disposable Ubuntu/systemd install smoke test. Never test driver
  installation against a developer workstation.

## P1: Observability And Reliability

- Persist events and remediation runs instead of keeping them in process
  memory or append-only log files.
- Add event IDs, source timestamps, ingestion timestamps, host identity, and a
  deduplication strategy that survives agent restarts.
- Add structured JSON logs, log rotation, health/readiness endpoints, and
  metrics for ingestion failures, stale agents, and remediation outcomes.
- Add systemd hardening, least-privilege service accounts, resource limits,
  restart backoff, and a documented upgrade/rollback procedure.

## P2: Product Capability

- Support DCGM/NVML metrics, multi-GPU inventory, CUDA/driver compatibility
  checks, and configurable alert thresholds.
- Introduce a playbook schema with preflight checks, rollback steps, timeout,
  risk level, and required capabilities.
- Add role-based access control, audit export, and approval history to the UI.
- Add deployment packaging for a pinned release artifact rather than manual
  file copying into `/opt/cuda-sentinel`.

## Release Gates

- No release may start a service whose executable is absent.
- No remediation may execute an arbitrary shell string.
- Installer reruns must preserve the previous installation and produce a
  verifiable rollback point.
- CI must pass Python tests, shell syntax/lint checks, frontend type/build
  checks, and a clean-install smoke test.

## Near-Term Milestones

1. v0.2.1: installer packages the runtime and exposes a systemd health check.
2. v0.3.0: dashboard reads live API data and supports safe dry-run proposals.
3. v0.4.0: durable event/remediation persistence and operational metrics.
4. v0.5.0: DCGM/NVML inventory, playbooks, RBAC, and audited approvals.
