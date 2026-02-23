# 📊 Data Warehouse (DWH)

> *Consolidated analytics layer — single source of truth*

## 🏗️ Architecture
**PostgreSQL 16** Star Schema with full SCD2 historization.
All business data flows through here — Jira, LDAP, and Leave System consolidated into one analytics-ready model.

## 🔐 Security
- **Row-Level Security (RLS)** — users only see their own hierarchy
- Session variable `jiramntr.login_user` drives visibility
- Even SQL Lab queries are filtered by RLS

## 📦 Schemas
| Schema | Purpose | Access |
|---|---|---|
| `dwh` | ⭐ Star Schema (facts + dims) | Primary |
| `meta` | 🧠 AI metadata, embeddings | Auxiliary |
| `ext` | 📥 External imports staging | Internal only |
| `oltp` | 🔌 Oracle FDW bridge | ⛔ Forbidden |

## 📋 Key Tables
| Table | Type | What it stores |
|---|---|---|
| `fact_daily_worklogs_h` | ⏱️ Fact | Hours logged per person/issue/day |
| `fact_sla_events` | 🚨 Fact | SLA breaches and response times |
| `dim_issue_h` | 📝 Dim | Jira issues (status, priority, assignee) |
| `dim_user_h` | 👤 Dim | Users from LDAP (hierarchy, manager) |
| `dim_project_h` | 📁 Dim | Projects with leads |
| `dim_calendar` | 📅 Dim | Date dimension (YYYYMMDD) |

## 🔄 Historization
All `_h` tables use `tstzrange` for Level 2 SCD tracking.
Use **views** (without `_h` suffix) for current-state queries — they auto-filter for active records.

## ⚙️ ETL
Yearly partitioned orchestrator runs nightly on butalam, with pre-flight checks and HWM incremental loading.
