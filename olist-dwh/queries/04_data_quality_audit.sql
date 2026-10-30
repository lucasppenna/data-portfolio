
----=============================
----=====DATA QUALITY============
----=============================

-- CHECK: orders without order_items
-- 775 orphans total, but only 3 are true anomalies (invoiced/shipped
-- without items — ingestion failures). The rest are canceled/unavailable
-- orders that never reached item assignment: expected business behavior.

with missing as 

(
select
o.order_id,
o.order_status,
oit.order_id as missing_order

from orders o
left join order_items oit on oit.order_id = o.order_id
where oit.order_id is null

)
select
order_status,
count(distinct order_id) as total_missing

from missing
group by order_status
;

-- CHECK: orders without matching customer (result: 0 — relation intact)

select count(*) as orphan_count
from orders o
left join customers c on c.customer_id = o.customer_id
where c.customer_id is null;

--- CHECK: order_payment without orders

select count(*) as orphan_count
from order_payments op
left join orders o on op.order_id = o.order_id
where o.order_id is null;

---- CHECK : order_review without orders

select count(*) as orphan_count
from order_reviews ore
left join orders o on ore.order_id = o.order_id
where o.order_id is null;

----- CHECK: produtc null or without english_name

select
case when p.product_category_name is null then 'null_category'
    else 'no_translation' end as issue_type,
count(distinct p.product_id) as total_products

from products p
left join category_name cn on cn.product_category_name = p.product_category_name
where cn.product_category_name_english is null
group by 1
;


----==================================
----====UNION ALL CHECK'S=============
----==================================

with orphan_items as (
    select 'orders_without_items' as check_name, 
    count(*) as orphan_count
    from orders o
    left join order_items oi on oi.order_id = o.order_id
    where oi.order_id is null
),
orphan_customers as (
    select 'orders_without_customer' as check_name, 
    count(*) as orphan_count
    from orders o
    left join customers c on c.customer_id = o.customer_id
    where c.customer_id is null
),
orphan_payments as (
    select 'payments_without_order' as check_name, 
    count(*) as orphan_count
    from order_payments op
    left join orders o on o.order_id = op.order_id
    where o.order_id is null
),
orphan_reviews as (
    select 'reviews_without_order' as check_name, 
    count(*) as orphan_count
    from order_reviews ore
    left join orders o on o.order_id = ore.order_id
    where o.order_id is null
),
category_issues as (
    select 'products_without_translation' as check_name,
           count(distinct p.product_id) as orphan_count
    from products p
    left join category_name cn
        on cn.product_category_name = p.product_category_name
    where cn.product_category_name_english is null
),
all_checks as (
    select * from orphan_items
    union all select * from orphan_customers
    union all select * from orphan_payments
    union all select * from orphan_reviews
    union all select * from category_issues
)
select
    check_name,
    orphan_count,
    case
        when orphan_count = 0 then 'pass'
        when check_name = 'orders_without_items' then 'pass_with_notes'
        else 'review' end as status
from all_checks
order by orphan_count desc;