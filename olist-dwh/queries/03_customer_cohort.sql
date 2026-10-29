-- ============================================================
-- Day 4 — Customer Cohort Analysis
-- Q1: retention by monthly cohort (first order -> recurrence)
-- ============================================================
-- TODO: probe — how many customer_unique_id have 2+ customer_id?

select
c.customer_unique_id,
count(distinct c.customer_id) as qtde_customer

from orders o
left join customers c on c.customer_id = o.customer_id

group by all

having qtde_customer > 1
order by qtde_customer desc
;

-- CTE 1: first order per customer_unique_id
-- CTE 2: every order classified as first vs repeat
-- final: cohort_month | months_since_first_order | active_customers | retention_pct

with first_order as

(
   select
c.customer_unique_id,
min(o.order_purchase_timestamp) as first_order_ts
from orders o
left join customers c on c.customer_id = o.customer_id
where o.order_status ='delivered'
group by all

), order_classified as 
(
    select 
    date_trunc('month', o.order_purchase_timestamp) as data_month,
    o.order_id,
    c.customer_unique_id,
    f.first_order_ts,
    date_diff('month', f.first_order_ts, o.order_purchase_timestamp) as months_since_first_order,
    case when o.order_purchase_timestamp = f.first_order_ts
     then 'first' else 'repeat' end as classified

from orders o
left join customers c on c.customer_id = o.customer_id
left join first_order f on f.customer_unique_id = c.customer_unique_id
where o.order_status ='delivered'

), cohort as 

(
    select
        date_trunc('month', first_order_ts) as cohort_month,
        count(*) as cohort_customers
    from first_order
    group by date_trunc('month', first_order_ts)
)
select
    cs.cohort_month,
    oc.months_since_first_order,
    count(distinct oc.customer_unique_id) as active_customers,
    round(count(distinct oc.customer_unique_id) * 100.0 / cs.cohort_customers, 2) as retention_pct
from order_classified oc
left join cohort cs
    on cs.cohort_month = date_trunc('month', oc.first_order_ts)

group by cs.cohort_month, cs.cohort_customers, oc.months_since_first_order
order by cs.cohort_month, oc.months_since_first_order;



-- ============================================================
-- Q2 (challenge) — New vs Returning revenue by month
-- ============================================================

with first_order1 as

(
   select
c.customer_unique_id,
min(o.order_purchase_timestamp) as first_order_ts

from orders o
left join customers c on c.customer_id = o.customer_id
where o.order_status ='delivered'
group by all

), order_classified as 
(
    select 
    date_trunc('month', o.order_purchase_timestamp) as data_month,
    case when o.order_purchase_timestamp = f.first_order_ts
     then 'first' else 'repeat' end as classified,
    op.payment_value

from orders o
left join customers c on c.customer_id = o.customer_id
left join first_order1 f on f.customer_unique_id = c.customer_unique_id
left join order_payments op on op.order_id = o.order_id
where o.order_status ='delivered'

)

select
data_month,
classified,
round(sum(payment_value),2) as revenue

from order_classified

group by all
order by data_month;
