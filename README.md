# CredResolve SQL Repository

These SQL scripts operate on the 17 operational source tables loaded into the MySQL database `credresolve`. The separate `data_dictionary.csv` is reference metadata and is not included in the operational-table row-count query.

## Recommended run order

1. `02_data_quality_checks.sql` — read-only checks for source volumes, duplicate-key groups, missing identifiers, account anomalies, and payment-status distributions.
2. `03_cleaning_layer.sql` — rebuilds typed `accounts_clean`, canonical `payments_clean`, and `payments_review`.
3. `04_golden_dataset.sql` — rebuilds account-grain `golden_accounts` from the cleaned tables.
4. `05_business_analysis.sql` — creates/refreshes `ceo_kpi_summary` and `monthly_payment_trends`, then runs status, DPD, loan-type and risk-segment analyses.
5. `01_monthly_recovery.sql` — optional focused monthly trend query; run after the cleaning layer.

Run each script separately in MySQL Workbench or the MySQL client after selecting the `credresolve` database. The date fields in the raw CSV tables are stored as text; `03_cleaning_layer.sql` uses `STR_TO_DATE(..., '%Y-%m-%d %H:%i:%s')` for the known timestamp strings.

## Safety and repeatability

- Keep a database backup before rebuilding derived tables.
- `02_data_quality_checks.sql` is read-only.
- `03_cleaning_layer.sql` **drops and recreates only** `accounts_clean`, `payments_clean`, and `payments_review`. It does not modify raw source tables.
- `04_golden_dataset.sql` **drops and recreates only** `golden_accounts`.
- The raw source tables (`accounts`, `payments`, `calls`, and the other source tables) are retained.
- Do not confuse `payment_reference` with a guaranteed unique transaction ID; this dataset reuses references. Canonicalization checks core fields for each `payment_id`. Records with missing payment IDs or conflicts in core transaction fields are routed to `payments_review`.
- The loader script `load_data_to_mysql.py` truncates each destination table before import. Do not rerun the loader unless you intentionally want to replace all imported CSV tables and have a backup.

## Expected validation results for the supplied dataset

- `accounts_clean`: 30,000 rows; distinct `account_id` count 30,000.
- `payments_clean`: 25,000 rows; distinct `payment_id` count 25,000.
- `payments_review`: 0 rows for this supplied extract (inspect this in future refreshes; do not assume it will always be zero).
- `golden_accounts`: 30,000 rows; distinct `account_id` count 30,000.
- Successful canonical payments: 17,534; gross successful amount ₹1,315,583,964.64.
- The successful-payment count and gross amount reconcile across `payments_clean`, `monthly_payment_trends`, and `golden_accounts`.

## Metric cautions

- Gross successful-payment amount is not net recovery, profit, or incremental impact.
- Reversed payments are not subtracted because the source does not provide reliable linkage to original successful transactions.
- `account_payment_coverage_pct` measures accounts with at least one successful payment, not a recovery rate.
- Data covers January through August 8, 2026 for payment events; August is partial and the source does not provide the full 12-month history requested in the assignment.
- SQL segmentation results are descriptive and do not establish causal channel, vendor, campaign, or targeting impact.
