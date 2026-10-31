-- stg_order_items: staging model for the raw order_items table
-- Goal: clean the source for mart-layer consumption
-- Steps:
--   1. Explicit select (column contract, not a mirror)
--   2. No casts: all types confirmed native via typeof
--      (BIGINT for item id, DOUBLE for prices, TIMESTAMP for dates)
--   3. Composite key: order_id + order_item_id (order_id alone is NOT unique)
-- Source: order_items table from the olist.dwh database

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
from order_items
