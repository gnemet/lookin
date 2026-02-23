# Application Stack

## Overview
**Go backend** (port 8080) serving a premium dark-themed web UI built with HTMX + Vanilla CSS.

## REST API Endpoints
| Endpoint | Purpose |
|---|---|
| `/api/chat` | AI conversational SQL (Johanna) |
| `/api/bi` | BI Query Library execution |
| `/api/kpi` | KPI Dashboard data |
| `/api/employee` | Employee directory |
| `/api/onsall` | On-call schedules |

## Web UI
- **HTMX** for interactive updates without JavaScript frameworks
- **Vanilla CSS** — premium dark theme, responsive
- **Datagrid Library v1.2** — sortable tables with LOV parameters

## Middleware
- **RLS (Row-Level Security)** — per-user data visibility based on org hierarchy
- **Session management** — LDAP/cookie authentication

## KPI Dashboard
YAML-driven KPI definitions with configurable rating scales, thresholds, and multilingual labels.

## BI Query Library
Markdown-based saved queries with LOV (List of Values) parameter inputs.
