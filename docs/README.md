# Repository Documentation

This directory is the CUDA Sentinel Agent Operating Context Layer (AOCL).

- `context/` contains stable project context for agents.
- `roadmap/` contains roadmap indexes and version plans.
- `architecture/` contains system design and repository structure notes.
- `runbooks/` contains repeatable operator procedures.
- `audits/` contains validation findings and implementation reviews.
- `handoffs/` contains agent-to-agent continuation notes.
- `specs/` contains the adopted AgentOps contracts.
- `logs/` is intentionally separate from durable documentation; runtime history belongs there.

Durable project memory belongs in `docs/`. Transient runtime execution history
belongs in `logs/`. The product roadmap remains the root [`ROADMAP.md`](../ROADMAP.md)
and is indexed from `roadmap/` rather than duplicated.

AgentOps adoption directive: [`AGENTOPS_REPO_BASELINE_DIRECTIVE_v1_0.md`](../directives/AGENTOPS_REPO_BASELINE_DIRECTIVE_v1_0.md).
