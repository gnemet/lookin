# 🧠 MCP Catalog Pipeline

> *Metadata-Only Protocol — teach AI about your data without exposing it*

## 💡 What is MCP?
The **Model Context Protocol** provides AI models with structured knowledge about the DWH schema, join patterns, and business rules — while keeping all actual data safely on-premise.

## 📦 Components

| Component | Count | Purpose |
|---|---|---|
| 📋 JSON Catalogs | 50 files | Column definitions for Datagrid UI |
| 🔗 Chain MCPs | 12 .md | Domain-specific knowledge docs |
| 📝 Master Template | 1 file | `dwh_mcp_template.md` — architect context |

## 🔄 Pipeline

| Step | Component | Output |
|---|---|---|
| 1️⃣ | 🏭 MCP Generator | Auto-generates 750+ column descriptions from DB |
| 2️⃣ | 🔗 Chain MCPs | 12 domain-specific markdown files |
| 3️⃣ | 🧬 Gemini Embedding | `text-embedding-004` → 768-dim vectors |
| 4️⃣ | 📦 pgvector Store | `meta.mcp_embeddings` with HNSW index |
| 5️⃣ | 🔍 RAG Search | Cosine similarity at query time |

## 🔒 Key Principle
> **Metadata-Only**: Only table names, column descriptions, and join recipes go to the LLM.
> Zero business data ever leaves the corporate network.

## 🔗 Chain MCP Domains
worklogs • issues • users • projects • SLA • calendar • custom fields • priorities • statuses • hierarchy • BI queries • KPI definitions
