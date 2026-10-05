# 🏢 JIRA-MONITOR

> *Enterprise ecosystem — 6 projects, 1 platform*

## Projects

| Project | Role | Tech | Port |
|---------|------|------|------|
| **Jiramntr** | DWH · BI · KPI · ETL | Go | :8080 |
| **Johanna** | AI Chat · NL→SQL | Go | :8082 |
| **ai-chat** | Shared NL→SQL Pipeline | Go lib | — |
| **MCP-Forge** | RAG Knowledge Builder | Python | — |
| **LookIn** | Architecture Viewer | HTML/JS | — |
| **Datagrid** | Table Renderer | Go lib | — |

## Infrastructure

- **Server**: prod server (Ubuntu, PostgreSQL 17.7)
- **GPU**: GPU server (Ollama LLM — sqlcoder, llama3, qwen3)
- **Auth**: Active Directory (LDAP)
- **Source**: Oracle FDW → the JIRA Oracle database

## Databases

| Database | Purpose |
|----------|---------|
| `jiramntr_db` | Star Schema DWH (dwh, meta, oltp schemas) |
| `ragdb` | RAG embeddings + knowledge (pgvector) |

## Git

All repos: `https://github.com/gnemet/<project>.git`
