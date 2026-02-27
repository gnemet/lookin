# 🧠 MCP Catalog Pipeline

> *Metadata-Only Protocol — teach AI about your data without exposing it*

## 💡 What is MCP?
The **Model Context Protocol** provides AI models with structured knowledge about the DWH schema,
join patterns, and business rules — while keeping all actual data safely on-premise.


## 📦 Components
| Component | Count | Purpose |
|---|---|---|
| 📋 JSON Catalogs | 32 files | Column definitions for Datagrid UI |
| 🔗 Chain MCPs | 3 .md | Domain-specific knowledge docs |
| 📝 Master Template | 1 file | `dwh_mcp_template.md` — architect context |


## 🔄 Pipeline
| Step | What happens |
|---|---|
| 1️⃣ | 🏭 MCP Generator auto-generates 750+ column descriptions from DB |
| 2️⃣ | 🔗 Chain MCPs — 3 domain-specific markdown files |
| 3️⃣ | 🧬 Gemini Embedding — `text-embedding-004` → 768-dim vectors |
| 4️⃣ | 📦 pgvector Store — `meta.mcp_embeddings` with HNSW index |
| 5️⃣ | 🔍 RAG Search — cosine similarity at query time |


## 🔒 Key Principle
> **Metadata-Only**: Only table names, column descriptions, and join recipes go to the LLM.
> Zero business data ever leaves the corporate network.
