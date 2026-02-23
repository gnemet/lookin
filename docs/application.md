# 🖥️ Application Stack

> *Go backend + HTMX frontend — premium dark theme*

## 📡 REST API
| Endpoint | Purpose |
|---|---|
| `/api/chat` | 🤖 AI conversational SQL (Johanna) |
| `/api/bi` | 📊 BI Query Library — run saved queries |
| `/api/kpi` | 📈 KPI Dashboard — YAML-driven scoring |
| `/api/employee` | 👤 Employee directory + hierarchy |
| `/api/oncall` | 📞 On-call schedules |


## 🎨 Web UI
- **HTMX** — interactive updates without SPA overhead
- **Vanilla CSS** — premium dark theme, fully responsive
- **Datagrid Library v1.2** — sortable, filterable tables with LOV params


## 🔒 Middleware
| Layer | Purpose |
|---|---|
| 🛡️ RLS | Row-Level Security per user hierarchy |
| 🔑 Auth | LDAP/cookie-based session management |
| 📝 Audit | Request logging to `meta.etl_log` |


## 📈 KPI Dashboard
YAML-driven KPI definitions with:
- Configurable rating scales (1-5 stars)
- Threshold-based color coding
- Multilingual labels (EN/HU)
