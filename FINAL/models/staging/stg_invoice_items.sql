-- Eine Zeile entspricht einer Rechnungsposition.
select
    invoice_item_id,
    invoice_id,
    line_number,
    order_item_id,
    quantity,
    unit_price_net,
    discount_net,
    tax_rate
from {{ source('erp', 'invoice_items') }}
