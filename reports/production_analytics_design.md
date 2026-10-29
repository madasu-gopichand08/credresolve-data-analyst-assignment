# CredResolve Production Analytics Design

## Purpose and scope

This design describes how the current analytical workflow could be operated reliably as a daily production system. The diagram is a proposed architecture, not a claim that orchestration, alerting, or all layers have already been implemented.

## Data flow

1. **Raw** — retain the delivered source extracts as immutable, access-controlled snapshots. Record source name, file/batch ID, ingestion timestamp, schema version, and row count. Do not overwrite raw evidence during cleaning.
2. **Staging** — standardize column names and types, normalize status labels, preserve source identifiers, and keep both event time and ingestion time. Source schema changes should be detected rather than silently accepted.
3. **Clean** — apply documented, version-controlled rules for key validity, duplicate handling, timestamps, amounts, and referential integrity. Send missing-key or conflicting records to quarantine/review tables; retain the reason and original row. Never deduplicate only on a reused transaction reference.
4. **Golden** — resolve canonical account, borrower, payment, agent, campaign, and event identities using explicit precedence rules. Store the source IDs and rule used for each mapping. Ambiguous identity matches remain unresolved rather than being guessed.
5. **Feature** — create analytical attributes such as DPD band, borrower segment, client, geography, language, agent tenure, campaign, channel, local calling hour, and monthly cohort. Keep the feature's effective date so historical comparisons do not accidentally use today's state.
6. **Metrics** — centralize versioned metric definitions and publish consistent daily/monthly aggregates. Dashboard and memo should use the same definitions and date windows.
7. **Dashboard** — show trends, denominators, data freshness, missing/late data warnings, and definitions in one screen. Label gross successful-payment amount separately from net recovery.

## Data contracts and primary keys

- Define required columns, expected data types, accepted status values, and nullability per source.
- Validate primary keys where they are expected: `account_id`, `payment_id`, `call_id`, `sms_event_id`, and `whatsapp_event_id`. Where duplicates exist in source feeds, retain duplicate-group diagnostics before choosing a canonical record.
- Do not assume a borrower ID uniquely identifies one person until entity conflicts are resolved. The supplied borrower table has repeated IDs with inconsistent records, and account rows include missing borrower references.
- Prefer stable source IDs plus source-system namespace. A transaction reference alone is not a safe payment key in this dataset because references are reused.

## Metric definitions to version

- **Gross successful payments:** sum of canonical payment amounts whose accepted status is `SUCCESS` in the selected event-time window. This is the metric currently measured; it is not net recovery.
- **Net recovery:** successful cash received minus linked reversals/refunds and any explicitly defined adjustments, attributed to the correct account and event window. Do not publish it as reliable until reversal linkage and payment attribution have been validated.
- **Account payment coverage:** distinct eligible accounts with at least one successful payment divided by all eligible accounts in the same fixed cohort/window. The current 44.28% figure is account payment coverage under the present account population, not a recovery rate.
- **Contact rate / RPC / PTP / PTP kept rate:** define each numerator, denominator, unique-entity grain, attribution window and treatment of retries before using it. A contact rate should not count duplicated attempts as new contacts; RPC should require a validated right-party contact disposition; kept PTP should be measured only after the promise due window has elapsed.
- **Recovery per account / agent-hour and cost per rupee recovered:** require a stable eligible-account denominator, reliable session/agent-hour data, and channel/agent cost data. Do not estimate ROI where cost or net-recovery inputs are absent.

## Incremental processing, late arrivals and backfills

- Use an ingestion watermark with an overlapping lookback window; make every load idempotent using stable source keys and versioned upserts.
- Track event time separately from ingestion time. Do not drop late-arriving events just because their event date is older than the latest batch.
- Reprocess the affected event-date partitions when late data, source corrections, mapping changes or a cleaning-rule update changes prior periods.
- A backfill must record its run ID, rule version, input snapshot, impacted dates, row-count deltas, and metric deltas. Compare the result with the preceding published version before replacing it.

## Data quality, lineage and monitoring

- Run checks at each layer: schema drift, duplicate key groups, null primary keys, invalid numeric/date values, unexpected statuses, foreign-key coverage, negative or implausible amounts, and row-count/reconciliation deltas.
- Quarantine failed records with a machine-readable reason; retain them for review instead of silently discarding them.
- Store lineage from source batch through transformation version, canonical record, metric calculation and dashboard refresh.
- Monitor source freshness, row volume, duplicate rate, late-arrival rate, rejection rate, pipeline failures and unusual metric movement. Use configurable thresholds and notify an owner; investigate before labelling a change as business improvement.
- Record data-quality status and last successful refresh on the CEO dashboard.

## Analytical safeguards

- Compare like-for-like periods and cohorts. August 2026 data currently ends on August 8 and must not be compared directly with a full month.
- Segment comparisons by relevant portfolio dimensions and report denominator changes to reduce mix and survivorship bias.
- Distinguish facts from correlation and hypotheses. Use a randomized holdout or a defensible quasi-experimental design to estimate targeting impact; document treatment/control assignment and confounders.
- Do not claim the reported 11% recovery improvement is validated from the current gross-payment series: January–July gross successful amounts are approximately flat. Do not provide an ROI estimate without incremental net recovery and cost assumptions.

## Current implementation boundary

The existing project has MySQL raw tables, cleaned account/payment tables, a Golden Dataset, data-quality queries, KPI views, monthly trends, notebooks and a dashboard. The orchestration, contracts enforcement, quarantine workflow, lineage tracking, monitoring and backfill controls described above are proposed production requirements, not all implemented capabilities.
