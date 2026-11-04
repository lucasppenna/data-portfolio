

-- ticket_evolution_yoy: monthly average ticket per paid order, year over year
-- Goal: measure how the average paid order value changes from month to month,
--   compared with the same month of the previous year
-- Steps:
--   1. Aggregate paid orders (flag_total_payment = 'ok') by month: sum of payment_value, order count
--   2. Compute ticket_medio = payment_value / orders for each month
--   3. Left join the monthly series with itself on (month - 12 months), so each month
--      finds its same-month-last-year row; a missing month becomes null, nothing shifts
--   4. Keep only months with at least 770 paid orders, in both the month and the prior year
-- Decisions:
--   - Threshold of 770 orders per month: derived from the standard error of the mean
--     (stddev of payment_value ~222; 5% of ~160 gives n >= (222 / 8)^2 ~ 770).
--     The rule was set before looking at the results, and applied to both months of each comparison
--   - Filter applied after the join, not with lag(): a row-based lag would shift months
--     when a month is missing from the series
--   - Analysis only: this query materializes nothing and is read by hand or by a dashboard
-- Source: fct_orders



with pay_orders as (
   select
date_trunc('month', order_purchase_timestamp) as month_order_purchase,
sum(payment_value) as payment_value_month,
count(order_id) as total_orders

from {{ ref('fct_orders') }}
where flag_total_payment = 'ok'

group by date_trunc('month', order_purchase_timestamp)
),
monthly as (
    select
        month_order_purchase,
        total_orders,
        round(payment_value_month / total_orders, 2) as ticket_medio
    from pay_orders
),
yoy as (
    select
        cur.month_order_purchase,
        cur.total_orders,
        cur.ticket_medio,
        prev.ticket_medio as ticket_prev_year,
        prev.total_orders as total_orders_prev_year
    from monthly cur
    left join monthly prev
        on prev.month_order_purchase = cur.month_order_purchase - interval 12 month
)
select
    month_order_purchase,
    total_orders,
    ticket_medio,
    ticket_prev_year,
    total_orders_prev_year,
    round((ticket_medio / ticket_prev_year - 1) * 100, 2) as yoy_pct_ticket,
    round((total_orders / total_orders_prev_year - 1) * 100, 2) as yoy_pct_total
from yoy
where total_orders >= 770
and total_orders_prev_year >= 770
order by month_order_purchase