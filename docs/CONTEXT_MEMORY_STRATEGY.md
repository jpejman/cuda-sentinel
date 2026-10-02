# AgentOps Persistent Context and Memory Strategy

**Version:** v0.1  
**Date:** 2026-08-12  
**Decision Status:** Storage backend intentionally undecided

## Goal

AgentOps should evolve from static durable files into a permanently growing, queryable project knowledge system that survives agents, chats, tools, clones, machines, releases, and years of project evolution.

## Current Layer

Primary sources are AOCL docs, Git history, snapshot manifests, and review manifests.

## Future Requirements

Support exact and semantic lookup, source citations, timestamps, version/commit awareness, lineage, stale-content detection, deduplication, conflicting-context detection, incremental refresh, selective deprecation, and cross-repo relationships.

## Candidate Storage Approaches

### SQLite

Embedded, portable, transactional, structured, easy to back up, no server required. Potential additions include FTS, vector extensions, embeddings tables, and hybrid retrieval.

### Dedicated Vector Database

Strong semantic retrieval at scale and metadata filtering, but adds operational complexity and dependencies.

### Hybrid

A likely future architecture may separate structured truth from semantic retrieval without requiring the same storage engine. No choice is frozen.

## Non-Technical User Requirement

A user should not need to know what an embedding is, which dimension to use, how to chunk Markdown, overlap percentages, ANN indexes, cosine similarity, vector normalization, or re-indexing strategy.

Expected experience:

```bash
agentops knowledge build .
```

AgentOps should automatically discover eligible sources, classify durable content, avoid secrets, chunk, choose/configure an embedding model, generate embeddings, index them, retain source metadata, validate retrieval, and report success in human language.

## Retrieval Contract

Semantic answers should return supporting source paths, timestamps, relevant commit/version, and retrieval confidence/quality signals. The memory layer must not silently become an unsourced truth database.

## Memory Growth

Future automatic memory should be driven by meaningful events such as architecture decisions, roadmap changes, releases, audits, handoffs, major module changes, and resolved incidents.

## Embedding Cost Awareness

Future AgentOps Model/API Intelligence should choose embedding providers/models using price, quality, privacy, local availability, throughput, corpus size, and re-index frequency. Normal users should receive automatic defaults; advanced users may override them.

## Open Questions

1. Should SQLite be the default metadata store?
2. Should vector storage be embedded or external?
3. How should knowledge be versioned against Git commits?
4. How should superseded context be represented?
5. How should cross-repo context work?
6. Which content should be embedded automatically?
7. Should code be embedded, summarized, or indexed differently from docs?
8. How should retrieval quality be evaluated?
9. How should local/private embedding models integrate?
10. How should memory portability work between machines?
