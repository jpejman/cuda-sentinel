# AgentOps Validation Specification

**Specification Version:** v0.1  
**Date:** 2026-08-12

## Purpose

Validation determines whether AgentOps capabilities actually work. File presence alone is insufficient.

## Status Values

`PASS`, `PARTIAL`, `WARN`, `FAIL`, `NOT_APPLICABLE`

## AOCL Validation

Verify durable context, roadmap, architecture, runbooks, audits, handoffs, docs index, and separation of transient logs.

## Context Snapshot Validation

Generate a real artifact and verify output, timestamp, Git state, current context, and readability.

## Full Snapshot Validation

Generate a real artifact and verify archive integrity, expected source, exclusions, secret policy, manifest, inventories, Git metadata, and checksums when required.

## Review Bundle Validation

Generate a real artifact and verify repo tree, inventory, Git evidence, AOCL, selected source, security policy, manifest, and review focus.

## Required Audit

Preferred output: `docs/audits/agentops_baseline_audit_<timestamp>.md`, recording repo, timestamp, branch, commit, version, discovered capabilities, changes, validation evidence, security findings, gaps, and next action.
