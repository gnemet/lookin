# ⚡ AI-Chat Module

> *Shared NL→SQL→Execute→NL pipeline — `github.com/gnemet/aichat`*

## Pipeline Stages

| Stage | Input | Output | LLM Role |
|-------|-------|--------|----------|
| **Stage 1** | User question + RAG context + MCP | SQL query | SQL generation |
| **Stage 2** | SQL query | Result rows | PostgreSQL execution (with RLS) |
| **Stage 3** | Results + question | Natural language | Conversational synthesis |
| **Auto-Repair** | Failed SQL + PG error | Fixed SQL | Error correction (teacher) |

## Interfaces

```go
AIClient.GenerateContent(ctx, prompt, history, systemPrompt, provider, model)
RAGProvider.BuildContext(ctx, question) → (context, error)
SQLExecutor.Execute(user, query, rls) → (rows, cols, error)
```

## Adapters

Both **jiramntr** and **johanna** implement the same 3 interfaces:

| Adapter | Jiramntr | Johanna |
|---------|----------|---------|
| AI Client | `jiramntrAIClient` | `johannaAIClient` |
| RAG | `jiramntrRAGProvider` | `johannaRAGProvider` |
| SQL | `jiramntrSQLExecutor` | `johannaSQLExecutor` |

## Personas

Loaded from embedded `.md` files via `embed.FS`:
- **sql** — SQL generation system prompt
- **chat** — Conversational synthesis persona
- **direct** — Direct NL answers (no SQL)
