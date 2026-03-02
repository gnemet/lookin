# 🔨 MCP-Forge

> *Config-driven RAG knowledge builder — Python CLI + Claude Agent Teacher*

## How It Works

1. **Config** → `config/jiramntr.yaml` defines project, sources, outputs
2. **Sources** → Adapters read from PostgreSQL catalogs, documents, Git, etc.
3. **Core** → Chunker splits content at `<!-- MANUAL -->` markers, Jinja2 templates render context
4. **Outputs** → 4 generators produce different MCP formats

## Output Formats

| Flag | Format | Target |
|------|--------|--------|
| `--full` | Single monolithic `.md` | Gemini (large context) |
| `--chain-gemini` | Topic-split `.md` files | Gemini chain |
| `--chain-ollama` | Chunked ≤5KB per file | Ollama (small context) |
| `--json` | Structured JSON catalog | ragdb import |

## Source Adapters

| Adapter | Status | Reads |
|---------|--------|-------|
| `postgres_dwh` | ✅ Active | JSON catalogs from `internal/catalog/` |
| `confluence` | 🔲 Stub | Confluence REST API |
| `documents` | 🔲 Stub | Local markdown/text files |
| `pptx_source` | 🔲 Stub | PowerPoint slides |
| `git_source` | 🔲 Stub | Git log + diff |
| `jira_comments` | 🔲 Stub | Jira issue comments |
| `bash_scripts` | 🔲 Stub | Shell scripts |

## Claude Agent — Self-Teaching System

Claude acts as the **teacher** for Ollama (the local student SLM):

| Mode | What it does |
|------|-------------|
| **Mode 1** — Teaching | Reads DWH schema files → creates `mcp.knowledge` rules |
| **Mode 2** — Feedback | Reads Ollama errors from `mcp.feedback` → fixes → knowledge |
| **Mode 3** — Q/A Gen | Generates `mcp.teaching` test pairs from rules |
| **Mode 4** — Validate | Replays Q/A through Ollama → scores in `mcp.teaching_run` |

Runs as a `systemd` timer on butalam, zero changes to aichat Go pipeline.

## Embedding Pipeline

```
mcp-forge outputs → embed/embedder.py → ragdb (rag.embeddings)
                         ↓
            Ollama 768d + Gemini 3072d vectors
```

Triggered after any knowledge change: `python3 embed/embedder.py --knowledge-only`

## Database Objects (ragdb)

| Table | Purpose |
|-------|---------|
| `mcp.knowledge` | Rules, examples, join recipes |
| `mcp.feedback` | User corrections (new → learned/wont_fix) |
| `mcp.audit_aisql` | SQL audit trail per request |
| `mcp.teaching` | Q/A test pairs + multi-turn chains |
| `mcp.teaching_run` | Pass/fail results per teaching pair |
| `rag.embeddings` | Vector store (per-collection) |

## Usage

```bash
cd ~/projects/mcp-forge
python3 mcp-forge.py --project jiramntr --all
python3 mcp-forge.py --list-projects
./scripts/claude-teacher.sh          # Run Claude Agent manually
```

