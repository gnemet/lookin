# ⭐ Star Schema (DWH)

> *Kimball-style design with Level 2 SCD historization*

## 📊 Fact Tables

### ⏱️ fact_daily_worklogs_h
Primary effort tracking — one row per worklog per day.
| Column | Type | Purpose |
|---|---|---|
| `user_sid` | FK | Who logged |
| `issue_sid` | FK | Which issue |
| `calendar_id` | FK | When (YYYYMMDD) |
| `hours_worked` | numeric | Decimal hours |
| `valid` | tstzrange | SCD2 range |

### 🚨 fact_sla_events
SLA compliance tracking.
| Column | Type | Purpose |
|---|---|---|
| `elapsed_ms` | bigint | Actual response time |
| `target_ms` | bigint | SLA target |
| `breached` | boolean | Passed or failed? |

## 📐 Dimension Tables

| Dim | Key | Key Columns |
|---|---|---|
| 👤 `dim_user_h` | `user_sid` | name, email, department, **manager** |
| 📝 `dim_issue_h` | `issue_sid` | key, status, priority, **assignee** |
| 📁 `dim_project_h` | `project_sid` | key, name, **project_lead** |
| 📅 `dim_calendar` | `day_id` | date, year, week, **is_workday** |

## 🔗 Join Recipes
- **Issue → Worklogs**: `i.issue_id = f.issue_id`
- **User → Worklogs**: `u.user_id = f.user_id`
- **Calendar → Worklogs**: `c.day_id = f.calendar_id`
- **Project → Issue**: `i.issue_key LIKE p.project_key || '-%'`

## 🔄 Views
Use `dwh.dim_issue` (no `_h`) for current state — auto-filters `upper_inf(valid)`.
