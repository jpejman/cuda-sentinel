# AGENTOPS REPOSITORY BASELINE DIRECTIVE

**Directive Version:** v1.0  
**Date:** 2026-08-09  
**Scope:** Cross-repository AgentOps lifecycle, context synchronization, snapshotting, review bundles, validation, and engineering handoff  
**Intended Consumers:** Codex, ChatGPT, KiloCode, Hermes/OpenClaw agents, OpenCode, future development agents, and human maintainers

---

# 1. OBJECTIVE

Inspect the current repository and reconcile it against the current AgentOps repository baseline.

The goal is to make the repository self-describing, safely snapshot-capable, reviewable by AI and human engineering agents, and suitable for repeatable synchronization and handoff.

This directive applies to existing repositories.

It MUST enhance and reuse working repository conventions wherever possible.

It MUST NOT blindly replace existing lifecycle tooling, documentation, snapshot scripts, audit systems, context systems, review bundle tooling, or handoff mechanisms.

The required baseline consists of four capabilities:

1. **AOCL — Agent Operating Context Layer**
2. **Repository Snapshot System**
3. **Agent Review Bundle**
4. **Validation / Audit Evidence**

The repository should be able to answer:

- What does this project do?
- What is the current architecture?
- What is the current roadmap?
- What is the current version/state?
- What historical decisions matter?
- What runbooks are active?
- What audits or implementation findings exist?
- What handoff context is current?
- What code and configuration exist now?
- What changed in Git?
- What should the next agent continue working on?
- Can another engineering agent reconstruct the current repository state?
- Can an AI reviewer efficiently understand the repository without rediscovering everything?

---

# 2. OPERATING PRINCIPLES

## 2.1 Discovery First

Before creating or modifying anything:

- inspect the repository
- identify existing lifecycle capabilities
- identify naming conventions
- identify documentation conventions
- identify existing scripts
- identify existing outputs
- identify current Git state
- identify potential duplication

Do not create duplicate functionality when an equivalent or superior implementation already exists.

Prefer:

**discover → classify → compare → reuse → extend → validate**

over:

**create new implementation**

## 2.2 Idempotent Enhancement

This directive may be run repeatedly.

Repeated execution should:

- preserve useful existing content
- preserve repo-specific conventions where practical
- add missing baseline capabilities
- update stale AgentOps lifecycle artifacts when appropriate
- avoid duplicating directories, scripts, documents, or outputs
- avoid unnecessary code churn

## 2.3 Preserve Product Behavior

This directive is infrastructure/process work.

Unless explicitly instructed otherwise, DO NOT modify:

- product behavior
- application business logic
- collector behavior
- analyzer logic
- production architecture
- UI behavior
- APIs
- database schemas
- model behavior
- deployment behavior
- unrelated tests

Do not refactor product code merely to satisfy this directive.

## 2.4 Protect Sensitive State

DO NOT modify, move, expose, package, or publish:

- secrets
- `.env` files
- credentials
- API keys
- tokens
- private keys
- browser profiles
- cookies
- Local Storage
- Session Storage
- service-account credentials
- SSH keys
- certificates
- virtual environments
- `node_modules`
- model weights
- databases
- large runtime artifacts

Security exclusions must take precedence over completeness.

---

# 3. REQUIRED FIRST ACTIONS

Before editing, run and record:

```bash
git status --short
git log -5 --oneline --decorate
```

Also determine where available:

```bash
git branch --show-current
git rev-parse HEAD
git remote -v
git tag --points-at HEAD
```

Inspect the repository root and current documentation/script structure.

Search for existing implementations or conventions using terms including:

```text
create_project_sync_snapshot
create_project_audit_snapshot
create_repo_snapshot
repo_snapshot
snapshot
review_bundle
repo_review
audit_bundle
audit
context
handoff
agentops
oacl
aocl
AGENTS.md
ROADMAP
ARCHITECTURE
MODULE_MAP
CHANGELOG
```

Inspect likely lifecycle locations such as:

```text
docs/
scripts/
scripts/audit/
tools/
ops/
automation/
.agentops/
.github/
```

Do not assume these locations exist.

---

# 4. CLASSIFY CURRENT REPOSITORY CAPABILITIES

For each capability, classify the repository as one of:

```text
ABSENT
PARTIAL
PRESENT
PRESENT_BUT_OUTDATED
DUPLICATED
NONCOMPLIANT
```

Evaluate:

| Capability | Classification |
|---|---|
| AOCL | |
| Context Snapshot | |
| Full Repository Snapshot | |
| Review Bundle | |
| Security Exclusion Policy | |
| Secret Scan | |
| Manifest Generation | |
| Git Metadata Capture | |
| File Inventory | |
| Excluded-File Inventory | |
| Checksums | |
| Agent Handoff Evidence | |
| Validation/Audit Report | |

Record the discovered implementation paths before changing anything.

---

# 5. AOCL BASELINE

## 5.1 Definition

**AOCL = Agent Operating Context Layer**

AOCL is the durable, version-controlled project knowledge layer that allows an agent to understand the repository without reconstructing its history from chat or source code alone.

Durable project memory belongs in `docs/`.

Transient runtime execution history belongs in `logs/`.

## 5.2 Canonical AOCL Structure

Create missing directories only when equivalent repo-specific structures do not already satisfy the same purpose:

```text
docs/
docs/context/
docs/roadmap/
docs/runbooks/
docs/audits/
docs/architecture/
docs/handoffs/
logs/
```

Do not delete existing documentation or logs.

Do not move existing files unless the move is clearly safe and beneficial.

## 5.3 docs/README.md

Create or update:

```text
docs/README.md
```

It must explain that:

- `docs/context/` contains stable seed/context files for agents
- `docs/roadmap/` contains roadmap and version plans
- `docs/runbooks/` contains repeatable operator procedures
- `docs/audits/` contains validation findings and implementation reviews
- `docs/architecture/` contains system design and repository structure notes
- `docs/handoffs/` contains agent-to-agent or chat-to-agent transfer notes
- `logs/` contains timestamped runtime execution history
- durable project memory belongs in `docs/`
- transient runtime history belongs in `logs/`

If equivalent documentation already exists, update or cross-reference it rather than creating conflicting sources of truth.

## 5.4 AOCL Content Preservation

Do not overwrite useful existing:

- architecture decisions
- roadmaps
- runbooks
- implementation notes
- audit findings
- handoffs
- project context
- version history

Where the repository already has strong AOCL-like content:

1. preserve it
2. classify it
3. link it from the AOCL structure when useful
4. add only missing baseline context
5. document any intentional deviation from the canonical layout

---

# 6. REPOSITORY SNAPSHOT BASELINE

The repository snapshot system must support two logical modes.

Existing scripts may use different names if their behavior is equivalent.

## 6.1 Mode 1 — Context Snapshot

Purpose:

Fast agent synchronization and lightweight project-state transfer.

Typical outputs:

```text
project_sync_snapshot_<timestamp>.md
project_sync_snapshot_<timestamp>.txt
```

The context snapshot should contain or reference:

- project identity
- project purpose
- current roadmap
- architecture
- current Git state
- module/repository inventory
- current implementation status
- important documents
- active handoff context
- known issues
- recommended continuation point

The context snapshot should remain compact enough for efficient agent ingestion.

## 6.2 Mode 2 — Full Repository Snapshot

Purpose:

Source-complete engineering synchronization and handoff while safely excluding unnecessary or sensitive artifacts.

Typical output:

```text
repo_snapshot_<timestamp>.zip
```

Recommended logical structure:

```text
repo_snapshot_<timestamp>/

    source/
        repository source and engineering files

    docs/
        roadmap
        architecture
        decisions
        workflows
        runbooks
        audits
        handoffs

    metadata/
        git_status.txt
        git_log.txt
        branch.txt
        commit.txt
        remote.txt
        tags.txt
        changed_files.txt
        file_inventory.txt
        excluded_files.txt
        checksums.txt

    context/
        project_sync_snapshot.md

    security/
        security_scan_report.txt

    snapshot_manifest.json
```

The exact physical layout may differ when an existing implementation already has a strong convention, but equivalent information must be available.

The archive must preserve useful repository-relative paths.

---

# 7. FULL SNAPSHOT INCLUDE POLICY

Include engineering-relevant source and text formats where safe, including as appropriate:

```text
.ps1
.py
.cs
.js
.ts
.tsx
.jsx
.java
.go
.rs
.sh
.bat
.cmd
.json
.yaml
.yml
.toml
.ini
.cfg
.conf
.xml
.md
.txt
.sql schema/migration files when safe and non-sensitive
```

Also include, when present and safe:

- source directories
- scripts
- configuration templates
- tests
- documentation
- build definitions
- CI/CD definitions
- package manifests
- dependency lockfiles
- `README*`
- `ROADMAP*`
- `ARCHITECTURE*`
- `MODULE_MAP*`
- `CHANGELOG*`
- `AGENTS.md`
- handoff documents
- AOCL documents
- non-sensitive repository operational files

Do not rely solely on extension whitelists if that would omit important engineering files.

---

# 8. SNAPSHOT EXCLUDE POLICY

At minimum, exclude where present:

## Git internals

```text
.git/
```

## Build outputs

```text
bin/
obj/
build/
dist/
target/
coverage/
```

## Dependency environments

```text
node_modules/
venv/
.venv/
env/
```

## Generated caches

```text
__pycache__/
*.pyc
.pytest_cache/
.mypy_cache/
.cache/
```

## Runtime/log/temp artifacts

```text
logs/
temp/
tmp/
cache/
```

Exceptions may be made for small, intentionally selected audit/runtime records when explicitly useful and safe.

## Crash / diagnostic artifacts

```text
MEMORY.DMP
*.dmp
*.evtx
crash bundles
diagnostic ZIP exports
```

## Model / binary data artifacts

```text
*.gguf
*.onnx
large *.bin model/data files
model directories
```

## Installer/build packages

```text
*.msi
*.exe
```

unless explicitly requested.

## Secrets and sensitive state

Exclude:

```text
.env
.env.*
credentials*
secrets*
private keys
service-account files
browser profiles
cookies
session stores
SSH keys
certificates containing private material
```

Do not assume filename filtering alone is sufficient.

---

# 9. SIZE MANAGEMENT

The Full Snapshot must remain useful and portable.

Implement or verify:

- configurable maximum individual file size
- configurable excluded directory list
- configurable excluded extension/pattern list
- deterministic reporting of omitted files

Create an exclusion inventory such as:

```text
excluded_files.txt
```

or:

```text
excluded_files.csv
```

For each intentionally omitted file, record when practical:

```text
path
size_bytes
reason
rule
```

Example reasons:

```text
secret_policy
directory_exclusion
extension_exclusion
runtime_artifact
dependency
build_artifact
model_artifact
file_too_large
generated_output
```

The operator and reviewing agent must be able to determine what was intentionally omitted.

---

# 10. SECURITY SCAN

Before finalizing a portable Full Snapshot or Review Bundle, perform a best-effort scan for obvious secrets.

Detect categories such as:

- API keys
- access tokens
- passwords
- private keys
- bearer tokens
- cloud credentials
- service-account material
- `.env` files
- obvious credential connection strings

Do not delete or modify source files.

Generate:

```text
security_scan_report.txt
```

or a machine-readable equivalent.

Where possible record:

```text
file
line_number
category
severity
action
```

Do NOT place detected secret values into the report.

Redact sensitive values.

If a likely secret would otherwise be included in the archive:

- exclude or sanitize the affected portable artifact
- record the exclusion
- mark validation as WARN or FAIL according to severity
- do not publish/upload the unsafe archive

A Git diff can contain secrets even when the underlying secret file is excluded.

Therefore any captured diff must also pass the security policy.

---

# 11. GIT METADATA

Capture available Git state without copying `.git/`.

For Context and Full snapshots, capture as appropriate:

```text
current branch
HEAD commit
recent commit history
working-tree status
changed files
tags
remote metadata
```

For engineering handoff, recent history should normally exceed the initial `git log -5` discovery check.

A typical full snapshot may record the last 20–25 commits.

If capturing:

```text
git diff
```

the diff must be treated as potentially sensitive and scanned/redacted before packaging.

If safe redaction cannot be guaranteed, prefer:

```text
git diff --stat
git status --short
changed file list
```

and mark full diff as intentionally omitted.

---

# 12. SNAPSHOT MANIFEST

Every Full Snapshot must contain:

```text
snapshot_manifest.json
```

At minimum include:

```json
{
  "project": "",
  "timestamp": "",
  "branch": "",
  "commit": "",
  "mode": "full",
  "tool_name": "",
  "tool_version": "",
  "included_files": 0,
  "excluded_files": 0,
  "archive_size_bytes": 0
}
```

Strongly preferred additional fields:

```json
{
  "repository_root": "",
  "context_snapshot_included": true,
  "aocl_detected": true,
  "security_scan_status": "",
  "checksums_generated": true,
  "review_bundle_version": "",
  "snapshot_policy_version": ""
}
```

Do not place credentials or sensitive absolute paths into portable manifests unless explicitly required.

---

# 13. CHECKSUMS

For Full Snapshots, generate checksums for included files or at minimum for the final archive.

Preferred algorithm:

```text
SHA-256
```

Recommended output:

```text
checksums.txt
```

or machine-readable equivalent.

Checksums should allow later validation that the engineering handoff artifact has not changed.

---

# 14. AGENT REVIEW BUNDLE BASELINE

## 14.1 Purpose

The Review Bundle is different from a Full Snapshot.

**Full Snapshot = reconstructable engineering state**

**Review Bundle = optimized comprehension artifact**

The Review Bundle should allow ChatGPT, Codex, KiloCode, Hermes/OpenClaw agents, OpenCode, or a human reviewer to understand the repository with minimal rediscovery and unnecessary file retrieval.

## 14.2 Required Review Bundle Content

The Review Bundle should contain or generate equivalent artifacts for:

```text
repository tree
file inventory
Git state
AOCL/context documents
roadmap
architecture
runbooks
audits
handoffs
important top-level docs
selected engineering source
review manifest
security status
```

Recommended logical structure:

```text
repo_review_<timestamp>/

    README.md

    repo/
        tree.txt
        file_inventory.csv

    git/
        status.txt
        log.txt
        branch.txt
        commit.txt
        tags.txt
        diff_stat.txt
        diff_sanitized.patch   # only when safe

    aocl/
        context/
        roadmap/
        architecture/
        runbooks/
        audits/
        handoffs/

    review/
        combined_docs.md
        combined_source.txt
        source_manifest.json

    source_snapshot/
        selected review-relevant source preserving relative paths

    security/
        security_scan_report.txt

    review_manifest.json
```

Physical naming may follow an existing repository convention when equivalent.

---

# 15. REVIEW BUNDLE SOURCE SELECTION

The Review Bundle should NOT automatically become a duplicate Full Snapshot.

Prefer review-relevant material.

Examples:

- lifecycle scripts
- core application entrypoints
- module maps
- architecture-defining files
- configuration schemas/templates
- tests relevant to current work
- AOCL
- active roadmap
- current handoffs
- recent audit findings

Where combined text files are generated, include clear file separators such as:

```text
================================================================================
FILE: relative/path/to/file
================================================================================
```

Recursive AOCL/docs aggregation is preferred over top-level-only Markdown collection.

Do not aggregate binary files.

Do not aggregate files containing secrets.

---

# 16. REVIEW BUNDLE MANIFEST

Generate:

```text
review_manifest.json
```

At minimum capture:

```json
{
  "project": "",
  "timestamp": "",
  "branch": "",
  "commit": "",
  "tool_name": "",
  "tool_version": "",
  "selected_files": 0,
  "excluded_files": 0,
  "security_scan_status": ""
}
```

Where practical, record why source files were selected for review.

---

# 17. AOCL + SNAPSHOT + REVIEW BUNDLE RELATIONSHIP

Preserve this conceptual boundary:

```text
AOCL
= durable project knowledge

Context Snapshot
= fast point-in-time synchronization

Full Snapshot
= reconstructable sanitized engineering state

Review Bundle
= optimized AI/human comprehension package

Validation
= evidence that the above capabilities exist and behave correctly
```

Do not merge these concepts into one ambiguous artifact if doing so reduces usefulness.

They may share internal modules and policies.

---

# 18. SHARED IMPLEMENTATION PREFERENCE

Where an existing repository already has working scripts:

- extend them when practical
- avoid introducing parallel implementations
- preserve working operator commands when reasonable
- document compatibility changes

Where multiple scripts duplicate functionality, do not perform a large consolidation unless clearly safe and within scope.

Record duplication as technical debt if consolidation should be handled separately.

Longer term, repositories may delegate this functionality to a shared AgentOps Core implementation.

This directive must not require that migration immediately.

---

# 19. CONFIGURATION AND POLICY

Prefer central configuration over hard-coded repo-specific exclusions.

If adding configuration is appropriate, a repository may use a file such as:

```text
.agentops.yaml
```

or an equivalent existing convention.

Potential settings:

```yaml
snapshot:
  max_file_size_mb: 10
  excluded_dirs: []
  excluded_patterns: []

review:
  include_source: true
  combined_docs: true

security:
  secret_scan: true

git:
  recent_commits: 25
  include_diff_stat: true
  include_full_diff: false
```

Do not introduce configuration merely for cosmetic abstraction.

Use it where it improves reuse, safety, or maintainability.

---

# 20. VALIDATION REQUIREMENTS

After implementation or reconciliation, validate each capability.

## AOCL Validation

Check:

- required/corresponding directories exist
- `docs/README.md` or equivalent explains the structure
- roadmap is discoverable
- architecture is discoverable
- runbooks are discoverable
- audits are discoverable
- handoffs are discoverable
- stable context is discoverable
- logs are treated separately from durable documentation

## Context Snapshot Validation

Generate a real Context Snapshot and verify:

- output exists
- timestamp is correct
- Git state is present
- important project context is represented
- output is readable by another agent

## Full Snapshot Validation

Generate a real Full Snapshot and verify:

- archive opens successfully
- expected source exists
- repository-relative paths are preserved
- prohibited directories are absent
- secrets are not knowingly packaged
- excluded-file inventory exists
- manifest exists and is valid
- Git metadata exists
- checksums exist when required
- context snapshot is included or referenced

## Review Bundle Validation

Generate a real Review Bundle and verify:

- repository tree exists
- inventory exists
- Git state exists
- AOCL/docs are represented
- selected source is represented
- combined docs/source are readable when generated
- security policy was applied
- manifest exists
- artifact is meaningfully smaller/more focused than a Full Snapshot when practical

---

# 21. REQUIRED AGENTOPS BASELINE AUDIT

Create a timestamped audit under the repository's audit documentation location.

Preferred canonical location:

```text
docs/audits/agentops_baseline_audit_<timestamp>.md
```

Use an equivalent existing audit location if appropriate.

The report must include:

```text
Repository:
Timestamp:
Branch:
Commit:
Directive Version:

AOCL:
Context Snapshot:
Full Snapshot:
Review Bundle:
Security:
Overall:

Existing implementations discovered:

Files/commands inspected:

Changes made:

Capabilities preserved:

Capabilities enhanced:

Capabilities added:

Duplicate functionality identified:

Intentional deviations from baseline:

Security findings:

Test artifacts generated:

Validation results:

Remaining gaps:

Recommended next actions:
```

Use statuses such as:

```text
PASS
PARTIAL
WARN
FAIL
NOT_APPLICABLE
```

The audit must be evidence-backed.

Do not report PASS merely because files exist.

---

# 22. REQUIRED HANDOFF

If the repository uses AOCL handoffs, create or update a handoff describing:

- what was discovered
- what was changed
- what was intentionally not changed
- generated snapshot/review commands
- validation result
- known gaps
- recommended continuation point

Preferred location:

```text
docs/handoffs/
```

Do not overwrite an unrelated active handoff.

---

# 23. COMMAND / OPERATOR EXPERIENCE

If the repository already has operator commands, preserve them where reasonable.

The long-term AgentOps command model is conceptually:

```bash
agentops assess .
agentops aocl validate .
agentops snapshot . --mode context
agentops snapshot . --mode full
agentops review .
agentops validate .
```

Existing repositories do NOT need to implement this exact CLI now.

Repo-local scripts are acceptable if they satisfy the current capability contract.

---

# 24. CHANGE SAFETY

Before editing:

```bash
git status --short
git log -5 --oneline --decorate
```

Do not discard existing uncommitted work.

Do not reset the repository.

Do not clean the working tree.

Do not modify unrelated files.

Do not delete existing docs or logs.

Do not modify secrets or environment files.

Do not commit unless explicitly instructed.

After editing:

```bash
git status --short
```

Also show the files created or modified by this directive.

---

# 25. NO COMMIT BY DEFAULT

Do not commit changes unless explicitly instructed.

If all validation succeeds and a commit is later approved, a suggested commit message is:

```text
Establish AgentOps repository baseline
```

If the work primarily enhances existing tooling, a more appropriate message may be:

```text
Enhance AgentOps snapshot and review lifecycle
```

---

# 26. SUCCESS CRITERIA

This directive is complete only when the repository has been inspected and the result is known for all four primary capabilities:

```text
AOCL
Repository Snapshot
Review Bundle
Validation
```

A successful repository should allow a new agent to:

1. pull or open the repository
2. locate durable project context
3. understand architecture and roadmap
4. determine current Git/project state
5. generate a lightweight Context Snapshot
6. generate a sanitized Full Snapshot
7. generate an optimized Review Bundle
8. understand what was intentionally excluded
9. verify the artifact manifest/security status
10. continue engineering work without reconstructing project history from scratch

---

# 27. FINAL RESPONSE FORMAT

At completion, report:

```text
AgentOps Baseline Result

AOCL:                PASS/PARTIAL/WARN/FAIL
Context Snapshot:    PASS/PARTIAL/WARN/FAIL
Full Snapshot:       PASS/PARTIAL/WARN/FAIL
Review Bundle:       PASS/PARTIAL/WARN/FAIL
Security:            PASS/WARN/FAIL
Overall:             PASS/PARTIAL/WARN/FAIL

Existing tooling reused:
- ...

New or enhanced files:
- ...

Generated validation artifacts:
- ...

Known gaps:
- ...

Recommended next action:
- ...
```

Keep the response evidence-based and reference exact repository paths and commands.

---

# END DIRECTIVE

**AgentOps Repository Baseline Directive v1.0**  
**2026-08-09**
