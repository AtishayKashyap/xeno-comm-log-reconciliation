-- Comm-Log Send Reconciliation
-- Target: merchant 501, October 2026, Campaign communications
--
-- Business rules:
-- 1. Only finalized + processed campaigns are reportable.
-- 2. Retry chains represent one underlying communication:
--    count each customer once across the entire chain.
-- 3. Standalone campaigns are independent communications:
--    count every send event, including repeated customers.

WITH RECURSIVE campaign_chain AS (

    -- Start each campaign with itself as its root.
    SELECT
        id AS campaign_id,
        id AS root_campaign_id
    FROM campaign
    WHERE parent_id IS NULL

    UNION ALL

    -- Follow parent -> child relationships through arbitrarily
    -- deep retry chains.
    SELECT
        c.id AS campaign_id,
        cc.root_campaign_id
    FROM campaign c
    JOIN campaign_chain cc
        ON c.parent_id = cc.campaign_id
),

eligible_campaigns AS (

    -- Apply Finance's campaign-level reporting eligibility.
    SELECT
        c.id AS campaign_id,
        c.parent_id,
        cc.root_campaign_id
    FROM campaign c
    JOIN campaign_chain cc
        ON cc.campaign_id = c.id
    WHERE c.merchant_id = 501
      AND c.creation_status IN (
          'approved',
          'aborted',
          'resumed',
          'stopped'
      )
      AND c.processing_status = 'processed'
),

eligible_sends AS (

    -- Restrict communication-log rows to the requested
    -- merchant, communication type, and October 2026 period.
    SELECT
        cl.id AS send_id,
        cl.customer_id,
        ec.campaign_id,
        ec.parent_id,
        ec.root_campaign_id
    FROM communication_log cl
    JOIN eligible_campaigns ec
        ON ec.campaign_id = cl.communication_id
    WHERE cl.merchant_id = 501
      AND cl.communication_type = '2'
      AND cl.sent_time >= '2026-10-01'
      AND cl.sent_time < '2026-11-01'
),

root_classification AS (

    -- Classify the communication using the complete campaign hierarchy,
    -- before applying reporting eligibility. This ensures that a root is
    -- considered a retry chain even if one of its retry campaigns is
    -- excluded from reporting.
    SELECT
        root_campaign_id,
        MAX(
            CASE
                WHEN campaign_id <> root_campaign_id THEN 1
                ELSE 0
            END
        ) AS has_retry
    FROM campaign_chain
    GROUP BY root_campaign_id
),

reconciled AS (

    -- Retry chains: distinct customers across the complete chain.
    -- Standalone campaigns: every send event counts independently.
    SELECT
        es.root_campaign_id,
        CASE
            WHEN rc.has_retry = 1
                THEN COUNT(DISTINCT es.customer_id)
            ELSE COUNT(*)
        END AS qualifying_sends
    FROM eligible_sends es
    JOIN root_classification rc
        ON rc.root_campaign_id = es.root_campaign_id
    GROUP BY
        es.root_campaign_id,
        rc.has_retry
)

SELECT
    SUM(qualifying_sends) AS target_base
FROM reconciled;