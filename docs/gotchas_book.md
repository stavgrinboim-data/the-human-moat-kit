# Gotchas Book

> **For AI agents:** Load this file into context **before** writing any query.
> Each gotcha is a trap that has already caught us once. Follow the **Agent rule** literally.
> If a question touches a metric listed under *Applies to*, the rule is mandatory, not advice.
>
> **For humans:** Every gotcha here is a scar. Add one every time you say
> *"wait, something's off here"*, then link it from the metric YAML.

---

## Format

Every entry has the same five fields, so agents can parse it reliably:

| Field | Meaning |
|---|---|
| **Trap** | What looks true in the data but isn't |
| **Why** | The business reality behind it |
| **Agent rule** | One imperative instruction an agent can follow |
| **Applies to** | Metrics / tables affected |
| **Owner** | Who confirmed this is how the business works |

---

## G001: Invoice deals don't exist in billing

- **Trap:** A customer is `Closed Won` in the CRM but has no subscription in billing (Stripe). It looks like a non-paying customer, or a data bug.
- **Why:** Enterprise customers often pay annually by invoice and bank transfer. Finance tracks them outside the billing system.
- **Agent rule:** For every `Closed Won` CRM account with no active billing subscription, **check `governance.override_ledger`** for `exception_type = 'count_as_paying'` before concluding anything. Never answer a paying-customer question from billing alone.
- **Applies to:** `paying_customer`, `mrr`, `arr`
- **Owner:** VP Finance

## G002: "Paying" in billing doesn't always mean paying

- **Trap:** Billing shows `status = 'active'` for accounts that pay nothing: free plans, 100% coupons, trials, or customers who downgraded but whose cancellation never synced.
- **Why:** Billing status describes the *subscription object*, not the *commercial relationship*.
- **Agent rule:** Count a billing row as paying **only if `mrr > 0`**, and **drop any customer** with an active `exclude` row in the override ledger.
- **Applies to:** `paying_customer`, `mrr`, `logo_churn`
- **Owner:** VP Finance

## G003: Never bypass the single door

- **Trap:** Querying `billing.subscriptions` directly gives a clean, plausible number. It is wrong by exactly the number of rows in the override ledger.
- **Why:** Exceptions are applied in **one** place: `analytics.paying_customers_v`. Anything that reads around it silently loses them. (Learned the hard way: an automated test hit the raw table and every ledger customer disappeared.)
- **Agent rule:** For paying customers, MRR or ARR, **read only from `analytics.paying_customers_v`**. If you think you need a raw table, say so and explain why instead of querying it.
- **Applies to:** every metric whose YAML has an `access.read_from`
- **Owner:** Head of Data

## G004: Subsidiaries are not separate customers

- **Trap:** Two accounts with different names, domains or workspaces look like two customers.
- **Why:** A group contract can cover a parent and its subsidiaries. Commercially it is **one** logo.
- **Agent rule:** Count customers at the **parent** level. Apply `merge_into_parent` rows from the override ledger. Never count distinct raw account IDs as "customers".
- **Applies to:** `paying_customer`, `logo_churn`, `net_revenue_retention`
- **Owner:** VP Finance

---

## Template: add your own

```markdown
## G00X: <short trap name>

- **Trap:**
- **Why:**
- **Agent rule:** <one imperative sentence>
- **Applies to:**
- **Owner:**
```

**Rule of thumb:** if the agent rule needs more than two sentences, the definition
belongs in the metric YAML or the view. Fix it there and keep the gotcha short.
