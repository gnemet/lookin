# Star Schema (DWH)

## Overview
The analytics data model following **Kimball Star Schema** design with SCD2 historization.

## Fact Tables
### fact_daily_worklogs_h
Primary effort tracking table. One row per worklog entry per day.
- **Grain**: person × issue × day
- **Measures**: `seconds_worked`, `hours_worked`
- **FKs**: `user_sid`, `issue_sid`, `project_sid`, `calendar_id`

### fact_sla_events
SLA compliance tracking.
- **Measures**: `elapsed_ms`, `target_ms`, `breached`
- **FKs**: `issue_id`, `priority_id`

## Dimension Tables
| Dimension | Key | Description |
|---|---|---|
| `dim_issue_h` | `issue_sid` | Jira issues (status, priority, assignee) |
| `dim_user_h` | `user_sid` | Users (name, department, manager) |
| `dim_project_h` | `project_sid` | Projects (key, name, lead) |
| `dim_calendar` | `day_id` | Calendar (YYYYMMDD format) |
| `dim_status_h` | `status_sid` | Issue statuses |
| `dim_priority_h` | `priority_sid` | Priority levels |

## Join Recipes
- **Issue → Worklogs**: `issue_id = f.issue_id`
- **User → Worklogs**: `user_id = f.user_id`
- **Calendar → Worklogs**: `day_id = f.calendar_id`

## Historization
All `_h` tables use `tstzrange` for SCD2 tracking.
Use views (without `_h`) for current-state queries.
