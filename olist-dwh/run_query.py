# run_query.py — run a .sql file against olist.dwh, printing every result
# Usage: python run_query.py queries/01_delivery_performance.sql
import sys
import duckdb

path = sys.argv[1] if len(sys.argv) > 1 else "queries/01_delivery_performance.sql"

con = duckdb.connect("olist.dwh")

with open(path, encoding="utf-8") as f:
    script = f.read()

# strip full-line comments BEFORE splitting:
# a ';' inside a comment would break the naive split
lines = [line for line in script.splitlines()
         if not line.strip().startswith("--")]
script_no_comments = "\n".join(lines)

for chunk in script_no_comments.split(";"):
    query = chunk.strip()
    if query:
        print(con.sql(query))

con.close()