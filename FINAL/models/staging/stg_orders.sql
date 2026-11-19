-- Tag 1: Eine Zeile bleibt eine Bestellung. Die Quelle ist bereits typisiert.
select
    order_id,
    order_number,
    customer_id,
    ordered_at,
    cast(ordered_at as date) as order_date,
    order_status,
    currency_code,
    updated_at
from {{ source('erp', 'orders') }}
