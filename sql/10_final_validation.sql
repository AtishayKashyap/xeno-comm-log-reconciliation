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

eligible_campaigns AS (
    SELECT
        c.id AS campaign_id,
        c.parent_id,
        cc.root_campaign_id
    FROM campaign c
    JOIN campaign_chain cc
        ON cc.campaign_id = c.id
    WHERE c.merchant_id = 501
      AND c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND c.processing_status = 'processed'
),

eligible_sends AS (
    SELECT
        cl.id AS send_id,
        cl.customer_id,
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
)

SELECT
    es.root_campaign_id,
    CASE
        WHEN rc.has_retry = 1 THEN 'retry_chain'
        ELSE 'standalone'
    END AS communication_type,
    COUNT(*) AS raw_attempts,
    COUNT(DISTINCT es.customer_id) AS distinct_customers,
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
ORDER BY es.root_campaign_id;
