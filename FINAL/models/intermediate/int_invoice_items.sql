-- Eine Zeile bleibt eine Rechnungsposition.
select
    i.invoice_item_id,
    i.invoice_id,
    i.order_item_id,
    h.order_id,
    o.customer_id,
    oi.product_id,
    h.invoice_date,
    o.currency_code,
    i.quantity,
    -- Der Rabatt gilt für die gesamte Rechnungsposition.
    i.quantity * i.unit_price_net - i.discount_net as line_net_amount
from {{ ref('stg_invoice_items') }} as i
join {{ ref('stg_invoices') }} as h
    on i.invoice_id = h.invoice_id
join {{ ref('stg_orders') }} as o
    on h.order_id = o.order_id
join {{ ref('stg_order_items') }} as oi
    on i.order_item_id = oi.order_item_id
where h.invoice_status = 'ISSUED'
