# 🤖 Johanna — AI Chat Assistant

> *Ask questions in Hungarian or English — get SQL-powered answers*

**Version**: 0.7.4 | **Port**: 8082 | **Engine**: antigravity

## 💡 What is it?
Johanna lets users query the Data Warehouse using **natural language**.
No SQL knowledge required — just ask:

*"Hány órát logolt a csapatom januárban?"*
*"Which projects had the most SLA breaches?"*


## 🔄 NL → SQL → NL Pipeline
| Step | What happens |
|---|---|
| 1️⃣ | 🗣️ User asks a question (HU/EN) |
| 2️⃣ | 🔍 RAG retrieves DWH schema context from ragdb |
| 3️⃣ | 🚦 Relevancy Gate decides: SQL path or direct answer |
| 4️⃣ | 🧠 LLM generates PostgreSQL with schema context |
| 5️⃣ | 🔧 Auto-Repair — failed SQL is fixed by a repair LLM |
| 6️⃣ | ⚡ SQL executed against DWH (with RLS!) |
| 7️⃣ | 💬 Result synthesized into natural-language prose |
| 8️⃣ | 🔁 Follow-up Memory — reuses RAG context for multi-turn |


## 🧠 RAG Pipeline
- **Cross-collection merge** — queries all collections (DWH, HR, Git), picks top results by score
- **DB-driven model routing** — each collection can override AI provider/model per stage
- **Per-collection thresholds** — stored in `rag.collections`, tunable via SQL
- **pgvector HNSW** — embeddings in ragdb, managed by mcp-forge


## 🎓 Self-Study
Background worker that learns from successful SQL queries:
1. Audit logs → LLM analysis → pattern extraction
2. Promoted patterns → `mcp.knowledge` → RAG re-embedding
3. User feedback corrections feed the same loop


## 📡 Pipeline Activity
Real-time WebSocket tracking of each pipeline stage:
- Stage indicators: RAG → SQL → Repair → Execute → Narrate
- Cancel running pipelines from the sidebar
- All events structured-logged via slog


## 🌐 Multi-Provider AI
| Provider | Type | Status |
|---|---|---|
| ✨ Gemini | Cloud (Paid) | Primary |
| 🦙 Ollama | Local GPU | Alternative |
| 🔶 Mock | Testing | Built-in |

Collection-based routing: each RAG collection can specify its own provider/model per stage (SQL, Repair, Chat).


## 🔗 JIRA Integration
- Personal Access Token for direct issue read/write
- Entity lookup (users, projects, issues)
- Token entry on login page (optional)


## 🔒 Security Principle
> **Metadata-Only Architecture** — zero business data sent to LLM.
> Only table names and column descriptions leave the network.
> All query results stay within the corporate environment.


## 🛠️ Technology
| Layer | Technology |
|---|---|
| Backend | Go 1.25 (Standard Library + aichat module) |
| Frontend | HTML5, HTMX, jQuery, Vanilla CSS |
| Database | PostgreSQL 18 + pgvector (ragdb) |
| Auth | LDAP + Kerberos SSO (SPNEGO) |
| Real-time | WebSocket (pipeline activity) |
| RAG | pgvector embeddings, cross-collection merge |

Author: Gabor Nemet
