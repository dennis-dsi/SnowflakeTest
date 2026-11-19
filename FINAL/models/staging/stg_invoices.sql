-- Eine Zeile entspricht einer Rechnung.
select
    invoice_id,
    invoice_number,
    order_id,
    invoice_date,
    due_date,
    invoice_status,
    updated_at
from {{ source('erp', 'invoices') }}
