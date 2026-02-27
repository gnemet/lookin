# 🧠 ragdb — RAG Database

> *Dedicated vector database for AI knowledge and embeddings*

## Connection

```
host=localhost port=5432 dbname=ragdb user=root
```

Environment: `RAG_PG_HOST`, `RAG_PG_PORT`, `RAG_PG_DB`, `RAG_PG_USER`, `RAG_PG_PASSWORD`

## Tables

| Table | Purpose | Rows |
|-------|---------|------|
| `rag.knowledge` | MCP teach rules (topic → content) | ~100 |
| `rag.embeddings` | Unified vectors (multi-provider, partitioned) | ~52 |
| `rag.issue_embeddings` | Jira issue vectors | — |
| `rag.audit_log` | AI query audit trail (cost, tokens) | growing |

## Embeddings

Unified table with `provider` column:

| Provider | Model | Dimensions |
|----------|-------|-----------|
| `gemini` | text-embedding-004 | 768 |
| `ollama` | nomic-embed-text | 768 |

### Partitions (by collection)

| Partition | Content |
|-----------|---------|
| `embeddings_dwh` | Star Schema + DWH functions |
| `embeddings_hr` | HR / org charts |
| `embeddings_meta` | Metadata, config |
| `embeddings_confluence` | Confluence pages |
| `embeddings_docs` | Local documents |

## Functions

| Function | Purpose |
|----------|---------|
| `fn_search_knowledge(query, limit)` | Full-text search on knowledge |
| `fn_search_embeddings(vector, threshold, top_k)` | Cosine similarity search |
| `fn_upsert_knowledge(topic, content, source)` | Insert or update knowledge |
| `fn_search_issues(vector, threshold, top_k)` | Search issue embeddings |
| `fn_get_stats()` | Collection statistics |
| `fn_cleanup_stale(days)` | Purge old entries |
