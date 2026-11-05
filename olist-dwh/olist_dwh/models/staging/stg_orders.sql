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
{{ safe_timestamp('order_purchase_timestamp') }} as order_purchase_timestamp,
{{ safe_timestamp('order_approved_at') }} as order_approved_at,
{{ safe_timestamp('order_delivered_carrier_date') }} as order_delivered_carrier_date,
{{ safe_timestamp('order_delivered_customer_date') }} as order_delivered_customer_date,
{{ safe_timestamp('order_estimated_delivery_date') }} as order_estimated_delivery_date


from orders