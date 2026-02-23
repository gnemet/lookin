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
| Table | Type | Description |
|---|---|---|
| `dim_calendar` | 📐 Dim | Date dimension for time-based analysis. One row per calendar day. |
| `dim_issue_h` | 📐 Dim | Jira issues with full SCD2 history. Use dim_issue view for current state. |
| `dim_project_h` | 📐 Dim | Jira projects with project lead and key. |
| `dim_user_h` | 📐 Dim | User directory from LDAP/Active Directory. Includes hierarchy (manager). |
| `fact_daily_worklogs_h` | ⏱️ Fact | Time tracking: logged hours per person per issue per day. Primary fact table for effort analysis. |
| `fact_sla_events` | ⏱️ Fact | SLA breach/success events. Tracks response and resolution time against targets. |


## 🔄 Historization
All `_h` tables use `tstzrange` for Level 2 SCD tracking.
Use **views** (without `_h` suffix) for current-state queries — they auto-filter for active records.


## ⚙️ ETL
Yearly partitioned orchestrator runs nightly on butalam,
with pre-flight checks and HWM incremental loading.
