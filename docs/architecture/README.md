# Architecture Index

The current repository architecture is documented in [`../ARCHITECTURE.md`](../ARCHITECTURE.md).

The implementation has four current layers:

- `cuda_sentinel/models.py`: versioned API/domain models.
- `cuda_sentinel/agent.py`: deterministic kernel-event parsing with stable IDs.
- `cuda_sentinel/store.py`: bounded in-memory state and event deduplication.
- `cuda_sentinel/api.py` and `cuda_sentinel/remediation.py`: API boundary and
  dry-run, allowlisted remediation policy.

The dashboard remains a mocked React/TypeScript prototype. Persistence,
authentication, live dashboard wiring, and audited live command execution are
explicit future milestones. The installer must package the runtime before a
production systemd deployment is considered complete.
