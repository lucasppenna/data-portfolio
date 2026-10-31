-- stg_orders: staging model for the raw orders table
-- Goal: clean the source for mart-layer consumption
-- Steps:
--   1. Explicit select (column contract, not a mirror)
--   2. Cast dates VARCHAR -> TIMESTAMP via try_cast (confirmed via typeof)
--   3. Keep order_status as-is (validation comes later via dbt test)
-- Source: orders table from the olist.dwh database

select
order_id,
customer_id,
order_status,
TRY_CAST(order_purchase_timestamp as TIMESTAMP) as order_purchase_timestamp,
TRY_CAST(order_approved_at as TIMESTAMP) as order_approved_at,
TRY_CAST(order_delivered_carrier_date as TIMESTAMP) as order_delivered_carrier_date,
TRY_CAST(order_delivered_customer_date as TIMESTAMP) as order_delivered_customer_date,
TRY_CAST(order_estimated_delivery_date as TIMESTAMP) as order_estimated_delivery_date


from orders