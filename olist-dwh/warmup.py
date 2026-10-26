import duckdb

con = duckdb.connect()

print(con.sql("""
    SELECT COUNT(*) AS total_pedidos
    FROM read_csv_auto('data/olist_orders_dataset.csv')
"""))

print(con.sql("""
    SELECT * FROM read_csv_auto('data/olist_orders_dataset.csv')
    LIMIT 5
"""))
