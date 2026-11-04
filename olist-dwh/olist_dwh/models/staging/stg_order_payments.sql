
-- stg_order_payments: staging model for the raw order_payments table
-- Goal: clean the source for mart-layer consumption
-- Steps:
--   1. Explicit select (column contract, not a mirror)
--   2. No casts: all types confirmed native via typeof
--      (VARCHAR for ids and type, BIGINT for sequential and installments, DOUBLE for value)
--   3. Composite key: order_id + payment_sequential (order_id alone is NOT unique)
--   4. Rounding is not applied here; it belongs to the mart layer
-- Source: order_payments table from the olist.dwh database



select
order_id,
payment_sequential,
payment_type,
payment_installments,
payment_value

from order_payments