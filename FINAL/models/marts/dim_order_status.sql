-- ref() kann neben Models auch Seeds referenzieren.
select
    order_status,
    status_label,
    status_rank
from {{ ref('order_status_mapping') }}
