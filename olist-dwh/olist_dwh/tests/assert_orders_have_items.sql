-- Known data quality issue from week 1: 3 orders in invoiced or shipped status have no items.
-- This test intentionally documents that gap (expected FAIL until
-- the source is fixed or the exception is accepted).

select
    o.order_id,
    o.order_status
from {{ ref('stg_orders') }} o
left join {{ ref('stg_order_items') }} i
    on o.order_id = i.order_id
where i.order_id is null
    and o.order_status in ('invoiced', 'shipped')