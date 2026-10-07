<div align="center">

# 🏰 The Human Moat Kit

### AI writes the code. You own the truth.

**Templates for turning business definitions into a Company Brain
that people *and* AI agents can trust.**

*From the talk "The Human Moat: Why Business Definitions Are Your Unfair Competitive Edge"
by Stav Grinboim at hayaData 2026*

</div>

---

## The problem in one question

> **"How many paying customers do we have?"**

| System | What it says about customer `ENT-0417` |
|---|---|
| CRM (Salesforce) | ✅ Closed Won, annual deal |
| Billing (Stripe) | ❌ Doesn't exist (pays by invoice) |
| Finance (side Google Sheet) | ✅ Paying |

Three systems, three answers. Your AI agent will pick one, write flawless SQL,
and be **confidently wrong**.

The AI didn't make a coding mistake. **It can't know what was never documented.**

## The philosophy

When AI writes the pipelines, the queries and the dashboards, the platform is no longer your edge.
Anyone can build one in a few weeks.

What AI **can't** do is decide what the business means:

- Does an invoice-only enterprise deal count as a paying customer?
- Is a subsidiary a separate logo?
- Who has the final say when Finance and Sales disagree?

Those decisions are **the Human Moat**. This kit is how you make them explicit,
version-controlled and machine-readable, so the AI does the documenting and you do the deciding.

```
   IDENTIFY  ──►  DEFINE  ──►  DOCUMENT  ──►  REFLECT
   └────── human ──────┘       └────── AI-assisted ─────┘
            ▲                                       │
            └──────────  "wait, something's off"  ◄─┘
```

## What's in the kit

| Step | File | What it is |
|---|---|---|
| **1. Define** | [`metrics/paying_customer.yaml`](metrics/paying_customer.yaml) | The metric as a set of business decisions: grain, base, requirements, exceptions, access, **owner** |
| **2. Document** | [`data/override_ledger.csv`](data/override_ledger.csv) · [`.sql`](data/override_ledger.sql) | The exceptions table. Every exception has a human signature |
| **3. Reflect** | [`docs/gotchas_book.md`](docs/gotchas_book.md) | Traps written as rules an AI agent reads *before* it writes SQL |
| **The single door** | [`models/paying_customers_view.sql`](models/paying_customers_view.sql) | One view that applies billing + exceptions. Everyone reads from here |
| Guardrails | [`tests/ledger_quality_checks.sql`](tests/ledger_quality_checks.sql) | Checks that catch unsigned, conflicting or stale exceptions |
| Agent wiring | [`prompts/agent_context.md`](prompts/agent_context.md) | Drop-in system prompt + loading pattern for your AI agent |

## How it fits together

```
        SOURCES                        THE SINGLE DOOR                CONSUMERS
 ┌──────────────────────┐
 │ billing.subscriptions│──┐
 └──────────────────────┘  │     ┌──────────────────────────┐     ┌─────────────────────┐
 ┌──────────────────────┐  ├────►│ analytics.               │────►│ Dashboards & reports│
 │ override_ledger      │──┘     │   paying_customers_v     │     └─────────────────────┘
 │ (synced from Sheets) │        └──────────────────────────┘     ┌─────────────────────┐
 └──────────────────────┘                     └──────────────────►│ AI agent            │
 ┌──────────────────────┐                                          │                     │
 │ metric YAML          │─────────── context ────────────────────►│ knows the rules     │
 │ gotchas book         │                                          │ before it queries   │
 └──────────────────────┘                                          └─────────────────────┘
```

> **The rule:** whoever doesn't come in through the single door is wrong.
> We learned this when an automated test queried the raw billing table, and every
> customer in the exceptions table vanished again.

## Quickstart (one afternoon)

1. **Pick one metric that has burned you.** Start with the one where two teams give different numbers.
2. **Copy `metrics/paying_customer.yaml`** and fill it in *with the business owner in the room*.
   The `owner` field is not optional.
3. **Find the side spreadsheet.** Someone in Finance, Sales Ops or CS already tracks the exceptions.
   Don't replace it. Promote it: give it the columns in `data/override_ledger.csv` and
   sync it to your warehouse (Fivetran / Airbyte / dlt / native Sheets connector).
4. **Create the single door.** Adapt `models/paying_customers_view.sql` to your tables.
   Repoint every dashboard to it.
5. **Write your first two gotchas** in `docs/gotchas_book.md`. Each one is a mistake that already happened.
6. **Wire the agent.** Add `prompts/agent_context.md` to its system prompt and grant its
   database role `SELECT` on the view only.
7. **Run `tests/ledger_quality_checks.sql`** after every sync. Zero rows = healthy.

Then repeat for the next metric. It's a loop, not a project.

## Using it with your AI agent

The kit is tool-agnostic. It works the same with an in-house Slack bot, Snowflake Cortex Analyst,
Databricks Genie, dbt Semantic Layer + MCP, or any LLM with a SQL tool.

| Layer | Gives the agent | Without it the agent... |
|---|---|---|
| Metric YAML | *What* to count and *where* to read it | ...picks whichever table looks right |
| Gotchas book | *Which traps* to check before querying | ...repeats last quarter's mistake |
| Single-door view | *One* governed object to query | ...bypasses your exceptions |
| `owner` field | *Who* to escalate to | ...can't tell anyone who decides |

## FAQ

**Isn't a Google Sheet a fragile source of truth?**
The sheet is the *input UI*, not the source of truth. The warehouse table is. Quality checks
gate every sync, and every row needs an approver and an expiry. If your team prefers, replace the
sheet with a form, a ticket workflow or a PR. The contract (columns + signature) stays the same.

**Doesn't the ledger grow forever?**
It shouldn't. Every exception is a bug report against a source system. Use `valid_until`, and
check #6 in the tests flags exceptions the source has caught up on. A healthy ledger has tens of
rows, not thousands. If it grows, fix the upstream process.

**Why not just a semantic layer (dbt / Cube / LookML)?**
Use one! This kit sits *on top* of it. A semantic layer describes **what's in the data**.
The kit records **what the business decided**: owners, exceptions and traps.

**Is it safe to give an AI agent this context?**
The YAML and gotchas contain definitions, not data. The ledger is read only through the view,
under a role scoped to it. Keep customer names out of `notes` if the agent can see the view.

## Contributing

Found a gotcha that's universal (timezones, refunds, multi-currency, test accounts...)?
Open a PR to `docs/gotchas_book.md`. The best moats are built from shared scars.

## License

MIT. Copy it, fork it, make it yours.

---

<div align="center">

**Every line of code is a decision someone had to make.**
*Stop spending time on syntax. Start building your moat.*

</div>
