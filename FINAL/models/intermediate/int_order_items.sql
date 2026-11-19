select
    i.order_item_id,
    i.order_id,
    i.product_id,
    o.customer_id,
    o.ordered_at,
    o.order_date,
    o.order_status,
    o.currency_code,
    i.quantity,
    i.quantity * i.unit_price_net - i.discount_net as line_net_amount,
    i.quantity * i.unit_cost_net_at_order as line_cost_amount
from {{ ref('stg_order_items') }} as i
join {{ ref('stg_orders') }} as o
    on i.order_id = o.order_id
