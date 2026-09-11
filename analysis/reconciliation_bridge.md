# Reconciliation Analysis & Supporting Evidence

This document provides the detailed step-by-step mathematical breakdown and evidence supporting the final `target_base` of **22**. For the executive summary and high-level reconciliation bridge, please see the `README.md`.

## 1. Eligibility Finding

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

## 2. Supporting Evidence: Campaign-by-Campaign Breakdown

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

## 3. Key Findings (Business Rules Applied)

The reconciliation depends on three separate reporting rules:

1. **Campaign eligibility is determined by campaign lifecycle status, not merely by the existence of send rows.** Campaign `9004` has communication-log rows, but its `creation_status = 'approval_awaiting'`, so those four rows are not reportable.
2. **Retry chains must be reconciled at the underlying-communication level.** `9001 → 9002 → 9003` and `9201 → 9202` are retry chains, so a customer reached through multiple attempts within the same chain counts once.
3. **Standalone campaigns use event-level counting.** Campaign `9101` is not part of a retry chain. Its seven send events therefore count separately, even though only six distinct customers appear.

A global `COUNT(DISTINCT customer_id)` would therefore be incorrect: it would reduce campaign `9101` from seven qualifying send events to six.