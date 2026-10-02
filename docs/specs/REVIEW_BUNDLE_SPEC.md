# Agent Review Bundle Specification

**Specification Version:** v0.1  
**Date:** 2026-08-12

## Purpose

Create a concentrated repository comprehension package for AI agents and engineering reviewers. A Review Bundle is not a backup and should not automatically duplicate the Full Snapshot.

## Required Information

Repository tree, file inventory, Git state, AOCL, roadmap, architecture, runbooks, audits, handoffs, selected high-value source, security status, and a review manifest.

## Recommended Layout

```text
repo_review_<timestamp>/
├── README.md
├── repo/
├── git/
├── aocl/
├── review/
├── source_snapshot/
├── security/
└── review_manifest.json
```

## Source Selection

Prefer architecture-defining source, entrypoints, lifecycle tooling, core modules, configuration schemas, relevant tests, active roadmap, current audits, and current handoffs. Avoid binaries, dependencies, generated outputs, secrets, and large irrelevant data.

When concatenating text, preserve file identity using clear `FILE: relative/path` separators.
