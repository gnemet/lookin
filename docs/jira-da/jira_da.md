# 🏗️ JiraDa — Enterprise Platform

> *Unified project environment for JIRA analytics, AI chat, and DWH management*

## Platform Repos

| Repo | Language | Description |
|------|----------|-------------|
| **jiramntr** | Go | JIRA DWH monitor — ETL, KPI, BI, Datagrid, Security (RLS) |
| **johanna** | Go | AI chat persona — NL→SQL→NL, RAG, WebSocket, Feedback |
| **mcp-forge** | Python | MCP chain builder — 7 adapters, 4 generators, Claude Teacher |
| **aichat** | Go | Shared AI module — pipeline, types, feedback, persona |
| **datagrid** | Go | Dynamic data grid — pivot tables, JSON catalog driven |
| **lookin** | HTML/JS | Architecture viewer — Mermaid + PNG diagrams, drill-down |

## Infrastructure

| Server | Services |
|--------|----------|
| **sys-butalam01** (Prod) | jiramntr, johanna, mcp-forge, datagrid, lookin |
| **sys-gpu01** (GPU) | jiramntr (Ollama inference) |

## Data Sources

- **JIRA Cloud API** — Issues, Worklogs, SLA Events, Comments, Users, Projects
- **Oracle LDAP** — User directory, Org structure
- **GitLab API** — Commits, MRs, Pipelines
- **JobCtrl API** — Daily density, SLA data
- **Confluence** — Documentation, Spaces

## Databases

| Database | Schemas |
|----------|---------|
| **jiramntr_db** | `dwh` (Star Schema, SCD2), `ext` (staging), `meta` (audit, MCP), `oltp` (FDW → Oracle) |
| **ragdb** | `rag` (embeddings, knowledge, audit_log), `mcp` (knowledge, feedback, teaching) |

## DevOps

- **GPG Vault** (AES256) — `vault.sh lock|unlock|verify|diff`
- **Environment switching** — `switch_env.sh` (auto-detect hostname)
- **Deploy scripts** — per-server deployment with `sshpass`
- **systemd timers** — Claude Teacher, embedding pipeline
- **GitHub Actions** — CI across all repos
- **Project Board** — Unified tracking via `/commit-all`, `/new-issue`, `/deploy`
