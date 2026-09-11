# Comm-Log Send Reconciliation

## Xeno Data Analyst Internship — Take-Home Assignment

### Objective

Reproduce Finance's reported `target_base` of **22** for:

- **Merchant:** 501
- **Period:** October 2026
- **Communication type:** Campaign (`communication_type = '2'`)

The investigation starts from the raw `communication_log` data and reconciles the naive send count to the Finance-reported metric by applying the campaign eligibility, retry-chain, and standalone-campaign reporting rules defined in the assignment.

## Final Result

**Finance target:** `22`

**Reconciled target_base:** `22` ✅

### Reconciliation path

**30 → 26 → 21 → 22**

Where:

- **30** = naive count of all October campaign send attempts
- **26** = after excluding four sends belonging to ineligible campaign `9004`
- **21** = diagnostic distinct-customer checkpoint across the eligible reporting roots
- **22** = final result after applying standalone-campaign event-level counting to campaign `9101`
## Investigation Summary

The reconciliation was performed in stages so that each difference from the naive count could be explained and verified independently.

### 1. Start with the naive send count

The initial query counts every October 2026 Campaign communication-log row for merchant `501`.

Result: **30 send attempts**.

This is only the starting point because the raw log can contain sends belonging to campaigns that are not eligible for Finance reporting, as well as multiple attempts belonging to the same retry chain.

### 2. Apply campaign eligibility

Finance reporting includes a campaign only when:

- its creation workflow has reached a finalized state; and
- its processing workflow is complete.

The finalized creation states are:

- `approved`
- `aborted`
- `resumed`
- `stopped`

Campaign `9004`, `Diwali Cart Recovery - Retry C (pending)`, has `creation_status = 'approval_awaiting'`. Its four communication-log rows therefore do not contribute to the reported metric.

Result after eligibility filtering: **26 send attempts**.

### 3. Reconcile retry chains

Campaign relationships show two retry chains:

- `9001 → 9002 → 9003`
- `9201 → 9202`

A retry chain represents one underlying communication. Therefore, customers reached across the entire chain must be counted once rather than once per send attempt.

For the eligible retry chains:

- Root `9001`: **13 attempts → 10 distinct customers**
- Root `9201`: **6 attempts → 5 distinct customers**

This produces the diagnostic distinct-customer checkpoint of **21** when combined with standalone campaign `9101` using distinct-customer counting.

### 4. Apply standalone-campaign semantics

Campaign `9101`, `Diwali Flash Sale - Standalone`, is not part of a retry chain.

For a standalone campaign, each send event is an independent communication. Therefore, repeated targeting of the same customer does not get deduplicated.

Campaign `9101` has:

- **7 send events**
- **6 distinct customers**

Customer `C20` appears twice, and both send events count.

Replacing the standalone distinct-customer count of `6` with its event count of `7` changes the diagnostic **21** to the final Finance result of **22**.

## SQL Investigation

The SQL files in `sql/` document the reconciliation from the initial raw count through the final validation.

| File | Purpose |
|---|---|
| `01_naive.sql` | Counts all October Campaign send attempts for merchant `501`. |
| `02_campaign_eligibility.sql` | Inspects campaign lifecycle status and communication-row counts. |
| `03_excluded_campaign_rows.sql` | Identifies send rows belonging to campaigns that are not eligible for reporting. |
| `04_retry_investigation.sql` | Examines customer-level send attempts and delivery outcomes across eligible campaigns. |
| `05_campaign_customer_counts.sql` | Compares total send attempts with distinct customers for each campaign. |
| `06_retry_chain_counts.sql` | Rolls campaigns up to their root campaign and measures attempts and distinct customers across each chain. |
| `07_standalone_check.sql` | Examines root campaigns and compares send-event counts with distinct-customer counts. |
| `08_standalone_duplicates.sql` | Identifies customers with multiple send events in standalone campaign `9101`. |
| `09_final_reconciliation.sql` | Applies campaign eligibility, retry-chain deduplication, and standalone event-level counting to calculate the final `target_base`. |
| `10_final_validation.sql` | Provides campaign-level validation of the final qualifying-send counts. |

### Key validation results

The final eligible reporting population contains three reporting roots:

| Root campaign | Classification | Raw attempts | Distinct customers | Qualifying sends |
|---:|---|---:|---:|---:|
| `9001` | Retry chain (`9001 → 9002 → 9003`) | 13 | 10 | 10 |
| `9101` | Standalone | 7 | 6 | 7 |
| `9201` | Retry chain (`9201 → 9202`) | 6 | 5 | 5 |
| **Total** | | **26** | | **22** |

The final SQL query returns:

`22`

This matches Finance's reported `target_base`.

## Reconciliation Bridge

| Step | Investigation / Adjustment | Result | Change | Reason |
|---:|---|---:|---:|---|
| 0 | Naive count of all October Campaign send attempts | 30 | — | Counts every matching `communication_log` row. |
| 1 | Exclude ineligible campaign sends | 26 | -4 | Campaign `9004` is `approval_awaiting`, so its four send rows are excluded from Finance reporting. |
| 2 | Diagnostic distinct-customer checkpoint | 21 | -5 | Retry-chain customers are deduplicated across the underlying communication, while this checkpoint applies distinct-customer counting to each reporting root. |
| 3 | Apply standalone-campaign event counting | **22** | +1 | Campaign `9101` is standalone, so all seven send events count. `C20` appears twice and both events qualify. |

### Final reconciliation

**30 → 26 → 21 → 22**

The final `target_base` is **22**, matching Finance's reported value.

### Why the diagnostic checkpoint is 21

After eligibility filtering, the reporting roots contain:

- Retry chain `9001 → 9002 → 9003`: **10 distinct customers**
- Standalone campaign `9101`: **6 distinct customers**
- Retry chain `9201 → 9202`: **5 distinct customers**

Therefore:

**10 + 6 + 5 = 21**

The value **21** is a diagnostic checkpoint rather than the final metric because standalone campaigns follow different counting semantics.

### Why the final value is 22

Campaign `9101` is standalone and contains seven send events:

- `C20` appears twice.
- `C21` through `C25` appear once each.

Because standalone campaigns count independent send events, both `C20` events qualify.

Therefore the standalone contribution is **7**, not **6**:

**10 + 7 + 5 = 22**

This produces the Finance-reported `target_base`.

## Reproducibility

The analysis is designed to be reproducible from the SQLite database and the SQL files in this repository.

The repository contains:

- `data/comm_log.db` — source SQLite database provided for the exercise.
- `sql/` — SQL queries used to investigate and reconcile the metric.
- `analysis/reconciliation_bridge.md` — detailed reconciliation notes and supporting evidence.
- `inspect_data.py` — data inspection helper.
- `inspect_db.py` — database inspection helper.
- `inspect_schema.py` — schema inspection helper.
- `map_data.py` — data-mapping helper.
- `README.md` — summary of the investigation, methodology, and final result.

The SQL queries use SQLite-compatible syntax and apply the exercise's stated scope:

- merchant `501`
- October 2026
- `communication_type = '2'`

The final calculation is independently validated by `10_final_validation.sql`, which produces the campaign-level breakdown:

`9001 = 10`, `9101 = 7`, `9201 = 5`

and therefore:

**10 + 7 + 5 = 22**


