import sqlite3

con = sqlite3.connect(r"data\comm_log.db")

tables = con.execute("""
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
    ORDER BY name
""").fetchall()

print("TABLES:")
for table in tables:
    print("-", table[0])

con.close()
