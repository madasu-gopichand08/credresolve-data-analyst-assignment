# CredResolve — Operational Driver Investigation

## Purpose and conclusion

The assignment asks for investigation of portfolio/DPD, client, geography, language, agent and tenure, campaign, channel, telephony vendor, calling time, attempt frequency and borrower segment. This report summarizes what the available operational logs support and—just as importantly—what they do not support.

**Conclusion:** these data support descriptive operational comparisons but do not establish a causal driver of the monthly gross-payment pattern. Agent and borrower identity conflicts, campaign-window mismatches, timestamp ambiguity and unmatched payment attribution block reliable driver rankings. Client and language fields are absent from the supplied schema. The investment recommendation remains to repair measurement and test borrower targeting through a controlled pilot, not to spend the full ₹10 crore based on apparent associations.

## Findings

### Calls and telephony vendors

- The raw calls table contains 91,350 rows and 90,000 distinct `call_id` values. There are **1,350 repeated call-ID groups**; 79 call IDs have conflicting core fields. For the descriptive vendor table, repeated IDs with consistent fields are represented once and conflicting IDs are excluded.
- Among the 89,921 canonicalized calls included in the comparison, the source-reported `ANSWERED` share is **19.87% overall**, ranging from **19.30% to 21.09% across vendor IDs**.
- This range is not evidence that one vendor is better. The same vendor name can be associated with multiple vendor IDs and different schema/timezone/status snapshots; there is no randomized assignment, cost data or confirmed RPC definition. Treat this as a diagnostic only.

### Calling time

After assuming that each `event_at` is a local wall-clock timestamp in its row's `timezone` and converting it to IST, `ANSWERED` share ranged from **19.32% to 20.41%** across five broad time bands. These are small descriptive differences, and the normalization depends on an assumption that must be confirmed with the source owner. Do not optimize calling windows from these figures until timestamp semantics, retries and comparable eligible-account denominators are validated.

### Attempt frequency

- `CONNECTED` share by attempt number ranged from **19.39% to 20.57%** for attempts 1–7; it does not decline or improve monotonically.
- Current-window account payment coverage ranged from **42.47% to 44.55%** across account attempt-count bands (1 attempt through 6+ attempts; 0 attempts: 43.72%).
- These are not causal estimates. Accounts that receive more attempts may already be harder to collect from, and the observed attempt window is not an assigned treatment. A touch is not necessarily a right-party contact and is not proof of recovery.

### SMS, WhatsApp and field visits

- SMS contains 45,000 rows and 45,000 unique event IDs. Its source event labels are `SENT`, `FAILED`, `DELIVERED` and `CLICKED`; the counts are broadly similar, but the supplied table does not define a common conversion denominator or link each event reliably to an incremental payment.
- WhatsApp contains 60,600 raw rows, 60,000 distinct event IDs and **600 repeated event-ID groups**. No core-field conflicts were found among those repeated IDs under the implemented comparison. Canonicalized event labels include `SENT`, `DELIVERED`, `READ`, `REPLIED`, `PAYMENT_CLICK` and `FAILED`. Do not compare raw click/reply counts directly with SMS counts as conversion rates.
- Field visits show 4,080 source-reported `PAID` outcomes among 25,000 visit rows (**16.32% of visit rows**). The rate varies only modestly across visit-type labels (about 16.01%–16.70%). These outcomes are not reconciled to canonical payments and do not estimate incremental recovery attributable to a visit.

### Campaigns and targeting

Across 45,000 targeting rows joined to campaign windows, **15,253** target dates fall before campaign start dates, **20,886** fall after campaign end dates, and only **8,861** lie within active calendar dates. This is a date-level diagnostic; event time zones and late-arriving data still need reconciliation. `legacy`, `v1`, `v2` and `v3` labels overlap across months and do not identify a single reliable global cutover date. Do not use “latest touch wins” or campaign version alone as causal attribution.

### PTP maturity

There are **1,242 promises with promised dates after 8 August 2026**, beyond the observed payment window. These are right-censored for this analysis. Among matured promises that are labelled `KEPT` or `BROKEN`, the source-status proxy is 4,180 / (4,180 + 4,220) = **49.76%**. This is *not* an official PTP kept rate: it excludes `OPEN` and `CANCELLED`, relies on source-reported status, and the source also marks some future-due promises as `KEPT` or `BROKEN`. Reconcile status effective time, maturity rules and payment linkage before publishing the metric.

### Agent tenure, geography, client and language

- The agents table has 30,000 rows but 1,000 distinct `agent_id` values. **All 1,000 IDs have multiple employee codes, names, vendor IDs, joined dates and team values.** Agent-level performance and tenure comparisons are not defensible until a stable historical identity crosswalk is obtained.
- Borrower identity conflicts also undermine geographic joins: **8,159 borrower IDs have multiple city values** and **8,070 have multiple state values**. There are 455 account rows with missing borrower IDs and 2,458 with a non-null borrower ID absent from the borrower table. Field-visit coordinates exist, but 24,969 distinct coordinate pairs after rounding to two decimals occur across 25,000 visit rows; coordinates should not be treated as validated geographic regions without a reliable geospatial map/region field.
- No explicit client or language column was found in the supplied tables. These requested dimensions cannot be tested from this dataset.
- Portfolio mix / DPD / borrower-risk / loan-type comparisons are covered in `03_statistical_investigation.ipynb` and its report. Those comparisons use current snapshot attributes and are descriptive, not historical mix-standardized causal effects.

## Evidence classification

| Dimension | What is supported | Evidence class |
|---|---|---|
| Vendor answer-share differences | Small source-reported differences across vendor IDs; definitions and assignment are not controlled | Correlation / diagnostic |
| Calling time | Small differences after an assumed timezone normalization | Hypothesis until timestamp semantics are verified |
| Attempt frequency | Connection and account-payment-coverage differences are non-monotonic and confounded | Correlation only |
| Digital/field outcomes | Counts and source-labelled outcomes can be summarized; no validated common conversion/attribution model | Descriptive fact only |
| Campaign alignment | Most targeting rows fall outside campaign active calendar dates | Strong evidence of attribution/data-quality risk |
| Agent tenure | Identity key conflicts make tenure assignment unreliable | Fact about data fitness; performance not estimable |
| Geography | City/state values conflict for many borrower IDs; coordinate regions are not validated | Fact about data fitness; geographic effects not estimable |
| Client/language | Required fields not present | Not testable |

## Investment and next data needed

Do not select a channel or vendor just because a raw rate appears slightly higher. First obtain:

1. Stable, effective-dated agent and borrower identity crosswalks.
2. Approved strategy-change date and immutable per-account assignment history.
3. Timestamp semantics, timezone rules, ingestion time and late-arrival policy for each event source.
4. Campaign-window definitions reconciled to targeting and interactions.
5. Canonical payment-to-reversal/refund links and a fixed eligible-account denominator.
6. Reliable costs, agent-hours, client and language fields if those dimensions are real business variables.

Then run a pre-registered randomized holdout or a defensible matched design: assign eligible accounts to better targeting versus business-as-usual, keep every assigned account (including zero-contact accounts) in the intent-to-treat denominator, use 30-day net collections per eligible account as the primary outcome, and report incremental net recovery, full cost, ROI and uncertainty. Until then, no credible operational driver or ROI for the ₹10 crore is established.

## Reproducibility

Run `notebooks/04_operational_driver_analysis.ipynb` from the existing `CredResolve` project. It reads source CSVs from `dataset/` using project-relative paths and writes the supporting CSVs under `outputs/`. It preserves source tables and does not modify raw files. Output labels explicitly call out descriptive, assumed or unverified measures.
