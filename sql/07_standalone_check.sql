SELECT
    c.id AS campaign_id,
    c.name,
    COUNT(*) AS send_attempts,
    COUNT(DISTINCT cl.customer_id) AS distinct_customers
FROM communication_log cl
JOIN campaign c
    ON c.id = cl.communication_id
WHERE cl.merchant_id = 501
  AND cl.communication_type = '2'
  AND cl.sent_time >= '2026-10-01'
  AND cl.sent_time < '2026-11-01'
  AND c.parent_id IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM campaign child
      WHERE child.parent_id = c.id
  )
  AND c.creation_status IN (
      'approved',
      'aborted',
      'resumed',
      'stopped'
  )
  AND c.processing_status = 'processed'
GROUP BY
    c.id,
    c.name
ORDER BY c.id;