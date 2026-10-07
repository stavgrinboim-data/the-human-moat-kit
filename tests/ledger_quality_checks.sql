-- =============================================================================
-- Quality checks: run after every ledger sync and in CI.
-- Each query should return ZERO rows. Any row = a broken promise.
-- =============================================================================

-- 1. No approved_by, no exception.
SELECT exception_id, 'missing approver' AS issue
FROM governance.override_ledger
WHERE approved_by IS NULL OR TRIM(approved_by) = '';

-- 2. Unknown exception types (typos in the sheet happen).
SELECT exception_id, exception_type AS issue
FROM governance.override_ledger
WHERE exception_type NOT IN ('count_as_paying', 'exclude', 'merge_into_parent');

-- 3. merge_into_parent without a parent / count_as_paying without an amount.
SELECT exception_id, 'incomplete row' AS issue
FROM governance.override_ledger
WHERE (exception_type = 'merge_into_parent' AND parent_customer_id IS NULL)
   OR (exception_type = 'count_as_paying'   AND mrr_override IS NULL);

-- 4. Duplicate IDs (sheet rows copy-pasted).
SELECT exception_id, 'duplicate id' AS issue
FROM governance.override_ledger
GROUP BY exception_id
HAVING COUNT(*) > 1;

-- 5. Conflicting active exceptions for the same customer.
SELECT customer_id, 'conflicting active exceptions' AS issue
FROM governance.override_ledger
WHERE metric = 'paying_customer'
  AND valid_from <= CURRENT_DATE
  AND (valid_until IS NULL OR valid_until >= CURRENT_DATE)
GROUP BY customer_id
HAVING COUNT(DISTINCT exception_type) > 1;

-- 6. Stale exceptions: the source system has caught up, so the ledger row should be retired.
--    (An exception that outlives its reason becomes a new bug.)
SELECT e.exception_id, 'customer now in billing, retire exception' AS issue
FROM governance.override_ledger e
JOIN billing.subscriptions s ON s.customer_id = e.customer_id
WHERE e.exception_type = 'count_as_paying'
  AND (e.valid_until IS NULL OR e.valid_until >= CURRENT_DATE)
  AND s.status IN ('active', 'past_due') AND s.mrr > 0;
