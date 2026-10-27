-- ============================================================
-- Day 2 — Delivery Performance
-- Q1: Top 10 states with the slowest average delivery time
-- ============================================================
-- TODO: join orders -> customers (relation documented in the README)
-- TODO: keep only delivered orders (be ready to justify why)
-- TODO: delivery time = date_diff('day', purchase_ts, delivered_ts)
--       -> confirm the real column names in the CSV header
-- TODO: exclude states with fewer than 50 delivered orders (HAVING)
-- TODO: round the average to 2 decimals, sort worst -> best, LIMIT 10

select
c.customer_state,
count(o.order_id) as total_orders,
round(avg(date_diff('day', o.order_purchase_timestamp, o.order_delivered_customer_date)),2) as avg_delivery_days

from orders o
left join customers c 
on c.customer_id = o.customer_id

where o.order_status = 'delivered'
group by c.customer_state

HAVING total_orders >= 50
order by avg_delivery_days desc
limit 10;

-- ============================================================
-- Q2 (challenge) — Delay rate by state, top 5
-- ============================================================
-- TODO: per order: was it delivered AFTER the estimated date?
-- TODO: aggregate to % of late orders per state
-- TODO: sort, take top 5

select
----o.order_id,
c.customer_state,
count(o.order_id) as total_orders,
round(avg(case when o.order_delivered_customer_date > o.order_estimated_delivery_date 
    then 1 else 0 end) * 100, 2) as delay_rate_pct

from orders o
left join customers c 
on c.customer_id = o.customer_id
where o.order_status = 'delivered'

group by c.customer_state

HAVING total_orders >= 50
order by delay_rate_pct desc
limit 5;