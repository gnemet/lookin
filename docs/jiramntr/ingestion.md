# 📥 Data Ingestion Pipeline

> *Three source systems → one Star Schema*

## 🌐 Data Sources
| Source | Protocol | What we get |
|---|---|---|
| 🟠 **Oracle DB** (Jira) | `oracle_fdw` | Issues, worklogs, custom fields, links |
| 🔵 **Active Directory** | LDAP sync | Users, org hierarchy, photos, departments |
| 🟢 **TER** (Leave System) | REST API | Absences, work schedules |
| 🟡 **SharePoint** | `sp-download` (Go) | Excel exports *(planned)* |
| ⚪ **Google Drive** | CSV loader | CSV exports, backups |


## 🔌 How Data Flows
```
Oracle DB ──→ oracle_fdw ──→ ext schema ──┐
LDAP      ──→ ext.ldap_import ───────────→├──→ ETL ──→ dwh schema
TER API   ──→ ext.ter_data ─────────────→┘
```


## ⚙️ ETL Orchestrator
- 📆 **Yearly partitioned** — processes one year at a time
- 🔍 **Pre-flight TCP checks** — validates source availability before running
- 📈 **HWM pattern** — High Water Mark for incremental loading
- 📊 **Observability** — logs timing, row counts, errors to `meta.etl_log`
- 🕔 **Schedule** — nightly cron on the prod server
