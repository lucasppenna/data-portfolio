-- Known data quality issue from week 1: 775 orders have no items.
-- This test intentionally documents that gap (expected FAIL until
-- the source is fixed or the exception is accepted).

select
    o.order_id,
    o.order_status
from {{ ref('stg_orders') }} o
left join {{ ref('stg_order_items') }} i
    on o.order_id = i.order_id
where i.order_id is null