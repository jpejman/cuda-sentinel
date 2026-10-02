# AgentOps Core Architecture

**Architecture Version:** v0.1  
**Date:** 2026-08-12

```text
                    AgentOps Core
                         |
        +----------------+----------------+
        |                |                |
        v                v                v
      AOCL           Snapshots       Review Bundles
        |                |                |
        +----------------+----------------+
                         |
                         v
                     Validation
                         |
                         v
                  Persistent Context
                         |
            +------------+------------+
            |                         |
            v                         v
      Structured Index          Semantic Index
            |                         |
            +------------+------------+
                         |
                         v
                Agent Retrieval Layer
```

## Layer 1 — Human-Readable Source Context

AOCL categories: `docs/context/`, `docs/roadmap/`, `docs/architecture/`, `docs/runbooks/`, `docs/audits/`, and `docs/handoffs/`. These remain useful even after databases are introduced.

## Layer 2 — Lifecycle Evidence

Snapshots provide point-in-time engineering state. Review Bundles provide optimized comprehension artifacts. Both should reuse security policy, inventories, Git metadata, manifests, exclusions, path handling, timestamps, and checksums.

## Layer 3 — Validation

Validation evaluates structure, freshness, completeness, security, artifact generation, manifest integrity, and source coverage.

## Layer 4 — Persistent Structured Context

Future structured entities may include Project, Repository, ArchitectureComponent, Decision, RoadmapItem, Version, Runbook, Audit, Handoff, Module, Issue, Test, Artifact, AgentSession, and SourceDocument. Storage backend remains abstract.

## Layer 5 — Semantic Context

AgentOps should own the semantic pipeline:

```text
discover -> classify -> chunk -> embed -> index -> retrieve -> cite source -> refresh
```

The user should not need to understand this pipeline.

## Storage Abstraction

Conceptually:

```text
ContextStore
├── FileContextStore
├── SQLiteContextStore
├── VectorContextStore
└── HybridContextStore
```

The initial implementation is effectively `FileContextStore`.
