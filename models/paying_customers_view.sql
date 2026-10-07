-- =============================================================================
-- analytics.paying_customers_v: THE SINGLE DOOR
-- -----------------------------------------------------------------------------
-- Implements metrics/paying_customer.yaml.
-- Dashboards, reports, tests and AI agents read paying customers ONLY from here.
-- Whoever doesn't come in through the single door gets the wrong answer.
--
--   base        -> billing.subscriptions (status + mrr > 0)
--   exceptions  -> governance.override_ledger (active rows only)
--   grain       -> one row per parent customer_id
--
-- Portable SQL (Snowflake / BigQuery / Postgres / Databricks).
-- =============================================================================

CREATE OR REPLACE VIEW analytics.paying_customers_v AS

WITH active_exceptions AS (            -- Only exceptions that are valid today
    SELECT *
    FROM governance.override_ledger
    WHERE metric = 'paying_customer'
      AND valid_from <= CURRENT_DATE
      AND (valid_until IS NULL OR valid_until >= CURRENT_DATE)
),

billing_base AS (                      -- YAML: base + require  (Gotcha G002)
    SELECT
        customer_id,
        SUM(mrr)  AS mrr
    FROM billing.subscriptions
    WHERE status IN ('active', 'past_due')
      AND mrr > 0
    GROUP BY customer_id
),

billing_kept AS (                      -- Drop excluded customers. Ledger wins over billing.
    SELECT b.customer_id, b.mrr, 'billing' AS source
    FROM billing_base b
    WHERE NOT EXISTS (
        SELECT 1 FROM active_exceptions e
        WHERE e.customer_id = b.customer_id
          AND e.exception_type IN ('exclude', 'count_as_paying')
    )
),

ledger_added AS (                      -- Add invoice deals billing never saw  (Gotcha G001)
    SELECT customer_id, mrr_override AS mrr, 'override_ledger' AS source
    FROM active_exceptions
    WHERE exception_type = 'count_as_paying'
),

all_paying AS (
    SELECT * FROM billing_kept
    UNION ALL
    SELECT * FROM ledger_added
),

rolled_up AS (                         -- Subsidiaries count once, under the parent  (Gotcha G004)
    SELECT
        COALESCE(m.parent_customer_id, p.customer_id) AS customer_id,
        p.customer_id                                  AS source_customer_id,
        p.mrr,
        p.source
    FROM all_paying p
    LEFT JOIN active_exceptions m
           ON m.customer_id = p.customer_id
          AND m.exception_type = 'merge_into_parent'
)

SELECT
    customer_id,
    SUM(mrr)                                                     AS mrr,
    SUM(mrr) * 12                                                AS arr,
    COUNT(*)                                                     AS source_accounts,
    MAX(CASE WHEN source = 'override_ledger' THEN 1 ELSE 0 END)  AS has_override,  -- lineage: was a human exception applied?
    CURRENT_DATE                                                 AS as_of_date
FROM rolled_up
GROUP BY customer_id;

-- Usage
--   SELECT COUNT(*) AS paying_customers, SUM(mrr) AS mrr
--   FROM analytics.paying_customers_v;
