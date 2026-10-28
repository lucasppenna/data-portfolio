-- ============================================================
-- Day 3 — Revenue Analytics
-- Q1: Top 10 states by total revenue, with rank and % of total
-- ============================================================
-- TODO: join order_payments -> orders -> customers
--       (payment_value lives in order_payments; state in customers)
-- TODO: keep only delivered orders (same justification as Day 2)
-- TODO: revenue per state = sum(payment_value)
-- TODO: rank states with a window function
--       -> decide: row_number() vs rank() vs dense_rank()?
--          (hint: what happens if two states tie? which behavior
--           does the business question want?)
-- TODO: % of total revenue with sum(...) over ()
--       -> the denominator must be the NATIONAL total,
--          not the per-state total
-- TODO: round the % to 2 decimals, sort by revenue desc, LIMIT 10
--       -> decide: filter top 10 AFTER ranking (subquery/CTE?)
--          because window functions run AFTER aggregation

with state as 
(
select
c.customer_state,
round(sum(op.payment_value),2) as revenue

from order_payments op 
left join orders o on o.order_id = op.order_id 
left join customers c on c.customer_id = o.customer_id

where o.order_status = 'delivered'
group by c.customer_state

)
select
customer_state,
revenue as revenue_state,
row_number() over(order by revenue desc ) as row_numb,
round(revenue *100 / sum(revenue) over(),2) as pct_total_revenue

from state

order by revenue desc
limit 10;


---/*select
 ---   order_id,
---    count(*) as n_payments,
---    sum(payment_value) as total_paid
---from order_payments
---group by order_id
---having count(*) > 1
---limit 5;
---*/

-- ============================================================
-- Q2 (challenge) — Monthly revenue trend with MoM delta
-- ============================================================
-- TODO: truncate order_purchase_timestamp to month
--       (probe first: date_trunc('month', ...) in DuckDB)
-- TODO: revenue per month, sorted chronologically
-- TODO: lag() to bring the previous month's revenue to the same row
-- TODO: MoM % delta — decide the edge case:
--       first month has no previous -> NULL, 0, or omit?
--       (hint: dividing by NULL gives NULL; dividing by 0 explodes)
-- TODO: comment (in English) what the last months of the series show


with month_rev as
(
select
date_trunc('month', o.order_purchase_timestamp) as date_month,
round(sum(op.payment_value),2) as revenue

from order_payments op 
left join orders o on o.order_id = op.order_id 
left join customers c on c.customer_id = o.customer_id

where o.order_status = 'delivered'
group by date_trunc('month', o.order_purchase_timestamp)

)
select
date_month,
revenue,
lag(revenue) over(order by date_month) as last_month,
round(
    (revenue - lag(revenue) over(order by date_month)) /
lag(revenue) over(order by date_month) 
* 100 ,2) as MoM_delta

from month_rev
order by date_month desc
limit 10;

-- Note: the last months of the series (Sep-Oct 2018) show a sharp
-- revenue drop because the dataset ends mid-October 2018 — these
-- months are partial, not a real decline.