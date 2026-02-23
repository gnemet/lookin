# Johanna — AI Chat Assistant

## Overview
A **standalone Go application** that provides natural language querying over the DWH.
Users ask questions in Hungarian or English, and Johanna generates SQL, executes it, and returns human-readable answers.

## Pipeline
1. **User Question** → Natural language input
2. **RAG Search** → Finds relevant MCP context via pgvector embeddings
3. **Prompt Assembly** → Combines MCP context + user question
4. **LLM** → Sends to Gemini/Ollama for SQL generation
5. **SQL Execution** → Runs generated SQL against DWH (with RLS)
6. **NL Synthesis** → Converts results to human-readable answer

## Multi-Provider AI
Supports: **Gemini** | **Ollama** | **OpenAI** | **Claude** | **DeepSeek**

## Security
- **Metadata-Only Architecture** — zero business data sent to LLM
- Only table/column descriptions go to the AI model
- Results stay within the corporate network

## Technology
- Go backend (separate repo from Jiramntr)
- Browser UI (HTMX)
- RAG via pgvector/HNSW search
