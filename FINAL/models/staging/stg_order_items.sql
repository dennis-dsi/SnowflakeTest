-- Tag 1: discount_net ist der gesamte Rabatt einer Position.
select
    order_item_id,
    order_id,
    line_number,
    product_id,
    quantity,
    unit_price_net,
    discount_net,
    tax_rate,
    unit_cost_net_at_order,
    updated_at
from {{ source('erp', 'order_items') }}
