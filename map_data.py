import sqlite3

con = sqlite3.connect(r"data\comm_log.db")

query = """
SELECT
    c.id AS campaign_id,
    c.parent_id,
    c.name,
    c.creation_status,
    c.processing_status,
    COUNT(cl.id) AS communication_rows
FROM campaign c
LEFT JOIN communication_log cl
    ON cl.communication_id = c.id
GROUP BY
    c.id,
    c.parent_id,
    c.name,
    c.creation_status,
    c.processing_status
ORDER BY c.id;
"""

print("=== CAMPAIGN ? COMMUNICATION MAPPING ===")

for row in con.execute(query):
    print(row)

print("\n=== ALL COMMUNICATION LOG ROWS ===")

query2 = """
SELECT
    cl.id,
    cl.communication_id,
    cl.customer_id,
    cl.delivery_status,
    cl.sent_time,
    cl.scheduled_time,
    cl.credit_used,
    cl.channel,
    c.name,
    c.parent_id,
    c.creation_status,
    c.processing_status
FROM communication_log cl
LEFT JOIN campaign c
    ON c.id = cl.communication_id
ORDER BY cl.id;
"""

for row in con.execute(query2):
    print(row)

con.close()
