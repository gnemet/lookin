# 🧪 AI Self-Teaching Pipeline

> *The AI gets smarter with every question*

## 💡 How it works
A **self-learning loop** where Johanna improves SQL generation accuracy based on user feedback and pattern analysis.

## 🔄 The Loop

| Step | What happens |
|---|---|
| 1️⃣ | 🗣️ User asks a question |
| 2️⃣ | 🔍 RAG retrieves relevant MCP context |
| 3️⃣ | 🧠 LLM generates SQL |
| 4️⃣ | ⚡ SQL executes against DWH |
| 5️⃣ | 👍👎 User rates the result |
| 6️⃣ | 📚 Self-Study analyzes failures |
| 7️⃣ | 🔄 Good patterns fed back into chain MCPs |

## 📊 Feedback Loop
```
Question → SQL → Execute → Result
                               ↓
                         User Feedback
                               ↓
                     Self-Study Analysis
                               ↓
                       MCP Knowledge Update
                               ↓
                      Better SQL Next Time ✨
```

## 🌐 Multi-Provider AI
| Provider | Use case |
|---|---|
| ✨ Gemini | Primary — best accuracy |
| 🦙 Ollama | Offline/air-gapped environments |
| 🔵 OpenAI | Alternative cloud option |
| 🟣 Claude | Alternative cloud option |
| 🔶 DeepSeek | Cost-effective alternative |
