# How to Adopt AgentOps in an Existing Repository

**Version:** v0.1  
**Date:** 2026-08-12

## Objective

Add AgentOps capabilities without destroying or duplicating useful existing repository practices.

## Recommended First Method

Use `directives/AGENTOPS_REPO_BASELINE_DIRECTIVE_v1_0.md` with the engineering agent already operating in the target repository.

## Workflow

1. Inspect Git state and repository structure.
2. Discover docs, roadmaps, architecture, snapshots, audits, review tooling, handoffs, and instructions.
3. Classify AOCL, Context Snapshot, Full Snapshot, Review Bundle, Validation, and Security Policy as ABSENT, PARTIAL, PRESENT, PRESENT_BUT_OUTDATED, DUPLICATED, or NONCOMPLIANT.
4. Reuse before replacing.
5. Establish or reconcile AOCL.
6. Validate Context and Full snapshot modes.
7. Validate Review Bundle.
8. Generate `docs/audits/agentops_baseline_audit_<timestamp>.md`.
9. Review `git status --short` before commit.

## Do Not

Do not blindly copy scripts into every repo, overwrite architecture, treat logs as durable context, package secrets, copy `.git`, include large model/data artifacts by default, or freeze a vector database before requirements are validated.

## Future

Adoption should become:

```bash
agentops assess .
agentops migrate .
agentops validate .
```
