# Security Architecture

## Three-Layer Access Control

The Jira Monitor implements a layered security model that controls access at multiple levels.

### Layer 1: Authentication
- HTTP cookie-based (`auth_user` cookie) via LDAP authentication
- All routes (except `/login`) require authentication

### Layer 2: Folder ACL
Controlled by `.folder.yaml` in each BI query/KPI folder:

| Field | Description |
|:---|:---|
| `whitelist` | Only listed users (+ admin) may access |
| `blacklist` | Listed users are denied even if whitelisted |
| `hierarchy` | `[up, down]` — org tree resolution via `ltree_path` in `dim_user_h` |

Uses `IsUserAllowed()` — unified across sidebar, BI queries, KPI dashboards, and routes.

### Layer 3: RLS Tokens
For cross-department data access (e.g. fekegy accessing IIER area data):

- Reports declare `rls_scope: area:IIER` in YAML frontmatter
- Admin grants tokens via **Settings → RLS Tokens** page
- Tokens are validated against SHA256 hash of the SQL block
- **Auto-rehash**: On server startup, hashes are refreshed — SQL edits don't break tokens
- Admin users (`nemetg`) bypass all RLS checks

### Logging
All Go applications use structured logging via `log/slog` with key-value pairs.
