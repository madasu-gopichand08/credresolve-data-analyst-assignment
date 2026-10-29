-- CredResolve | 03_cleaning_layer.sql
-- Rebuilds only derived tables. The raw source tables are never dropped or changed.
-- WARNING: this replaces existing accounts_clean, payments_clean, and payments_review tables.
-- Keep the provided credresolve_backup.sql backup before running this script.
USE credresolve;

DROP TEMPORARY TABLE IF EXISTS tmp_payment_stage;
DROP TEMPORARY TABLE IF EXISTS tmp_payment_core_versions;
DROP TABLE IF EXISTS payments_review;
DROP TABLE IF EXISTS payments_clean;
DROP TABLE IF EXISTS accounts_clean;

-- A. Typed account layer. The raw source columns remain unchanged.
CREATE TABLE accounts_clean AS
SELECT
  CAST(NULLIF(TRIM(account_id), '') AS CHAR(100)) AS account_id,
  CAST(NULLIF(TRIM(borrower_id), '') AS CHAR(100)) AS borrower_id,
  CAST(NULLIF(TRIM(loan_type), '') AS CHAR(100)) AS loan_type,
  CAST(NULLIF(TRIM(principal_amount), '') AS DECIMAL(18,2)) AS principal_amount,
  CAST(NULLIF(TRIM(outstanding_amount), '') AS DECIMAL(18,2)) AS outstanding_amount,
  CAST(NULLIF(TRIM(dpd), '') AS SIGNED) AS dpd,
  CAST(NULLIF(TRIM(risk_segment), '') AS CHAR(100)) AS risk_segment,
  UPPER(NULLIF(TRIM(status), '')) AS status,
  CASE
    WHEN opened_at IS NULL OR CHAR_LENGTH(TRIM(opened_at)) = 0 THEN NULL
    ELSE STR_TO_DATE(TRIM(opened_at), '%Y-%m-%d %H:%i:%s')
  END AS opened_at,
  CAST(NULLIF(TRIM(timezone), '') AS CHAR(80)) AS timezone,
  CAST(NULLIF(TRIM(schema_version), '') AS CHAR(40)) AS schema_version
FROM accounts
WHERE account_id IS NOT NULL AND TRIM(account_id) <> '';

ALTER TABLE accounts_clean ADD PRIMARY KEY (account_id);

-- B. Parse/normalize payment values while preserving the source table.
CREATE TEMPORARY TABLE tmp_payment_stage AS
SELECT
  CAST(NULLIF(TRIM(payment_id), '') AS CHAR(100)) AS payment_id,
  CAST(NULLIF(TRIM(account_id), '') AS CHAR(100)) AS account_id,
  CAST(NULLIF(TRIM(borrower_id), '') AS CHAR(100)) AS borrower_id,
  CASE
    WHEN event_at IS NULL OR CHAR_LENGTH(TRIM(event_at)) = 0 THEN NULL
    ELSE STR_TO_DATE(TRIM(event_at), '%Y-%m-%d %H:%i:%s')
  END AS event_at,
  CAST(NULLIF(TRIM(payment_reference), '') AS CHAR(255)) AS payment_reference,
  CAST(NULLIF(TRIM(amount), '') AS DECIMAL(18,2)) AS amount,
  UPPER(NULLIF(TRIM(payment_status), '')) AS payment_status,
  UPPER(NULLIF(TRIM(payment_method), '')) AS payment_method,
  CAST(NULLIF(TRIM(provider_id), '') AS CHAR(100)) AS provider_id
FROM payments;

-- C. Count distinct versions of payment core fields. A reference difference alone
-- does not make a payment a different transaction; account/borrower/time/amount/
-- status/method/provider must agree before one row can enter payments_clean.
CREATE TEMPORARY TABLE tmp_payment_core_versions AS
SELECT
  payment_id,
  COUNT(*) AS source_row_count,
  COUNT(DISTINCT SHA2(CONCAT_WS(CHAR(31),
    COALESCE(account_id, '<NULL>'),
    COALESCE(borrower_id, '<NULL>'),
    COALESCE(DATE_FORMAT(event_at, '%Y-%m-%d %H:%i:%s'), '<NULL>'),
    COALESCE(CAST(amount AS CHAR), '<NULL>'),
    COALESCE(payment_status, '<NULL>'),
    COALESCE(payment_method, '<NULL>'),
    COALESCE(provider_id, '<NULL>')
  ), 256)) AS core_version_count
FROM tmp_payment_stage
WHERE payment_id IS NOT NULL
GROUP BY payment_id;

-- D. Preserve missing-ID or core-conflicting payment records for review.
CREATE TABLE payments_review AS
SELECT
  s.*,
  v.source_row_count,
  v.core_version_count,
  CASE
    WHEN s.payment_id IS NULL THEN 'MISSING_PAYMENT_ID'
    WHEN v.core_version_count > 1 THEN 'CONFLICTING_CORE_FIELDS'
    ELSE 'REVIEW'
  END AS review_reason
FROM tmp_payment_stage s
LEFT JOIN tmp_payment_core_versions v ON v.payment_id = s.payment_id
WHERE s.payment_id IS NULL OR v.core_version_count > 1;

-- E. One canonical row per payment ID, only when core fields agree.
-- When duplicates differ only by payment_reference, prefer a non-empty reference.
CREATE TABLE payments_clean AS
SELECT
  payment_id, account_id, borrower_id, event_at, payment_reference, amount,
  payment_status, payment_method, provider_id, source_row_count
FROM (
  SELECT
    s.payment_id, s.account_id, s.borrower_id, s.event_at, s.payment_reference,
    s.amount, s.payment_status, s.payment_method, s.provider_id,
    v.source_row_count,
    ROW_NUMBER() OVER (
      PARTITION BY s.payment_id
      ORDER BY (s.payment_reference IS NULL) ASC,
               s.payment_reference ASC
    ) AS rn
  FROM tmp_payment_stage s
  JOIN tmp_payment_core_versions v ON v.payment_id = s.payment_id
  WHERE v.core_version_count = 1
) ranked
WHERE rn = 1;

ALTER TABLE payments_clean ADD PRIMARY KEY (payment_id);

-- F. Validation summary. Expected for this dataset: 30,000 accounts, 25,000
-- canonical payments, and 0 payment IDs in payments_review with core conflicts.
SELECT 'accounts_clean' AS object_name,
       COUNT(*) AS row_count,
       COUNT(DISTINCT account_id) AS distinct_keys
FROM accounts_clean
UNION ALL
SELECT 'payments_clean', COUNT(*), COUNT(DISTINCT payment_id)
FROM payments_clean
UNION ALL
SELECT 'payments_review', COUNT(*), COUNT(DISTINCT payment_id)
FROM payments_review;

SELECT core_version_count, COUNT(DISTINCT payment_id) AS payment_id_groups
FROM payments_review
GROUP BY core_version_count
ORDER BY core_version_count;

DROP TEMPORARY TABLE IF EXISTS tmp_payment_stage;
DROP TEMPORARY TABLE IF EXISTS tmp_payment_core_versions;
