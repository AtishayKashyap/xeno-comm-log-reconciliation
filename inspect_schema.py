import sqlite3

con = sqlite3.connect(r"data\comm_log.db")

for table in ["campaign", "communication_log"]:
    print(f"\n=== {table} ===")
    columns = con.execute(f"PRAGMA table_info({table})").fetchall()
    for col in columns:
        print(col)

con.close()
