-- Composite key uniqueness: (order_id, order_item_id) must be unique.
-- order_id alone is NOT unique (one order = multiple items),
-- so the generic `unique` test cannot be used on it directly.

select
    order_id,
    order_item_id,
    count(*) as occurrences
from {{ ref('stg_order_items') }}
group by order_id, order_item_id
having count(*) > 1 