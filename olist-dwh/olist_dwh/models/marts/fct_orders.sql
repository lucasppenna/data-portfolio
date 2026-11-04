{{ config(materialized='table') }}

-- fct_orders: fact table with one row per order
-- Goal: consolidate order, item and payment metrics into one row per order_id
-- Steps:
--   1. Aggregate payments by order_id (sum, row count, classification flag)
--   2. Aggregate items by order_id (count, price and freight sums)
--   3. Left join both aggregates to stg_orders, so no order is lost
--   4. Zero-fill item and payment totals for orders without records
--   5. Flag orders invoiced or shipped with no items (missing items anomaly)
-- Decisions:
--   - Materialized as a table: read-heavy mart with aggregations
--   - Payment totals rounded here, after summing, not per row
--   - Payment classification in flag_total_payment: no_payment, zero_payment, ok
-- Source: stg_orders, stg_order_items, stg_order_payments

with orders as (
    select
        order_id,
        order_status,
        order_purchase_timestamp
    from {{ ref('stg_orders') }}
),

payments as (
    select
        order_id,
        count(payment_sequential) as payment_count,
        round(sum(payment_value), 2) as payment_value
    from {{ ref('stg_order_payments') }}
    group by order_id
),

items as (
    select
        order_id,
        count(order_item_id) as items_count,
        round(sum(price), 2) as items_price,
        round(sum(freight_value), 2) as items_freight
    from {{ ref('stg_order_items') }}
    group by order_id
),

orders_with_payments as (
    select
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        p.payment_value,
        case
            when p.order_id is null then 'no_payment'
            when p.payment_value = 0 then 'zero_payment'
            else 'ok'
        end as flag_total_payment
    from orders o
    left join payments p on p.order_id = o.order_id
)

select
    owp.order_id,
    owp.order_status,
    owp.order_purchase_timestamp,
    owp.flag_total_payment,
    coalesce(owp.payment_value, 0) as payment_value,
    coalesce(i.items_count, 0) as items_count,
    coalesce(i.items_price, 0) as items_price,
    coalesce(i.items_freight, 0) as items_freight,
    case
        when i.order_id is null
            and owp.order_status in ('invoiced', 'shipped') then true
        else false
    end as flag_missing_items_anomaly
from orders_with_payments owp
left join items i on i.order_id = owp.order_id