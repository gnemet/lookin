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

- **Oracle JIRA DB** — Issues, Worklogs, SLA Events, Comments, Users, Projects
- **Active Directory (LDAP)** — User directory, Org structure, OSINT
- **TER REST API** — Ulyssys time management, Leave, Schedules
- **GitLab API** — Commits, MRs, Pipelines
- **JobCtrl API** — PC Density, Custom Reports

## Architecture

The platform follows a **hub-and-spoke model**:

- **jiramntr** is the central DWH hub — ingests all external sources via FDW/REST/LDAP
- **johanna** provides AI chat on top of the DWH data
- **mcp-forge** builds the knowledge layer (RAG, catalog, teaching pipeline)
- **aichat** and **datagrid** are shared Go libraries used by multiple services
- **lookin** provides interactive architecture documentation

## Key Design Principles

- **Markdown-driven** — BI queries, KPI scorecards, and parameters all defined in `.md` files
- **Zero-hardcode** — all configuration via YAML, no magic constants
- **SCD2 historization** — all dimension tables use `tstzrange` validity periods
- **LDAP-based ACL** — folder-level whitelist/blacklist from Active Directory
- **Hierarchy-aware** — ltree-based org tree for RLS and KPI depth filtering
