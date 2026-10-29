-- CredResolve | 02_data_quality_checks.sql
-- READ-ONLY pre-cleaning checks. Run before 03_cleaning_layer.sql.
-- These queries do not modify or delete source data.
USE credresolve;

-- 1. Source-table volumes (all 17 expected operational source tables).
SELECT 'accounts' AS dataset, COUNT(*) AS row_count FROM accounts
UNION ALL SELECT 'borrowers', COUNT(*) FROM borrowers
UNION ALL SELECT 'agents', COUNT(*) FROM agents
UNION ALL SELECT 'agent_sessions', COUNT(*) FROM agent_sessions
UNION ALL SELECT 'campaigns', COUNT(*) FROM campaigns
UNION ALL SELECT 'daily_targeting', COUNT(*) FROM daily_targeting
UNION ALL SELECT 'calls', COUNT(*) FROM calls
UNION ALL SELECT 'call_attempts', COUNT(*) FROM call_attempts
UNION ALL SELECT 'call_dispositions', COUNT(*) FROM call_dispositions
UNION ALL SELECT 'whatsapp_events', COUNT(*) FROM whatsapp_events
UNION ALL SELECT 'sms_events', COUNT(*) FROM sms_events
UNION ALL SELECT 'field_visits', COUNT(*) FROM field_visits
UNION ALL SELECT 'promises_to_pay', COUNT(*) FROM promises_to_pay
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'vendor_telephony', COUNT(*) FROM vendor_telephony
UNION ALL SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL SELECT 'account_status_history', COUNT(*) FROM account_status_history
ORDER BY dataset;

-- 2. Duplicate-key group counts in source tables.
SELECT 'accounts.account_id' AS key_name, COUNT(*) AS duplicate_groups
FROM (SELECT account_id FROM accounts GROUP BY account_id HAVING COUNT(*) > 1) x
UNION ALL SELECT 'payments.payment_id', COUNT(*)
FROM (SELECT payment_id FROM payments WHERE payment_id IS NOT NULL AND TRIM(payment_id) <> '' GROUP BY payment_id HAVING COUNT(*) > 1) x
UNION ALL SELECT 'calls.call_id', COUNT(*)
FROM (SELECT call_id FROM calls WHERE call_id IS NOT NULL AND TRIM(call_id) <> '' GROUP BY call_id HAVING COUNT(*) > 1) x
UNION ALL SELECT 'call_attempts.attempt_id', COUNT(*)
FROM (SELECT attempt_id FROM call_attempts WHERE attempt_id IS NOT NULL AND TRIM(attempt_id) <> '' GROUP BY attempt_id HAVING COUNT(*) > 1) x
UNION ALL SELECT 'whatsapp_events.whatsapp_event_id', COUNT(*)
FROM (SELECT whatsapp_event_id FROM whatsapp_events WHERE whatsapp_event_id IS NOT NULL AND TRIM(whatsapp_event_id) <> '' GROUP BY whatsapp_event_id HAVING COUNT(*) > 1) x
UNION ALL SELECT 'sms_events.sms_event_id', COUNT(*)
FROM (SELECT sms_event_id FROM sms_events WHERE sms_event_id IS NOT NULL AND TRIM(sms_event_id) <> '' GROUP BY sms_event_id HAVING COUNT(*) > 1) x
ORDER BY key_name;

-- 3. Missing key / relationship checks.
SELECT 'accounts_missing_account_id' AS check_name, COUNT(*) AS affected_rows
FROM accounts WHERE account_id IS NULL OR TRIM(account_id) = ''
UNION ALL SELECT 'accounts_missing_borrower_id', COUNT(*)
FROM accounts WHERE borrower_id IS NULL OR TRIM(borrower_id) = ''
UNION ALL SELECT 'payments_missing_payment_id', COUNT(*)
FROM payments WHERE payment_id IS NULL OR TRIM(payment_id) = ''
UNION ALL SELECT 'payments_missing_account_id', COUNT(*)
FROM payments WHERE account_id IS NULL OR TRIM(account_id) = ''
UNION ALL SELECT 'payments_missing_amount', COUNT(*)
FROM payments WHERE amount IS NULL OR TRIM(amount) = ''
ORDER BY check_name;

-- 4. Raw account anomalies. These are flags, not automatic corrections.
SELECT
  SUM(CASE WHEN CAST(NULLIF(TRIM(outstanding_amount), '') AS DECIMAL(18,2)) > CAST(NULLIF(TRIM(principal_amount), '') AS DECIMAL(18,2)) THEN 1 ELSE 0 END) AS outstanding_exceeds_principal,
  SUM(CASE WHEN UPPER(TRIM(status)) IN ('CLOSED','PAID','WRITEOFF') AND CAST(NULLIF(TRIM(outstanding_amount), '') AS DECIMAL(18,2)) > 0 THEN 1 ELSE 0 END) AS closed_like_status_with_positive_balance,
  SUM(CASE WHEN CAST(NULLIF(TRIM(dpd), '') AS SIGNED) > 90 THEN 1 ELSE 0 END) AS accounts_over_90_dpd
FROM accounts;

-- 5. Payment status and duplicate context. Raw SUM(amount) is intentionally not used here.
SELECT UPPER(TRIM(payment_status)) AS payment_status,
       COUNT(*) AS source_rows,
       COUNT(DISTINCT payment_id) AS distinct_payment_ids
FROM payments
GROUP BY UPPER(TRIM(payment_status))
ORDER BY source_rows DESC;
