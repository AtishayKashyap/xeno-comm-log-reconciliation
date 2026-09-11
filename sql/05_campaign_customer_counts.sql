WITH eligible AS (
    SELECT
        cl.id,
        cl.communication_id,
        cl.customer_id
    FROM communication_log cl
    JOIN campaign c
        ON c.id = cl.communication_id
    WHERE cl.merchant_id = 501
      AND cl.communication_type = '2'
      AND cl.sent_time >= '2026-10-01'
      AND cl.sent_time < '2026-11-01'
      AND c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND c.processing_status = 'processed'
)
SELECT
    communication_id,
    COUNT(*) AS send_attempts,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM eligible
GROUP BY communication_id
ORDER BY communication_id;
