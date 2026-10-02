# AgentOps Core — Background and Problem Statement

**Version:** v0.1  
**Date:** 2026-08-12

## Problem

AI-assisted engineering creates a continuity problem. A repository may contain current code while failing to capture why the architecture exists, what decisions were made, which approaches failed, current priorities, active procedures, known risks, and where the next agent should continue.

As agents change, chats end, context windows expire, and work moves between tools, critical knowledge is repeatedly rediscovered. This creates duplicated investigation, contradictory decisions, architectural regressions, token waste, longer onboarding, poor handoffs, and dependence on individual chats.

## Thesis

A modern repository should contain enough durable operating context that a capable agent can pick it up and continue work without requiring the original chat history.

AgentOps combines durable context, lifecycle snapshots, optimized review artifacts, validation, handoffs, and future persistent semantic memory.

## Why Markdown First

Markdown is portable, version-controlled, diffable, human-readable, model-readable, tool-independent, durable, and easy to bootstrap. It is the initial substrate, not necessarily the final memory architecture.

## Why Snapshots

Snapshots capture point-in-time engineering state for review, debugging, architecture analysis, handoff, audit, recovery, and remote agent synchronization.

## Why Review Bundles

A full repo may be too large or noisy for efficient AI review. Review Bundles concentrate repo tree, important docs, AOCL, Git state, selected source, manifests, and security information.

## Why Validation

A folder existing does not prove the system works. Validation must prove context is discoverable, artifacts generate, prohibited content is excluded, manifests are valid, and handoff information is usable.

## Future Memory Layer

Possible technologies include SQLite, SQLite FTS, embedded vector storage, local vector databases, external vector databases, or hybrids. The stable requirement is that project knowledge becomes easier to retrieve over time without forcing users to understand embeddings or vector search internals.
