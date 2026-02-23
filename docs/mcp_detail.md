# MCP Catalog Pipeline

## Overview
The **Model Context Protocol** system that provides AI models with structured metadata about the DWH — without exposing business data.

## Components
| Component | Count | Purpose |
|---|---|---|
| JSON Catalogs | 50 files | Table/column definitions for Datagrid UI |
| Chain MCPs | 12 .md files | Domain-specific knowledge docs |
| MCP Template | 1 master | `dwh_mcp_template.md` — architect context |

## Pipeline
1. **MCP Generator** → Auto-generates 750+ column descriptions from DB schema
2. **Chain MCPs** → 12 domain .md files (worklogs, issues, users, SLA, etc.)
3. **Gemini Embedding** → `text-embedding-004` converts to vectors
4. **pgvector Store** → `meta.mcp_embeddings` with HNSW index
5. **RAG Search** → Similarity search at query time

## Key Principle
> **Metadata-Only**: Only table names, column descriptions, and join recipes go to the LLM. Zero business data leaves the network.

## Auto-Generation
The MCP Generator reads `information_schema` and produces catalog JSON + chain MCP markdown files automatically.
