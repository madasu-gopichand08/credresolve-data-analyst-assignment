-- CredResolve | 04_golden_dataset.sql
-- Builds one account-grain analytical table from accounts_clean and payments_clean.
-- Re-running replaces only the derived golden_accounts table; source tables remain intact.
USE credresolve;

DROP TABLE IF EXISTS golden_accounts;

CREATE TABLE golden_accounts AS
SELECT
  a.account_id,
  a.borrower_id,
  a.loan_type,
  a.principal_amount,
  a.outstanding_amount,
  a.dpd,
  a.risk_segment,
  a.status,
  a.opened_at,
  a.timezone,
  a.schema_version,
  COALESCE(p.successful_payment_count, 0) AS successful_payment_count,
  COALESCE(p.successful_payment_amount, 0.00) AS successful_payment_amount,
  p.last_successful_payment_at,
  CASE WHEN a.borrower_id IS NULL OR TRIM(a.borrower_id) = '' THEN 1 ELSE 0 END AS missing_borrower_id_flag,
  CASE WHEN a.outstanding_amount > a.principal_amount THEN 1 ELSE 0 END AS outstanding_exceeds_principal_flag,
  CASE WHEN a.status IN ('CLOSED','PAID') AND a.outstanding_amount > 0 THEN 1 ELSE 0 END AS closed_with_outstanding_flag,
  CASE WHEN a.status = 'WRITEOFF' AND a.outstanding_amount > 0 THEN 1 ELSE 0 END AS written_off_with_outstanding_flag
FROM accounts_clean a
LEFT JOIN (
  SELECT account_id,
         COUNT(DISTINCT payment_id) AS successful_payment_count,
         CAST(SUM(amount) AS DECIMAL(18,2)) AS successful_payment_amount,
         MAX(event_at) AS last_successful_payment_at
  FROM payments_clean
  WHERE payment_status = 'SUCCESS'
  GROUP BY account_id
) p ON p.account_id = a.account_id;

ALTER TABLE golden_accounts ADD PRIMARY KEY (account_id);

-- Validation and reconciliation.
SELECT COUNT(*) AS golden_rows,
       COUNT(DISTINCT account_id) AS distinct_account_ids,
       SUM(successful_payment_count > 0) AS accounts_with_successful_payments,
       ROUND(100.0 * SUM(successful_payment_count > 0) / NULLIF(COUNT(*), 0), 2) AS account_payment_coverage_pct,
       SUM(successful_payment_count) AS successful_payment_count,
       ROUND(SUM(successful_payment_amount), 2) AS gross_successful_payment_amount
FROM golden_accounts;

SELECT
  ROUND((SELECT SUM(successful_payment_amount) FROM golden_accounts), 2) AS golden_gross_success_amount,
  ROUND((SELECT SUM(amount) FROM payments_clean WHERE payment_status = 'SUCCESS'), 2) AS clean_payment_gross_success_amount;
