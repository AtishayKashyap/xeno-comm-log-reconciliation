import sqlite3

con = sqlite3.connect(r"data\comm_log.db")

queries = {
    "row_counts": """
        SELECT
            (SELECT COUNT(*) FROM campaign) AS campaign_rows,
            (SELECT COUNT(*) FROM communication_log) AS communication_rows
    """,

    "campaign_sample": """
        SELECT id, merchant_id, parent_id, name, creation_status, processing_status
        FROM campaign
        ORDER BY id
        LIMIT 15
    """,

    "communication_sample": """
        SELECT id, merchant_id, communication_id, customer_id,
               communication_type, delivery_status,
               sent_time, scheduled_time, credit_used, channel
        FROM communication_log
        ORDER BY id
        LIMIT 15
    """,

    "communication_types": """
        SELECT communication_type, COUNT(*) AS rows
        FROM communication_log
        GROUP BY communication_type
        ORDER BY rows DESC
    """
}

for name, sql in queries.items():
    print(f"\n=== {name} ===")
    for row in con.execute(sql):
        print(row)

con.close()
