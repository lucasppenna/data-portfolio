# run_query.py — run a .sql file against olist.dwh, printing every result
# Usage: python run_query.py queries/01_delivery_performance.sql
import duckdb

con = duckdb.connect("olist.dwh")

with open("queries/01_delivery_performance.sql", encoding="utf-8") as f:
    script = f.read()

for chunk in script.split(";"):
    query = chunk.strip()
    if query:
        print(con.sql(query))

con.close()
