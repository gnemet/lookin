# RAG Pipeline

## Overview
**Retrieval-Augmented Generation** using pgvector for semantic search over MCP documentation.

## How It Works
1. **Embedding** — Chain MCP `.md` files are split into chunks and embedded via Gemini `text-embedding-004`
2. **Storage** — Vectors stored in `meta.mcp_embeddings` with HNSW index
3. **Search** — User question is embedded, then cosine similarity finds top-K relevant chunks
4. **Context** — Retrieved chunks are injected into the LLM prompt

## Two Modes
| Mode | Description |
|---|---|
| **pgvector HNSW** | Semantic similarity search (default) |
| **Direct MCP** | Falls back to full MCP template if RAG fails |

## Embedding Model
- **Provider**: Google Gemini
- **Model**: `text-embedding-004`
- **Dimension**: 768

## Knowledge Sources
- 12 chain MCP files (domain-specific)
- DWH schema descriptions
- User hierarchy (LDAP)
- BI query catalog
