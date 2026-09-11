SELECT
    customer_id,
    COUNT(*) AS send_events
FROM communication_log cl
JOIN campaign c
    ON c.id = cl.communication_id
WHERE cl.merchant_id = 501
  AND cl.communication_type = '2'
  AND cl.sent_time >= '2026-10-01'
  AND cl.sent_time < '2026-11-01'
  AND c.id = 9101
  AND c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
  AND c.processing_status = 'processed'
GROUP BY customer_id
HAVING COUNT(*) > 1;
