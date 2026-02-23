# AI Self-Teaching Pipeline

## Overview
A **self-learning loop** where the AI improves its SQL generation accuracy over time based on user feedback.

## Pipeline Steps
1. **User asks question** → NL input in HU/EN
2. **RAG retrieval** → Relevant MCP context from pgvector
3. **LLM generates SQL** → Via Gemini/Ollama
4. **SQL executes** → Against DWH with RLS
5. **User rates result** → 👍/👎 feedback
6. **Self-Study** → Failed queries are analyzed and stored
7. **MCP Update** → Good patterns are fed back into chain MCPs

## Feedback Loop
```
User Question → SQL → Execute → Result
                                    ↓
                              User Feedback
                                    ↓
                        Self-Study Analysis
                                    ↓
                          MCP Knowledge Update
```

## Multi-Provider
Supports switching between AI providers:
**Gemini** | **Ollama** | **OpenAI** | **Claude** | **DeepSeek**
