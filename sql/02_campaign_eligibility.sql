SELECT
    c.id AS campaign_id,
    c.name,
    c.parent_id,
    c.creation_status,
    c.processing_status,
    COUNT(cl.id) AS communication_rows
FROM campaign c
LEFT JOIN communication_log cl
    ON cl.communication_id = c.id
WHERE c.merchant_id = 501
GROUP BY
    c.id,
    c.name,
    c.parent_id,
    c.creation_status,
    c.processing_status
ORDER BY c.id;
