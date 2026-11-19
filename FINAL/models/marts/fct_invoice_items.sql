select
    i.invoice_item_id,
    i.invoice_id,
    i.order_item_id,
    i.order_id,
    c.customer_version_key,
    p.product_id,
    i.invoice_date,
    i.currency_code,
    i.quantity,
    i.line_net_amount
from {{ ref('int_invoice_items') }} as i
join {{ ref('dim_customers_history') }} as c
    on i.customer_id = c.customer_id
    -- Die Quelle liefert nur ein Datum. Für dieses Lab gilt Tagesbeginn.
    and cast(i.invoice_date as timestamp_ntz) >= c.valid_from
    and (cast(i.invoice_date as timestamp_ntz) < c.valid_to or c.valid_to is null)
join {{ ref('dim_products') }} as p
    on i.product_id = p.product_id
