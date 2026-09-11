# Reconciliation Bridge

**Target:** merchant 501, October 2026, Campaign communications (`communication_type = '2'`)

Finance reports a `target_base` of **22**.

## Reconciliation

| Step | Investigation / Adjustment | Result | Change | Reason |
|---:|---|---:|---:|---|
| 0 | Naive count of all October campaign send attempts | 30 | — | Starting point: count every matching communication-log row. |
| 1 | Exclude ineligible campaign sends | 26 | -4 | Reporting includes only campaigns whose creation workflow has cleared and whose processing is complete. |
| 2 | Apply distinct-customer counting across eligible campaign roots | 21 | -5 | Retry campaigns represent the same underlying communication; counting customers once across each retry chain gives 10 for the 9001 chain, 6 for standalone 9101, and 5 for the 9201 chain. |
| 3 | Apply standalone-campaign counting semantics | **22** | +1 | Campaign 9101 is standalone, so its seven send events count independently. Customer C20 appears twice and both events qualify. |

### Reconciliation path

**30 → 26 → 21 → 22**

The final `target_base` is **22**.

## Supporting Evidence

After campaign eligibility filtering, **26** October send attempts remain.

| Root Campaign | Type | Raw Attempts | Distinct Customers | Qualifying Sends |
|---:|---|---:|---:|---:|
| 9001 | Retry chain (`9001 → 9002 → 9003`) | 13 | 10 | 10 |
| 9101 | Standalone | 7 | 6 | 7 |
| 9201 | Retry chain (`9201 → 9202`) | 6 | 5 | 5 |
| **Total** | | **26** | | **22** |

### Campaign 9001 Retry Chain

Campaigns `9001 → 9002 → 9003` form a multi-level retry chain.

Across the three campaigns there are **13 send attempts** involving **10 distinct customers**. Because these campaigns represent repeated attempts within the same underlying communication, each customer is counted once across the complete chain.

**Qualifying sends: 10**

### Campaign 9201 Retry Chain

Campaigns `9201 → 9202` form a retry chain.

Across the two campaigns there are **6 send attempts** involving **5 distinct customers**. The retry attempt does not create a new underlying communication for reporting purposes.

**Qualifying sends: 5**

### Campaign 9101 Standalone

Campaign `9101` has no parent campaign and no child retry campaign, so it is a standalone communication.

It contains **7 send events** involving **6 distinct customers**. Customer `C20` appears twice.

For a standalone campaign, each send event is counted independently. Therefore both C20 events qualify.

**Qualifying sends: 7**

## Eligibility Finding

The naive query returns **30** October campaign send attempts.

Campaign `9004` contributes **4** of those rows, but its `creation_status` is `approval_awaiting`. The data dictionary states that a campaign is included in official reporting only when its creation workflow has cleared and its processing has completed.

Therefore, all four `9004` rows are excluded:

**30 − 4 = 26 eligible send attempts**

The remaining eligible campaigns are:

- `9001` — approved, processed
- `9002` — approved, processed
- `9003` — approved, processed
- `9101` — approved, processed
- `9201` — approved, processed
- `9202` — approved, processed

## Final Reconciliation

The investigation proceeds from the raw send count to the reporting metric:

1. **30** — all October campaign send attempts.
2. **26** — remove the four sends belonging to ineligible campaign `9004`.
3. **21** — diagnostic distinct-customer checkpoint across the three eligible reporting roots:
   - `9001 → 9002 → 9003` = 10
   - `9101` = 6
   - `9201 → 9202` = 5
4. **22** — restore standalone campaign `9101` to event-level counting:
   - `9101` has 7 send events rather than 6 distinct customers.
   - Difference: **+1**

Therefore:

**30 → 26 → 21 → 22**

**Final `target_base` = 22**

## Key Findings

The reconciliation depends on three separate reporting rules:

1. **Campaign eligibility is determined by campaign lifecycle status, not merely by the existence of send rows.** Campaign `9004` has communication-log rows, but its `creation_status = 'approval_awaiting'`, so those four rows are not reportable.

2. **Retry chains must be reconciled at the underlying-communication level.** `9001 → 9002 → 9003` and `9201 → 9202` are retry chains, so a customer reached through multiple attempts within the same chain counts once.

3. **Standalone campaigns use event-level counting.** Campaign `9101` is not part of a retry chain. Its seven send events therefore count separately, even though only six distinct customers appear.

A global `COUNT(DISTINCT customer_id)` would therefore be incorrect: it would reduce campaign `9101` from seven qualifying send events to six.

## Notable Data Observation

One detail that stood out was that communication-log rows can already exist for a campaign whose creation workflow is still `approval_awaiting`. This means the presence of a send event alone is not sufficient to determine reporting eligibility. I also found that repeated customers do not have one universal treatment: repeated customers across a retry chain are counted once, while repeated send events within a standalone campaign remain separate qualifying events. This distinction was essential to reconciling the reported number of **22**.

## Reproducibility

The SQL files preserve the investigation from the initial naive count through the final reconciliation.

- `sql/01_naive.sql` — initial send-attempt count
- `sql/02_campaign_eligibility.sql` — campaign lifecycle and row mapping
- `sql/03_excluded_campaign_rows.sql` — ineligible send-row count
- `sql/04_retry_investigation.sql` — campaign relationships and customer-level attempts
- `sql/05_campaign_customer_counts.sql` — per-campaign attempt and customer counts
- `sql/06_retry_chain_counts.sql` — recursive retry-chain analysis
- `sql/07_standalone_check.sql` — identification of genuinely standalone campaigns
- `sql/08_standalone_duplicates.sql` — investigation of repeated customers in the standalone campaign
- `sql/09_final_reconciliation.sql` — final `target_base` calculation
- `sql/10_final_validation.sql` — component-level validation of the final result

The final reconciliation query in `sql/09_final_reconciliation.sql` returns:

**22**

The component-level validation in `sql/10_final_validation.sql` confirms:

- `9001 → 9002 → 9003` = **10**
- `9101` = **7**
- `9201 → 9202` = **5**

Therefore:

**10 + 7 + 5 = 22**

## Conclusion

The Finance-reported `target_base` of **22** is reproducible from the raw SQLite data once campaign eligibility, retry-chain semantics, and standalone-campaign event semantics are applied in sequence.
