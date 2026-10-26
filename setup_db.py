import duckdb

con = duckdb.connect("olist.dwh")

tables = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_orders_dataset.csv": "orders",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "category_name"
}

for filename, table_name in tables.items():
    con.sql(f"""
        CREATE OR REPLACE TABLE {table_name} AS
        SELECT *
        FROM read_csv_auto('data/{filename}')
    """)
    count = con.sql(f"select count(*) from {table_name}").fetchall()[0][0]
    print(f"{table_name}: {count} linhas") 



