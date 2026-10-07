-- =============================================================================
-- override_ledger: the exceptions table
-- -----------------------------------------------------------------------------
-- Origin: the side spreadsheet Finance already kept. We didn't replace it,
-- we promoted it. Owners keep editing a Google Sheet; a sync (Fivetran,
-- Airbyte, dlt, a native connector or a scheduled script) lands it here as
-- an official warehouse table.
--
-- Golden rule: no approved_by, no exception.
--
-- Written in portable SQL. Tested patterns for Snowflake / BigQuery / Postgres;
-- adjust types (VARCHAR→STRING, NUMBER→NUMERIC) to your warehouse.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS governance;

CREATE TABLE IF NOT EXISTS governance.override_ledger (
    exception_id        VARCHAR       NOT NULL,  -- Stable ID, e.g. EXC-001. Never reuse.
    customer_id         VARCHAR       NOT NULL,  -- Same key as the metric's grain.
    exception_type      VARCHAR       NOT NULL,  -- count_as_paying | exclude | merge_into_parent
    parent_customer_id  VARCHAR,                 -- Required only for merge_into_parent.
    mrr_override        NUMERIC(12,2),           -- Required for count_as_paying (billing has no amount).
    metric              VARCHAR       NOT NULL,  -- Which metric this exception applies to.
    reason              VARCHAR       NOT NULL,  -- WHY, in business language. One sentence.
    approved_by         VARCHAR       NOT NULL,  -- A human. Role or name. Never blank.
    approved_at         DATE          NOT NULL,
    valid_from          DATE          NOT NULL,
    valid_until         DATE,                    -- NULL = open-ended. Prefer an end date.
    notes               VARCHAR,                 -- Contract #, ticket links, cleanup plan.
    _synced_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (exception_id),
    CHECK (exception_type IN ('count_as_paying', 'exclude', 'merge_into_parent')),
    CHECK (exception_type <> 'merge_into_parent' OR parent_customer_id IS NOT NULL),
    CHECK (exception_type <> 'count_as_paying'   OR mrr_override IS NOT NULL),
    CHECK (valid_until IS NULL OR valid_until >= valid_from)
);

-- Note: Snowflake and BigQuery don't enforce CHECK / PRIMARY KEY constraints.
-- Run tests/ledger_quality_checks.sql after every sync instead.
