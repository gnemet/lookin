# 🔨 MCP-Forge

> *Config-driven RAG knowledge builder — Python CLI*

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

## Usage

```bash
cd ~/projects/mcp-forge
python3 mcp-forge.py --project jiramntr --all
python3 mcp-forge.py --list-projects
```
