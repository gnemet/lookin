#!/usr/bin/env python3
"""
LookIn Doc Generator — reads from source projects → styled docs/*.md

Usage:
    python3 generate_docs.py          # generate all docs
    python3 generate_docs.py --list   # list what would be generated

Style is controlled by templates in the GENERATORS section.
When source changes, re-run this script to regenerate.
"""

import json
import os
import sys
from pathlib import Path

LOOKIN_DIR = Path(__file__).parent.resolve()
DOCS_DIR = LOOKIN_DIR / "docs"
JIRAMNTR_DIR = LOOKIN_DIR.parent / "jiramntr"
JOHANNA_DIR = LOOKIN_DIR.parent / "johanna"
NL = "\n"

# ── Style helpers ──────────────────────────────────────────────

def md_table(headers, rows):
    lines = ["| " + " | ".join(headers) + " |"]
    lines.append("|" + "|".join("---" for _ in headers) + "|")
    for row in rows:
        lines.append("| " + " | ".join(str(c) for c in row) + " |")
    return NL.join(lines)

def md_section(emoji, title, lines):
    body = NL.join(lines) if isinstance(lines, list) else lines
    return f"{NL}## {emoji} {title}{NL}{body}{NL}"

def md_steps(steps):
    rows = []
    for i, (emoji, text) in enumerate(steps, 1):
        rows.append([f"{i}\ufe0f\u20e3", f"{emoji} {text}"])
    return md_table(["Step", "What happens"], rows)


# ── Source readers ─────────────────────────────────────────────

def read_catalogs():
    catalogs = {}
    for f in sorted((LOOKIN_DIR / "catalogs").glob("*.json")):
        try:
            catalogs[f.stem] = json.loads(f.read_text())
        except Exception:
            pass
    return catalogs

def read_johanna_config():
    cfg_path = JOHANNA_DIR / "config.yaml"
    if not cfg_path.exists():
        return {}
    # Simple key: value parser (avoid yaml dependency)
    cfg = {}
    for line in cfg_path.read_text().splitlines():
        line = line.strip()
        if ":" in line and not line.startswith("#"):
            k, _, v = line.partition(":")
            cfg[k.strip()] = v.strip().strip('"').strip("'")
    return cfg

def count_files(directory, pattern):
    d = Path(directory)
    return len(list(d.glob(pattern))) if d.exists() else 0


# ── Doc generators ─────────────────────────────────────────────

def gen_architecture():
    catalogs = read_catalogs()
    rows = []
    for name, data in sorted(catalogs.items()):
        if name.startswith("fact_"):
            rows.append([f"`{name}`", "\u23f1\ufe0f Fact", data.get("description", "")])
        elif name.startswith("dim_"):
            rows.append([f"`{name}`", "\U0001f4d0 Dim", data.get("description", "")])

    if not rows:
        rows = [
            ["`fact_daily_worklogs_h`", "\u23f1\ufe0f Fact", "Hours logged per person/issue/day"],
            ["`fact_sla_events`", "\U0001f6a8 Fact", "SLA breaches and response times"],
            ["`dim_issue_h`", "\U0001f4dd Dim", "Jira issues (status, priority, assignee)"],
            ["`dim_user_h`", "\U0001f464 Dim", "Users from LDAP (hierarchy, manager)"],
            ["`dim_project_h`", "\U0001f4c1 Dim", "Projects with leads"],
            ["`dim_calendar`", "\U0001f4c5 Dim", "Date dimension (YYYYMMDD)"],
        ]

    parts = [
        "# \U0001f4ca Data Warehouse (DWH)",
        "",
        "> *Consolidated analytics layer \u2014 single source of truth*",
        md_section("\U0001f3d7\ufe0f", "Architecture", [
            "**PostgreSQL 16** Star Schema with full SCD2 historization.",
            "All business data flows through here \u2014 Jira, LDAP, and Leave System consolidated into one analytics-ready model.",
        ]),
        md_section("\U0001f510", "Security", [
            "- **Row-Level Security (RLS)** \u2014 users only see their own hierarchy",
            "- Session variable `jiramntr.login_user` drives visibility",
            "- Even SQL Lab queries are filtered by RLS",
        ]),
        md_section("\U0001f4e6", "Schemas", md_table(
            ["Schema", "Purpose", "Access"],
            [["`dwh`", "\u2b50 Star Schema (facts + dims)", "Primary"],
             ["`meta`", "\U0001f9e0 AI metadata, embeddings", "Auxiliary"],
             ["`ext`", "\U0001f4e5 External imports staging", "Internal only"],
             ["`oltp`", "\U0001f50c Oracle FDW bridge", "\u26d4 Forbidden"]]
        )),
        md_section("\U0001f4cb", "Key Tables", md_table(["Table", "Type", "Description"], rows)),
        md_section("\U0001f504", "Historization", [
            "All `_h` tables use `tstzrange` for Level 2 SCD tracking.",
            "Use **views** (without `_h` suffix) for current-state queries \u2014 they auto-filter for active records.",
        ]),
        md_section("\u2699\ufe0f", "ETL", [
            "Yearly partitioned orchestrator runs nightly on butalam,",
            "with pre-flight checks and HWM incremental loading.",
        ]),
    ]
    return NL.join(parts)


def gen_johanna():
    cfg = read_johanna_config()
    version = cfg.get("version", "0.x")
    port = cfg.get("port", "8082")
    engine = cfg.get("engine", "antigravity")
    author = cfg.get("author", "")

    parts = [
        f"# \U0001f916 Johanna \u2014 AI Chat Assistant",
        "",
        "> *Ask questions in Hungarian or English \u2014 get SQL-powered answers*",
        "",
        f"**Version**: {version} | **Port**: {port} | **Engine**: {engine}",
        md_section("\U0001f4a1", "What is it?", [
            "Johanna lets users query the Data Warehouse using **natural language**.",
            "No SQL knowledge required \u2014 just ask:",
            "",
            '*"H\u00e1ny \u00f3r\u00e1t logolt a csapatom janu\u00e1rban?"*',
            '*"Which projects had the most SLA breaches?"*',
        ]),
        md_section("\U0001f504", "Pipeline", md_steps([
            ("\U0001f5e3\ufe0f", "User asks a question (HU/EN)"),
            ("\U0001f50d", "RAG searches for relevant DWH context"),
            ("\U0001f4dd", "Prompt assembled with MCP + question"),
            ("\U0001f9e0", "LLM generates SQL"),
            ("\u26a1", "SQL executed against DWH (with RLS!)"),
            ("\U0001f4ac", "Result synthesized into natural language"),
        ])),
        md_section("\U0001f310", "Multi-Provider AI", md_table(
            ["Provider", "Status"],
            [["\u2728 Gemini", "Primary"],
             ["\U0001f999 Ollama", "Local/offline"],
             ["\U0001f535 OpenAI", "Supported"],
             ["\U0001f7e3 Claude", "Supported"],
             ["\U0001f536 DeepSeek", "Supported"]]
        )),
        md_section("\U0001f512", "Security Principle", [
            "> **Metadata-Only Architecture** \u2014 zero business data sent to LLM.",
            "> Only table names and column descriptions leave the network.",
            "> All query results stay within the corporate environment.",
        ]),
        md_section("\U0001f6e0\ufe0f", "Technology", [
            "- Go backend (separate repo)",
            "- Browser UI via HTMX",
            "- RAG via pgvector HNSW search",
            f"- Author: {author}" if author else "",
        ]),
    ]
    return NL.join(parts)


def gen_ingestion():
    parts = [
        "# \U0001f4e5 Data Ingestion Pipeline",
        "",
        "> *Three source systems \u2192 one Star Schema*",
        md_section("\U0001f310", "Data Sources", md_table(
            ["Source", "Protocol", "What we get"],
            [["\U0001f7e0 **Oracle DB** (Jira)", "`oracle_fdw`", "Issues, worklogs, custom fields, links"],
             ["\U0001f535 **Active Directory**", "LDAP sync", "Users, org hierarchy, photos, departments"],
             ["\U0001f7e2 **TER** (Leave System)", "REST API", "Absences, work schedules"],
             ["\U0001f7e1 **SharePoint**", "`sp-download` (Go)", "Excel exports *(planned)*"],
             ["\u26aa **Google Drive**", "CSV loader", "CSV exports, backups"]]
        )),
        md_section("\U0001f50c", "How Data Flows", [
            "```",
            "Oracle DB \u2500\u2500\u2192 oracle_fdw \u2500\u2500\u2192 ext schema \u2500\u2500\u2510",
            "LDAP      \u2500\u2500\u2192 ext.ldap_import \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2192\u251c\u2500\u2500\u2192 ETL \u2500\u2500\u2192 dwh schema",
            "TER API   \u2500\u2500\u2192 ext.ter_data \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2192\u2518",
            "```",
        ]),
        md_section("\u2699\ufe0f", "ETL Orchestrator", [
            "- \U0001f4c6 **Yearly partitioned** \u2014 processes one year at a time",
            "- \U0001f50d **Pre-flight TCP checks** \u2014 validates source availability before running",
            "- \U0001f4c8 **HWM pattern** \u2014 High Water Mark for incremental loading",
            "- \U0001f4ca **Observability** \u2014 logs timing, row counts, errors to `meta.etl_log`",
            "- \U0001f554 **Schedule** \u2014 nightly cron on butalam server",
        ]),
    ]
    return NL.join(parts)


def gen_star_schema():
    catalogs = read_catalogs()

    fact_parts = []
    for name in ["fact_daily_worklogs_h", "fact_sla_events"]:
        if name in catalogs:
            data = catalogs[name]
            cols = data.get("columns", {})
            rows = [[f"`{c}`", v.get("type", ""), v.get("desc", "")] for c, v in cols.items()]
            emoji = "\u23f1\ufe0f" if "worklog" in name else "\U0001f6a8"
            fact_parts.append(f"### {emoji} {name}")
            fact_parts.append(data.get("description", ""))
            fact_parts.append(md_table(["Column", "Type", "Purpose"], rows))
            fact_parts.append("")

    dim_rows = []
    for name in ["dim_user_h", "dim_issue_h", "dim_project_h", "dim_calendar"]:
        if name in catalogs:
            data = catalogs[name]
            keys = list(data.get("columns", {}).keys())
            dim_rows.append([f"`{name}`", f"`{keys[0]}`" if keys else "", data.get("description", "")])

    parts = [
        "# \u2b50 Star Schema (DWH)",
        "",
        "> *Kimball-style design with Level 2 SCD historization*",
        md_section("\U0001f4ca", "Fact Tables",
                   NL.join(fact_parts) if fact_parts else "See catalog JSONs for details."),
        md_section("\U0001f4d0", "Dimension Tables",
                   md_table(["Dim", "Key", "Description"], dim_rows) if dim_rows else "See catalog JSONs."),
        md_section("\U0001f517", "Join Recipes", [
            "- **Issue \u2192 Worklogs**: `i.issue_id = f.issue_id`",
            "- **User \u2192 Worklogs**: `u.user_id = f.user_id`",
            "- **Calendar \u2192 Worklogs**: `c.day_id = f.calendar_id`",
            "- **Project \u2192 Issue**: `i.issue_key LIKE p.project_key || '-%'`",
        ]),
        md_section("\U0001f504", "Views", [
            "Use `dwh.dim_issue` (no `_h`) for current state \u2014 auto-filters `upper_inf(valid)`.",
        ]),
    ]
    return NL.join(parts)


def gen_mcp_detail():
    n_catalogs = count_files(JIRAMNTR_DIR / "internal/catalog", "*.json") or 50
    n_chains = count_files(JIRAMNTR_DIR / "dist/butalam/ai/mcp/templates", "*.md") or 12

    parts = [
        "# \U0001f9e0 MCP Catalog Pipeline",
        "",
        "> *Metadata-Only Protocol \u2014 teach AI about your data without exposing it*",
        md_section("\U0001f4a1", "What is MCP?", [
            "The **Model Context Protocol** provides AI models with structured knowledge about the DWH schema,",
            "join patterns, and business rules \u2014 while keeping all actual data safely on-premise.",
        ]),
        md_section("\U0001f4e6", "Components", md_table(
            ["Component", "Count", "Purpose"],
            [["\U0001f4cb JSON Catalogs", f"{n_catalogs} files", "Column definitions for Datagrid UI"],
             ["\U0001f517 Chain MCPs", f"{n_chains} .md", "Domain-specific knowledge docs"],
             ["\U0001f4dd Master Template", "1 file", "`dwh_mcp_template.md` \u2014 architect context"]]
        )),
        md_section("\U0001f504", "Pipeline", md_steps([
            ("\U0001f3ed", f"MCP Generator auto-generates 750+ column descriptions from DB"),
            ("\U0001f517", f"Chain MCPs \u2014 {n_chains} domain-specific markdown files"),
            ("\U0001f9ec", "Gemini Embedding \u2014 `text-embedding-004` \u2192 768-dim vectors"),
            ("\U0001f4e6", "pgvector Store \u2014 `meta.mcp_embeddings` with HNSW index"),
            ("\U0001f50d", "RAG Search \u2014 cosine similarity at query time"),
        ])),
        md_section("\U0001f512", "Key Principle", [
            "> **Metadata-Only**: Only table names, column descriptions, and join recipes go to the LLM.",
            "> Zero business data ever leaves the corporate network.",
        ]),
    ]
    return NL.join(parts)


def gen_application():
    parts = [
        "# \U0001f5a5\ufe0f Application Stack",
        "",
        "> *Go backend + HTMX frontend \u2014 premium dark theme*",
        md_section("\U0001f4e1", "REST API", md_table(
            ["Endpoint", "Purpose"],
            [["`/api/chat`", "\U0001f916 AI conversational SQL (Johanna)"],
             ["`/api/bi`", "\U0001f4ca BI Query Library \u2014 run saved queries"],
             ["`/api/kpi`", "\U0001f4c8 KPI Dashboard \u2014 YAML-driven scoring"],
             ["`/api/employee`", "\U0001f464 Employee directory + hierarchy"],
             ["`/api/oncall`", "\U0001f4de On-call schedules"]]
        )),
        md_section("\U0001f3a8", "Web UI", [
            "- **HTMX** \u2014 interactive updates without SPA overhead",
            "- **Vanilla CSS** \u2014 premium dark theme, fully responsive",
            "- **Datagrid Library v1.2** \u2014 sortable, filterable tables with LOV params",
        ]),
        md_section("\U0001f512", "Middleware", md_table(
            ["Layer", "Purpose"],
            [["\U0001f6e1\ufe0f RLS", "Row-Level Security per user hierarchy"],
             ["\U0001f511 Auth", "LDAP/cookie-based session management"],
             ["\U0001f4dd Audit", "Request logging to `meta.etl_log`"]]
        )),
        md_section("\U0001f4c8", "KPI Dashboard", [
            "YAML-driven KPI definitions with:",
            "- Configurable rating scales (1-5 stars)",
            "- Threshold-based color coding",
            "- Multilingual labels (EN/HU)",
        ]),
    ]
    return NL.join(parts)


def gen_ai_pipeline():
    parts = [
        "# \U0001f9ea AI Self-Teaching Pipeline",
        "",
        "> *The AI gets smarter with every question*",
        md_section("\U0001f504", "The Loop", md_steps([
            ("\U0001f5e3\ufe0f", "User asks a question"),
            ("\U0001f50d", "RAG retrieves relevant MCP context"),
            ("\U0001f9e0", "LLM generates SQL"),
            ("\u26a1", "SQL executes against DWH"),
            ("\U0001f44d\U0001f44e", "User rates the result"),
            ("\U0001f4da", "Self-Study analyzes failures"),
            ("\U0001f504", "Good patterns fed back into chain MCPs"),
        ])),
        md_section("\U0001f310", "Multi-Provider AI", md_table(
            ["Provider", "Use case"],
            [["\u2728 Gemini", "Primary \u2014 best accuracy"],
             ["\U0001f999 Ollama", "Offline/air-gapped environments"],
             ["\U0001f535 OpenAI", "Alternative cloud option"],
             ["\U0001f7e3 Claude", "Alternative cloud option"],
             ["\U0001f536 DeepSeek", "Cost-effective alternative"]]
        )),
    ]
    return NL.join(parts)


def gen_rag_detail():
    parts = [
        "# \U0001f50d RAG Pipeline",
        "",
        "> *Retrieval-Augmented Generation \u2014 the AI's knowledge engine*",
        md_section("\U0001f504", "How It Works", md_steps([
            ("\U0001f4dd", "MCP `.md` files split into chunks"),
            ("\U0001f9ec", "Each chunk embedded via Gemini `text-embedding-004`"),
            ("\U0001f4e6", "Vectors stored in `meta.mcp_embeddings` (HNSW)"),
            ("\U0001f5e3\ufe0f", "User question embedded as vector"),
            ("\U0001f50d", "Cosine similarity finds top-K chunks"),
            ("\U0001f4cb", "Relevant chunks injected into LLM prompt"),
        ])),
        md_section("\U0001f500", "Two Modes", md_table(
            ["Mode", "When", "How"],
            [["\U0001f3af **pgvector HNSW**", "Default", "Semantic similarity search"],
             ["\U0001f4c4 **Direct MCP**", "Fallback", "Full template if RAG fails"]]
        )),
        md_section("\U0001f9ec", "Embedding Model", [
            "- **Provider**: Google Gemini",
            "- **Model**: `text-embedding-004`",
            "- **Dimensions**: 768",
            "- **Index**: HNSW (Hierarchical Navigable Small World)",
        ]),
        md_section("\U0001f4da", "Knowledge Sources", md_table(
            ["Source", "Content"],
            [["\U0001f517 Chain MCPs", "Domain-specific DWH knowledge"],
             ["\U0001f4ca Schema descriptions", "Table/column metadata"],
             ["\U0001f465 LDAP hierarchy", "User org structure"],
             ["\U0001f4cb BI catalog", "Saved query definitions"]]
        )),
    ]
    return NL.join(parts)


# ── Main ───────────────────────────────────────────────────────

GENERATORS = {
    "architecture": gen_architecture,
    "johanna": gen_johanna,
    "ingestion": gen_ingestion,
    "star_schema": gen_star_schema,
    "mcp_detail": gen_mcp_detail,
    "application": gen_application,
    "ai_pipeline": gen_ai_pipeline,
    "rag_detail": gen_rag_detail,
}

def main():
    if "--list" in sys.argv:
        print("Would generate:")
        for name in GENERATORS:
            print(f"  docs/{name}.md")
        return

    DOCS_DIR.mkdir(exist_ok=True)
    print(f"Generating {len(GENERATORS)} docs in {DOCS_DIR}/")

    for name, gen_fn in GENERATORS.items():
        content = gen_fn()
        out = DOCS_DIR / f"{name}.md"
        out.write_text(content.strip() + NL)
        lines = content.strip().count(NL) + 1
        print(f"  {name}.md ({lines} lines)")

    print(f"Done! {len(GENERATORS)} docs generated.")
    print("Style: edit GENERATORS in generate_docs.py, then re-run.")

if __name__ == "__main__":
    main()
