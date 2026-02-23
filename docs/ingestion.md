# Data Ingestion Pipeline

## Overview
Extracts data from **3 source systems** and loads it into the PostgreSQL DWH via Foreign Data Wrappers and ETL scripts.

## Data Sources
| Source | Protocol | Data |
|---|---|---|
| 🟠 **Oracle DB (Jira)** | oracle_fdw | Issues, worklogs, custom fields |
| 🔵 **Active Directory** | LDAP sync | Users, hierarchy, thumbnails |
| 🟢 **Leave System (TER)** | REST API | Absences, work schedules |

## Architecture
```
Oracle → oracle_fdw → ext schema → ETL → dwh schema
LDAP   → ext.ldap_import → ETL → dwh schema
TER    → REST Client (Go) → ETL → dwh schema
```

## ETL Orchestrator
- **Yearly partitioned** — processes one year at a time
- **Pre-flight TCP checks** — validates source availability
- **HWM (High Water Mark)** — incremental pattern for efficiency
- **Observability** — logs timing, row counts, errors to `meta.etl_log`

## Schedule
Runs nightly via cron on the butalam server.
