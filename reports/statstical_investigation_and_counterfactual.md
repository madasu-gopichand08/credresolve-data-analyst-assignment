# CredResolve — Statistical Investigation and Counterfactual Plan

## Executive conclusion

The supplied data does **not** demonstrate sustained 11% month-on-month growth in gross successful payments. After consolidating repeated payment IDs whose core transaction fields agree, successful payments total **17,534 IDs** and **₹1,315,583,964.64 (₹131.56 crore) gross**. January to July gross successful-payment amount changes from ₹187.23 million to ₹187.24 million — **+0.007% overall**. Monthly movement is volatile: −9.13% in February, +11.03% in March, −7.29% in April, +5.20% in May, −4.72% in June and +6.65% in July. August contains only 1–8 August data and is not comparable to a full month.

This is a conclusion about the **gross successful-payment proxy**, not verified net recovery. Reversal/refund pairing, historical eligible-account denominators and validated attribution are insufficient to prove the business's true recovery rate or explain causality.

## 1. Evidence and definitions

- **Gross successful-payment amount:** sum of canonical payment records with `payment_status = SUCCESS`; not net of reversals/refunds and not net of collection costs.
- **Account payment coverage:** share of all accounts in the supplied snapshot with at least one successful payment in the observed window; not a recovery rate.
- **Canonical payment:** one record per `payment_id` after checking agreement on account, borrower, event timestamp, amount, status, method and provider. Conflicting IDs should be held for review. Payment reference is not used as a unique transaction key.
- The package README identifies the dataset as synthetic challenge data and says it intentionally includes duplicated rows, inconsistent identifiers, mixed time zones, legacy codes, late-arriving events and overwritten-style history.

## 2. Monthly gross successful-payment trend

| Month | Successful payment IDs | Gross successful amount | MoM change |
|---|---:|---:|---:|
| Jan 2026 | 2,464 | ₹187,229,127.59 | — |
| Feb 2026 | 2,268 | ₹170,142,453.76 | −9.13% |
| Mar 2026 | 2,524 | ₹188,912,374.02 | +11.03% |
| Apr 2026 | 2,406 | ₹175,138,043.41 | −7.29% |
| May 2026 | 2,449 | ₹184,250,278.50 | +5.20% |
| Jun 2026 | 2,366 | ₹175,559,726.97 | −4.72% |
| Jul 2026 | 2,441 | ₹187,242,265.08 | +6.65% |
| Aug 1–8, 2026 | 616 | ₹47,109,695.31 | Not comparable (partial month) |

January-to-July amount change is +0.007%, effectively flat at this scale. The partial August average is around ₹5.89 million per observed calendar day vs July's ₹6.04 million per day (about −2.51%), but this is a descriptive check, not a full-month forecast.

**Finding classification:** Strong evidence that the reported +11% improvement is not supported when interpreted as sustained month-on-month growth in this gross-payment series. The actual recovery-rate claim remains unproven because the supplied metric definition is not sufficiently specified.

## 3. Data-forensics and analytical fitness findings

| Finding | Observed evidence | Consequence |
|---|---|---|
| Duplicate payment IDs | 25,500 raw rows; 25,000 distinct payment IDs; 500 repeated-ID groups; no core-field conflicts in the defined comparison | Deduplication affects 500 surplus rows; preserve raw rows and document canonicalization. |
| Payment reference reuse | 3,407 references map to more than one distinct payment ID, covering 7,218 payment IDs | Never deduplicate on payment reference alone. |
| Campaign-window mismatch | 45,000 targeting rows; 15,253 dated before campaign start date, 20,886 after campaign end date and 8,861 within active calendar dates | Campaign-to-target attribution is not reliable until campaign dates, event time zone and late-arriving data are reconciled. These are calendar-date flags, not final proof for each row. |
| Strategy version ambiguity | `legacy`, `v1`, `v2` and `v3` versions appear across multiple campaign-start and targeting months | Version labels do not identify a single global cutover date. Obtain the approved change log and assignment trail. |
| Agent identity conflict | 30,000 source rows but only 1,000 distinct `agent_id` values; all 1,000 IDs are associated with multiple employee codes and names, and multiple vendors | Agent performance, tenure, vendor and agent-hour metrics are not defensible until identity resolution is completed. |
| Borrower identity conflict | 30,600 source rows but 11,015 distinct borrower IDs; 8,185 borrower IDs have multiple names, 8,399 have multiple phone values; 455 accounts miss borrower ID and another 2,458 have a non-null ID absent from the borrower table | Borrower-level matching, geographic attribution and clustered uncertainty estimates are unreliable until the borrower crosswalk is repaired. |
| Account status/balance contradictions | 22,461 `CLOSED`, `PAID` or `WRITEOFF` accounts have positive reported outstanding; 13,029 accounts report outstanding greater than principal | Reconcile fees, write-off semantics, status history and outstanding definitions before using outstanding for ROI or collection rate. |
| Time-zone diagnostic | 30,191 of 60,000 history rows have `recorded_at < event_at` under a naive timestamp comparison; 45,107 have absolute naive lag above six hours | Do not infer true event order until source time zones/offsets are normalized. |
| Promise maturity | 1,242 promise dates fall after 8 August 2026, the end of the observed payment window | These PTPs are right-censored at the snapshot date; do not call them broken before their due date and sufficient follow-up. |
| Period coverage | Payments run 1 January–8 August 2026 | The assignment asks about approximately 12 months, but only about seven full months plus eight August days are present. Seasonality and full-year trend cannot be assessed. |

Client and language are not explicit dimensions in the supplied schema, so client- and language-level effects cannot be tested reliably from these columns.

## 4. Mix and cohort investigation

The current-account snapshot joined to successful payments gives the following **descriptive account payment coverage**:

| Current snapshot segment | Accounts | Accounts with success | Coverage |
|---|---:|---:|---:|
| HIGH risk | 7,552 | 3,300 | 43.70% |
| LOW risk | 7,513 | 3,381 | 45.00% |
| MEDIUM risk | 7,533 | 3,335 | 44.27% |
| NPA | 7,402 | 3,268 | 44.15% |
| DPD 0 | 2,685 | 1,220 | 45.44% |
| DPD 1–30 | 10,880 | 4,719 | 43.37% |
| DPD 31–60 | 5,514 | 2,524 | 45.77% |
| DPD 61–90 | 5,468 | 2,436 | 44.55% |
| DPD 91–180 | 5,453 | 2,385 | 43.74% |

Loan-type coverage ranges from about 43.52% (BNPL) to 45.28% (CONSUMER). Account-opening-year coverage is 44.36% for 2024 vintages and 44.19% for 2025 vintages.

These are modest, unadjusted differences using current snapshot attributes. DPD, risk and status can change over time; these segments are **not historical as-of features**. They suggest a need to standardize mix, but they do not show that mix caused the monthly trend, and they do not rule out Simpson's paradox.

## 5. How to test the requested statistical effects

- **Mix effects / Simpson's paradox:** construct month-by-month eligible-account denominators and a common fixed stratum definition. Calculate the same recovery outcome within DPD, risk, loan type and vintage strata, then reweight each month to a fixed pre-change portfolio mix. Compare the raw aggregate trend with the standardized trend. This cannot be reliably completed from a current-only DPD/risk snapshot.
- **Cohort effects:** define cohorts by account-opening vintage and by date of strategy assignment; give each cohort the same follow-up window (e.g., 30 days since assignment). Avoid comparing cohorts with different follow-up lengths.
- **Selection and survivorship bias:** denominator must include every eligible account assigned to a strategy, including accounts never contacted and accounts with zero payment. Do not use only successfully contacted accounts, kept promises, active cases or accounts still present after treatment.
- **Attribution-window bias:** predefine one primary attribution window, keep multi-touch channels visible, and report unattributed/ambiguous payments. Do not use “latest touch wins” as a default causal assignment. Validate with sensitivity windows (e.g., 7, 30 and 60 days) and ensure no look-ahead leakage.
- **Time-series effects:** use a consistent daily/weekly series, event completeness checks, time-zone normalization, weekday/holiday controls and enough pre/post observations. Eight-month data with only eight August days is insufficient for a reliable annual seasonality model or strong interrupted-time-series causal claim.
- **Correlation versus causation:** channel, vendor, calling time and agent comparisons are hypotheses until exposure assignment, denominators, identities and cost/hour inputs are reliable. A touch followed by a payment is association, not proof the touch caused the payment.

## 6. Counterfactual: “What if targeting had not changed?”

### Retrospective design: matched difference-in-differences

**Do not assign treatment by campaign version label alone.** Obtain (a) the approved effective date of the targeting change and (b) an immutable record of the accounts actually assigned to new vs legacy strategy. If these do not exist, no reliable retrospective causal estimate is available from the current data.

1. **Treatment group:** all eligible accounts assigned the new targeting policy at the documented cutover.
2. **Control group:** eligible accounts contemporaneously kept on legacy targeting; a randomized holdout is preferred. If not available, construct a matched/weighted comparison with common support and explicitly weaker assumptions.
3. **Time zero:** actual assignment timestamp, normalized to a canonical time zone.
4. **Primary outcome:** 30-day cumulative **net** collections per eligible account assigned, including zero for no payment. Deduplicate payment transactions, link reversals/refunds to their originals, and exclude only pre-specified valid exclusions. Until reversal links are dependable, report gross successful payments as a secondary proxy.
5. **Covariates measured before treatment:** DPD, risk, outstanding balance, loan type, account vintage, historical payments, contact attempts, prior PTP, and geography if identity resolution is repaired. Use agent, vendor and channel controls only after identity/time-zone checks.
6. **Estimator:** `DiD = (Treatment post − Treatment pre) − (Control post − Control pre)`, calculated on comparable account-level outcomes and equal observation windows.
7. **Assumptions:** parallel pre-trends; no spillover between groups; stable metric definitions; complete denominators; reliable treatment assignment and timestamps; no differential simultaneous intervention; adequate overlap between treatment/control.
8. **Validation:** plot pre-trends; run placebo dates; inspect an event study; test alternative 7/30/60-day windows; compare matched, weighted and raw estimates; report confidence intervals; pre-specify segment cuts and avoid controlling for post-treatment mediators.
9. **Uncertainty:** bootstrap at account level, or borrower level if borrower identity is repaired. Report point estimate and confidence interval, not a single precise-looking ROI number.

### Preferred prospective design: randomized pilot

Randomly assign eligible accounts (or borrower clusters after identity resolution) to new targeting versus business-as-usual, stratifying by pre-treatment DPD, risk, balance and loan type. Choose holdout size using a power calculation; keep all assigned accounts in the intent-to-treat denominator, including those never contacted. Pre-register the 30-day net-collection outcome, cost, complaints and operational guardrails. Scale only if incremental net recovery and ROI are positive with acceptable uncertainty.

## 7. Investment recommendation implication

The analysis supports **not committing the entire ₹10 crore based on the claimed +11% trend**. The current data does not establish reliable incremental net recovery, channel causality, cost per rupee or payback. Resolve identity, event-time and payment/reversal issues, then run a controlled pilot for the strongest feasible targeting intervention. A numeric expected ROI should be reported only when costs, reversals and the causal treatment effect are measured; otherwise show scenario ranges and label assumptions.

## 8. Production data needed

1. Exact targeting-strategy change log and account assignment history.
2. Historical daily eligible-portfolio snapshots with as-of DPD, risk, balance and status.
3. Borrower and agent master crosswalks with stable IDs, effective dates and history.
4. Canonical timezone/offset per event source, event time vs ingestion time, and late-arriving/backfill policy.
5. Reversal/refund-to-original-payment linkage; separate payment event ID, transaction ID and payment reference.
6. Campaign start/end definitions consistent with targeting and interaction logs.
7. Agent session hours, telephony vendor outcomes, operating costs, channel costs and client/language fields if those are real business dimensions.
8. A metric contract defining recovery amount, account denominator, attribution window, reversals, cutoffs and exclusions.

## Deliverable/use

The companion notebook `03_statistical_investigation.ipynb` reproduces the numeric checks from project-relative `dataset/*.csv` files and writes supporting CSVs to `outputs/`. It is intended to sit in `CredResolve/notebooks/`, with this report in `CredResolve/reports/`. Its outputs should be rerun after any changes to cleaning rules or source data.
