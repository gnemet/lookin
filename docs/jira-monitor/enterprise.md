# 🏢 JIRA-MONITOR

> *Enterprise ecosystem — 6 projects, 1 platform*

## Projects

| Project | Role | Tech | Port |
|---------|------|------|------|
| **Jiramntr** | DWH · BI · KPI · ETL | Go | :8080 |
| **Johanna** | AI Chat · NL→SQL | Go | :8082 |
| **aichat** | Shared NL→SQL Pipeline | Go lib | — |
| **MCP-Forge** | RAG Knowledge Builder | Python | — |
| **LookIn** | Architecture Viewer | HTML/JS | — |
| **Datagrid** | Table Renderer | Go lib | — |

## Infrastructure

- **Server**: sys-butalam01 (Ubuntu, PostgreSQL 17.7)
- **GPU**: sys-gpu01 (Ollama LLM — sqlcoder, llama3, qwen3)
- **Auth**: ldap.alig.hu (Active Directory)
- **Source**: Oracle FDW → racdb.alig.hu

## Databases

| Database | Purpose |
|----------|---------|
| `jiramntr_db` | Star Schema DWH (dwh, meta, oltp schemas) |
| `ragdb` | RAG embeddings + knowledge (pgvector) |

## Git

All repos: `https://github.com/gnemet/<project>.git`
