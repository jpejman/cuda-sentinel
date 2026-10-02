# AOCL Specification

**Specification Version:** v0.1  
**Date:** 2026-08-12

AOCL means **Agent Operating Context Layer**. It is the durable, version-controlled project knowledge layer used by agents and humans to understand the repository and continue work.

## Canonical Categories

```text
docs/context/
docs/roadmap/
docs/architecture/
docs/runbooks/
docs/audits/
docs/handoffs/
logs/
```

`docs/context/` contains stable context; `docs/roadmap/` plans and milestones; `docs/architecture/` design and boundaries; `docs/runbooks/` repeatable procedures; `docs/audits/` findings and reviews; `docs/handoffs/` continuation context; `logs/` transient execution history.

Maintain `docs/README.md` as the index to the repository's actual AOCL structure.

AOCL must preserve useful project-specific docs, avoid unnecessary duplication, remain understandable without a database, remain version controlled, distinguish current truth from historical evidence, make continuation location clear, and link to evidence where possible.
