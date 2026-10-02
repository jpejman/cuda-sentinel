# Agent Instructions — AgentOps Core

**Version:** v0.1  
**Date:** 2026-08-12

## Mission

AgentOps Core defines reusable infrastructure for preserving engineering context across repositories, agents, tools, and time.

## Operating Rules

Before changing implementation:

1. Inspect `README.md`.
2. Inspect `ROADMAP.md`.
3. Inspect relevant files under `docs/specs/`.
4. Inspect existing implementation before creating new modules.
5. Prefer extending existing patterns over duplicating them.
6. Preserve backwards compatibility when practical.
7. Record architectural changes in documentation.
8. Do not silently change artifact formats or security behavior.

## Core Concepts

- **AOCL** = durable project knowledge
- **Context Snapshot** = compact point-in-time synchronization
- **Full Snapshot** = reconstructable sanitized engineering state
- **Review Bundle** = optimized comprehension package
- **Validation** = evidence that the preceding capabilities work
- **Persistent Memory** = future structured/semantic project knowledge layer

## Security

Never weaken default secret exclusions for convenience. Never include credentials or raw secrets in manifests, logs, review bundles, snapshots, audit reports, or fixtures.

## Architecture Evolution

Database and vector-memory implementation is intentionally undecided. Do not freeze SQLite, a vector database, or an embedding provider without an explicit architecture decision. Design interfaces so storage backends can evolve.

## Development Philosophy

Contract first. Reference implementation second. Shared deterministic tooling third. Automation and intelligence later.
