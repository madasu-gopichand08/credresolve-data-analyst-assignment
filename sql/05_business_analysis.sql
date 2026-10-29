-- CredResolve | 05_business_analysis.sql
-- Descriptive analytics. Amounts are gross successful payments, not net recovery.
USE credresolve;

CREATE OR REPLACE VIEW monthly_payment_trends AS
SELECT DATE_FORMAT(event_at, '%Y-%m') AS payment_month,
       COUNT(DISTINCT payment_id) AS successful_payment_count,
       ROUND(SUM(amount), 2) AS gross_successful_amount,
       MIN(event_at) AS first_payment_at,
       MAX(event_at) AS last_payment_at
FROM payments_clean
WHERE payment_status = 'SUCCESS'
GROUP BY DATE_FORMAT(event_at, '%Y-%m');

CREATE OR REPLACE VIEW ceo_kpi_summary AS
SELECT
  COUNT(*) AS total_accounts,
  SUM(outstanding_amount) AS total_reported_outstanding,
  SUM(dpd > 90) AS accounts_over_90_dpd,
  SUM(successful_payment_count > 0) AS accounts_with_successful_payments,
  ROUND(100.0 * SUM(successful_payment_count > 0) / NULLIF(COUNT(*), 0), 2) AS account_payment_coverage_pct,
  SUM(successful_payment_count) AS successful_payment_count,
  ROUND(SUM(successful_payment_amount), 2) AS gross_successful_payment_amount
FROM golden_accounts;

SELECT * FROM ceo_kpi_summary;
SELECT * FROM monthly_payment_trends ORDER BY payment_month;

-- Payment outcomes. Amount sums are not net of reversals.
SELECT payment_status,
       COUNT(*) AS canonical_payment_count,
       ROUND(SUM(amount), 2) AS gross_amount
FROM payments_clean
GROUP BY payment_status
ORDER BY canonical_payment_count DESC;

-- Account status distribution; source label is named `status`, not `account_status`.
SELECT status,
       COUNT(*) AS account_count,
       ROUND(SUM(outstanding_amount), 2) AS reported_outstanding_amount
FROM golden_accounts
GROUP BY status
ORDER BY account_count DESC;

-- DPD segmentation. The numerator is account-level payment coverage, not a collection rate.
SELECT CASE
         WHEN dpd = 0 THEN 'Current (0)'
         WHEN dpd BETWEEN 1 AND 30 THEN '1-30'
         WHEN dpd BETWEEN 31 AND 60 THEN '31-60'
         WHEN dpd BETWEEN 61 AND 90 THEN '61-90'
         WHEN dpd > 90 THEN '>90'
         ELSE 'Unknown'
       END AS dpd_bucket,
       COUNT(*) AS account_count,
       SUM(successful_payment_count > 0) AS accounts_with_successful_payments,
       ROUND(100.0 * SUM(successful_payment_count > 0) / NULLIF(COUNT(*), 0), 2) AS account_payment_coverage_pct,
       ROUND(SUM(outstanding_amount), 2) AS reported_outstanding_amount,
       ROUND(SUM(successful_payment_amount), 2) AS gross_successful_payment_amount
FROM golden_accounts
GROUP BY dpd_bucket
ORDER BY MIN(dpd);

-- Loan type segmentation.
SELECT loan_type,
       COUNT(*) AS account_count,
       SUM(successful_payment_count > 0) AS accounts_with_successful_payments,
       ROUND(100.0 * SUM(successful_payment_count > 0) / NULLIF(COUNT(*), 0), 2) AS account_payment_coverage_pct,
       ROUND(SUM(outstanding_amount), 2) AS reported_outstanding_amount,
       ROUND(SUM(successful_payment_amount), 2) AS gross_successful_payment_amount
FROM golden_accounts
GROUP BY loan_type
ORDER BY account_count DESC;

-- Risk-segment analysis.
SELECT risk_segment,
       COUNT(*) AS account_count,
       SUM(successful_payment_count > 0) AS accounts_with_successful_payments,
       ROUND(100.0 * SUM(successful_payment_count > 0) / NULLIF(COUNT(*), 0), 2) AS account_payment_coverage_pct,
       ROUND(SUM(outstanding_amount), 2) AS reported_outstanding_amount,
       ROUND(SUM(successful_payment_amount), 2) AS gross_successful_payment_amount
FROM golden_accounts
GROUP BY risk_segment
ORDER BY account_count DESC;
