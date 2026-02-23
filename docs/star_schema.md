# ⭐ Star Schema (DWH)

> *Kimball-style design with Level 2 SCD historization*

## 📊 Fact Tables
### ⏱️ fact_daily_worklogs_h
Time tracking: logged hours per person per issue per day. Primary fact table for effort analysis.
| Column | Type | Purpose |
|---|---|---|
| `worklog_sid` | bigint | Surrogate key (unique row ID) |
| `worklog_key` | text | Jira worklog ID (business key) |
| `calendar_id` | integer | FK → dim_calendar.day_id (YYYYMMDD format) |
| `user_sid` | bigint | FK → dim_user_h.user_sid (who logged) |
| `project_sid` | bigint | FK → dim_project_h.project_sid |
| `issue_sid` | bigint | FK → dim_issue_h.issue_sid |
| `seconds_worked` | integer | Time logged in seconds |
| `hours_worked` | numeric(10,2) | Time logged in decimal hours |
| `valid_period` | tstzrange | SCD2 validity range (historization) |

### 🚨 fact_sla_events
SLA breach/success events. Tracks response and resolution time against targets.
| Column | Type | Purpose |
|---|---|---|
| `sla_event_id` | bigint | Primary key |
| `issue_id` | bigint | FK → dim_issue_h.issue_id |
| `priority_id` | bigint | FK → dim_priority_h.priority_id (cast to bigint) |
| `sla_type` | text | SLA type (response_time, resolution_time) |
| `breached` | boolean | True if SLA was breached |
| `elapsed_ms` | bigint | Elapsed time in milliseconds |
| `target_ms` | bigint | SLA target in milliseconds |



## 📐 Dimension Tables
| Dim | Key | Description |
|---|---|---|
| `dim_user_h` | `user_sid` | User directory from LDAP/Active Directory. Includes hierarchy (manager). |
| `dim_issue_h` | `issue_sid` | Jira issues with full SCD2 history. Use dim_issue view for current state. |
| `dim_project_h` | `project_sid` | Jira projects with project lead and key. |
| `dim_calendar` | `day_id` | Date dimension for time-based analysis. One row per calendar day. |


## 🔗 Join Recipes
- **Issue → Worklogs**: `i.issue_id = f.issue_id`
- **User → Worklogs**: `u.user_id = f.user_id`
- **Calendar → Worklogs**: `c.day_id = f.calendar_id`
- **Project → Issue**: `i.issue_key LIKE p.project_key || '-%'`


## 🔄 Views
Use `dwh.dim_issue` (no `_h`) for current state — auto-filters `upper_inf(valid)`.
