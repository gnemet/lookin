# 🤖 Johanna — AI Chat Assistant

> *Ask questions in Hungarian or English — get SQL-powered answers*

**Version**: 0.7.2 | **Port**: 8082 | **Engine**: antigravity

## 💡 What is it?
Johanna lets users query the Data Warehouse using **natural language**.
No SQL knowledge required — just ask:

*"Hány órát logolt a csapatom januárban?"*
*"Which projects had the most SLA breaches?"*


## 🔄 Pipeline
| Step | What happens |
|---|---|
| 1️⃣ | 🗣️ User asks a question (HU/EN) |
| 2️⃣ | 🔍 RAG searches for relevant DWH context |
| 3️⃣ | 📝 Prompt assembled with MCP + question |
| 4️⃣ | 🧠 LLM generates SQL |
| 5️⃣ | ⚡ SQL executed against DWH (with RLS!) |
| 6️⃣ | 💬 Result synthesized into natural language |


## 🌐 Multi-Provider AI
| Provider | Status |
|---|---|
| ✨ Gemini | Primary |
| 🦙 Ollama | Local/offline |
| 🔵 OpenAI | Supported |
| 🟣 Claude | Supported |
| 🔶 DeepSeek | Supported |


## 🔒 Security Principle
> **Metadata-Only Architecture** — zero business data sent to LLM.
> Only table names and column descriptions leave the network.
> All query results stay within the corporate environment.


## 🛠️ Technology
- Go backend (separate repo)
- Browser UI via HTMX
- RAG via pgvector HNSW search
- Author: Gabor Nemet
