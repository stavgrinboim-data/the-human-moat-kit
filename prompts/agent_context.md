# Agent context: how to wire the kit into your AI data agent

Drop this block into your agent's system prompt (or retrieval step) **before** it writes SQL.
It works with any agent: an in-house Slack bot, Snowflake Cortex, Databricks Genie,
a dbt/MCP setup, or a plain LLM with a SQL tool.

```text
You answer business questions using the company's governed metrics.

Before writing any SQL:
1. Find the metric YAML in /metrics that matches the question.
2. Read the gotchas listed in that YAML from docs/gotchas_book.md and follow each "Agent rule".
3. Query ONLY the object in `access.read_from`. Never query tables in `access.never_read_directly`.
4. If no certified metric matches, say so and name the closest one. Do not invent a definition.

In every answer:
- State which metric definition and version you used (e.g. paying_customer v1.2.0).
- If any row has has_override = 1, say how many results include a human-approved exception.
- Name the metric owner so people know who to ask.
```

## Loading pattern

| Kit file | Loaded how | When |
|---|---|---|
| `metrics/*.yaml` | Retrieved by metric name / synonyms | Per question |
| `docs/gotchas_book.md` | Always in context (keep it short!) | Every question |
| `models/*_view.sql` | Granted as the only readable object | Permission layer |
| `data/override_ledger` | Read *through* the view, never directly | Never by the agent |

**Why permissions matter more than prompts:** a prompt says "don't read the raw table";
a role that *can't* read the raw table guarantees it. Give the agent's database role
`SELECT` on the views only.
