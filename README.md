# CredResolve — Data Analytics & Collections Intelligence

## Project Overview

CredResolve is a data analytics project designed to investigate whether the reported claim that **“recovery has improved by 11% month-on-month”** is supported by the available data.

The project focuses on data quality, payment reconciliation, portfolio analysis, operational performance, statistical investigation, and investment decision-making.

Using SQL, Python, Jupyter Notebook, and data visualizations, the analysis reconstructs payment trends, identifies inconsistencies across operational datasets, builds a Golden Dataset, and develops evidence-based recommendations for leadership.

**The central finding is that the available gross successful-payment data does not support sustained 11% month-on-month growth.** However, gross successful payments are not equivalent to verified net recovery, and the available payment period is incomplete.

## Business Objectives

- Independently evaluate the reported recovery improvement.
- Identify duplicate records, inconsistent identities, missing references, and other data-quality issues.
- Build a cleaned analytical layer and Golden Dataset.
- Investigate portfolio, campaign, channel, calling, and payment patterns.
- Design a counterfactual approach to evaluate targeting-strategy changes.
- Recommend a responsible approach to allocating the proposed ₹10 crore investment.
- Design a production-oriented analytics pipeline and executive reporting system.

## Technology Stack

- **SQL / MySQL:** Data validation, cleaning, transformation, KPI calculations, and analytical queries.
- **Python:** Data profiling, statistical investigation, and operational analysis.
- **Jupyter Notebook:** Reproducible analysis and documentation of analytical reasoning.
- **Pandas and NumPy:** Data manipulation and numerical analysis.
- **CSV:** Source data, analytical outputs, and Golden Dataset.
- **PNG:** Executive dashboard and architecture diagram.

## Project Structure

```text
CredResolve/
├── README.md
├── .gitignore
├── load_data_to_mysql.py
├── dataset/                 # Original CSV files; kept local
├── golden_dataset/
│   └── golden_accounts.csv
├── notebooks/
│   ├── 01_dataset_profiling.ipynb
│   ├── 02_golden_dataset.ipynb
│   ├── 03_statistical_investigation.ipynb
│   ├── 04_operational_driver_analysis.ipynb
│   └── data_quality_summary.csv
├── sql/
│   ├── 01_monthly_recovery.sql
│   ├── 02_data_quality_checks.sql
│   ├── 03_cleaning_layer.sql
│   ├── 04_golden_dataset.sql
│   ├── 05_business_analysis.sql
│   └── README.md
├── dashboard/
│   └── ceo_dashboard.png
├── outputs/                 # Dashboard, memo, diagrams and analysis outputs
├── reports/                 # Quality, statistical and operational reports
├── analysis/
├── pipeline/
└── staging/
```

The `analysis`, `pipeline`, and `staging` folders are reserved for future development.

## Key Findings

### 1. Payment Trends

- Raw payments contain **25,500 rows** and 25,000 distinct payment IDs.
- The cleaned payment table contains **25,000 canonical payment records**.
- There are **17,534 successful payment records**, representing a gross successful-payment amount of approximately **₹131.56 crore**.
- January–July 2026 gross successful-payment amounts fluctuate without sustained month-on-month growth.
- August data is available only through August 8, 2026, so it is not directly comparable with complete months.

### 2. Data Quality

The investigation identified several issues requiring care in business reporting:

- 500 duplicate payment-ID groups.
- 1,350 duplicate call-ID groups.
- 600 duplicate WhatsApp event-ID groups.
- 455 account records with missing borrower IDs.
- 13,029 accounts where reported outstanding exceeds principal.
- 22,461 closed-like accounts with positive outstanding balances.
- 5,453 accounts with more than 90 days past due.

These findings are signals for reconciliation and investigation; they should not automatically be interpreted as confirmed business errors.

### 3. Account Payment Coverage

A total of 13,284 accounts have at least one successful payment, equivalent to **44.28% of the 30,000 accounts**.

This is an account payment coverage measure, not a recovery rate. A reliable recovery rate requires an appropriate denominator and reconciled net collections.

### 4. Operational and Statistical Investigation

Additional analysis examines:

- Attempt frequency and calling outcomes.
- Descriptive differences across telephony vendors and calling hours.
- Campaign targeting windows and strategy versions.
- Agent and borrower identity quality.
- Digital engagement and field-visit patterns.
- Timestamp limitations, missing dimensions, and selection effects.

Descriptive differences do not establish causation. Unresolved identity and attribution issues limit reliable rankings of agents, vendors, campaigns, and channels.

## Golden Dataset and Cleaning Approach

The project creates a cleaned account layer, a cleaned payment layer, and a Golden Dataset for downstream analysis.

Key decisions include:

- Preserve raw source tables for traceability.
- Normalize text fields and convert numeric and timestamp values.
- Consolidate repeated payment IDs only when their core transaction fields agree.
- Preserve conflicting or missing-ID payment records for review.
- Apply primary-key checks to the cleaned account and payment tables.
- Validate row counts and reconcile successful-payment totals across analytical layers.

The verified Golden Dataset contains **30,000 account rows with 30,000 unique account IDs**.

## Investment Recommendation

Better borrower targeting is proposed as a candidate area to test, not as a proven best-performing investment.

The available data is not sufficient to establish a reliable incremental recovery estimate or return on investment for any of the six investment choices.

Before committing the full ₹10 crore, the recommended approach is to:

1. Reconcile payment events, reversals, attribution, and collection costs.
2. Define a consistent net-recovery metric and observation window.
3. Run a controlled targeting pilot with comparable treatment and control groups.
4. Measure incremental net recovery, cost, break-even point, and uncertainty.
5. Scale investment only if the observed improvement is credible and economically justified.

## Production Architecture

The proposed production design follows:

**Raw → Staging → Clean → Golden → Feature → Metrics → Dashboard**

The design includes data contracts, primary keys, data lineage, incremental processing, late-arriving events, backfills, quality checks, monitoring, and anomaly detection.

The current project implements analytical tables, cleaning scripts, KPI views, notebooks, and reporting outputs. The broader production orchestration and monitoring capabilities remain proposed design components rather than fully deployed services.

## How to Reproduce the Analysis

### Prerequisites

- Python with Jupyter Notebook.
- Pandas and NumPy.
- MySQL 8.0 or a compatible version supporting the SQL features used by the scripts.

### 1. Prepare the dataset

Place the authorized original CSV files in the local `dataset/` directory.

The original dataset files are intentionally excluded from the public repository. Reproduction therefore requires access to the authorized source data.

### 2. Run the notebooks

Open Jupyter Notebook from the project directory and execute the notebooks in order:

1. `01_dataset_profiling.ipynb`
2. `02_golden_dataset.ipynb`
3. `03_statistical_investigation.ipynb`
4. `04_operational_driver_analysis.ipynb`

Restart the kernel and run all cells to validate the analysis from beginning to end.

### 3. Run the SQL analysis

Use the instructions in `sql/README.md`.

The scripts cover data-quality checks, cleaning, Golden Dataset validation, business analysis, and monthly payment trends. Execute them against the intended database and review the results before replacing any existing derived tables.

**Important:** Review `load_data_to_mysql.py` before running it. The loader truncates destination tables before importing data. Use a backup and the correct database configuration to avoid unintended data loss.

## Deliverables

- Four analysis notebooks.
- SQL scripts and SQL documentation.
- Golden Dataset (`golden_accounts.csv`).
- Data quality and cleaning report.
- Supporting statistical and operational analysis outputs.
- Executive dashboard.
- Two-page executive decision memo.
- Production architecture diagram.
- Production analytics design document.

## Limitations

- The available payment events cover January 1 through August 8, 2026, rather than a complete 12-month period.
- Gross successful-payment amount is not verified net recovery.
- Reliable ROI calculations require additional cost and incremental-treatment-effect evidence.
- Identity conflicts and attribution limitations restrict some operational comparisons.
- Observational associations do not establish causal effects.

## Conclusion

CredResolve demonstrates how data forensics, careful metric definitions, reproducible SQL, and transparent statistical reasoning can challenge a business performance claim.

The analysis does not substantiate sustained 11% month-on-month growth from the available gross successful-payment data. It recommends improving data reliability and running a controlled experiment before making a large investment decision.
