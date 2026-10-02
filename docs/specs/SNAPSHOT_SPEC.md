# Repository Snapshot Specification

**Specification Version:** v0.1  
**Date:** 2026-08-12

## Purpose

Capture portable point-in-time repository engineering state.

## Modes

**Context Snapshot:** compact agent synchronization artifact containing project identity, architecture/roadmap references, Git state, module/file overview, current status, important docs, and continuation point.

**Full Snapshot:** sanitized engineering reconstruction package containing source, docs, metadata, context, security output, and `snapshot_manifest.json`.

## Metadata

Capture branch, commit, recent Git history, working-tree status, changed files, remotes, tags, file inventory, excluded-file inventory, and checksums where available.

## Exclusions

Exclude `.git/`, dependency directories, virtual environments, caches, build outputs, runtime artifacts, large model/data files, secrets, credentials, `.env*`, browser/session state, and other sensitive or generated content.

## Size Management

Support maximum file size, excluded directory/file rules, and an explicit exclusion inventory with reason. Large ZIP archives that materially increase snapshot size or performance cost should be excluded from nested snapshots and recorded explicitly.

## Security

Perform best-effort secret detection before finalizing portable artifacts. Never include secret values in reports. Treat `git diff` as potentially sensitive.

## Manifest

At minimum: project, timestamp, branch, commit, mode, tool name/version, included/excluded counts, archive size, and security scan status.
