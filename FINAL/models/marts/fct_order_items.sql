select
    i.order_item_id,
    i.order_id,
    c.customer_version_key,
    p.product_id,
    i.order_date,
    i.order_status,
    i.currency_code,
    i.quantity,
    i.line_net_amount,
    i.line_cost_amount,
    i.line_net_amount - i.line_cost_amount as line_margin_amount
from {{ ref('int_order_items') }} as i
join {{ ref('dim_customers_history') }} as c
    on i.customer_id = c.customer_id
    -- Untere Grenze eingeschlossen, obere Grenze ausgeschlossen.
    and i.ordered_at >= c.valid_from
    and (i.ordered_at < c.valid_to or c.valid_to is null)
join {{ ref('dim_products') }} as p
    on i.product_id = p.product_id
