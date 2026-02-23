# Data Warehouse (DWH)

## Overview
A **PostgreSQL 16** Star Schema storing consolidated data from Jira, LDAP, and the Leave System.

## Key Components
- **Schema**: `dwh` (primary), `meta` (AI metadata), `ext` (external imports)
- **Historization**: Level 2 SCD (Slowly Changing Dimensions) using `tstzrange` columns
- **Security**: Row-Level Security (RLS) based on org hierarchy

## Fact Tables
| Table | Description |
|---|---|
| `fact_daily_worklogs_h` | Time tracking: hours per person per issue per day |
| `fact_sla_events` | SLA breach/success events with response times |

## Dimension Tables
| Table | Description |
|---|---|
| `dim_issue_h` | Jira issues with full SCD2 history |
| `dim_user_h` | Users from LDAP (hierarchy, department) |
| `dim_project_h` | Jira projects with project leads |
| `dim_calendar` | Date dimension (one row per day) |
| `dim_status_h` | Issue status names |
| `dim_priority_h` | Issue priority levels |

## Views (Current State)
Use `dwh.dim_issue`, `dwh.dim_user` etc. for current-state queries.
These automatically filter for active SCD2 records.

## ETL
Yearly partitioned orchestrator runs nightly, loading data from Oracle FDW and LDAP.
