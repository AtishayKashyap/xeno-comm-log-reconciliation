WITH RECURSIVE campaign_chain AS (
    SELECT
        id AS campaign_id,
        id AS root_campaign_id
    FROM campaign
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.id AS campaign_id,
        cc.root_campaign_id
    FROM campaign c
    JOIN campaign_chain cc
        ON c.parent_id = cc.campaign_id
),
eligible AS (
    SELECT
        cl.id,
        cl.communication_id,
        cl.customer_id,
        cc.root_campaign_id
    FROM communication_log cl
    JOIN campaign c
        ON c.id = cl.communication_id
    JOIN campaign_chain cc
        ON cc.campaign_id = c.id
    WHERE cl.merchant_id = 501
      AND cl.communication_type = '2'
      AND cl.sent_time >= '2026-10-01'
      AND cl.sent_time < '2026-11-01'
      AND c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND c.processing_status = 'processed'
)
SELECT
    root_campaign_id,
    COUNT(*) AS send_attempts,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM eligible
GROUP BY root_campaign_id
ORDER BY root_campaign_id;
