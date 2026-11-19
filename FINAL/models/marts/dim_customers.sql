-- Diese Dimension zeigt immer den aktuellen Kundenstand (Type 1).
select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country_code,
    s.segment_name
from {{ ref('stg_customers') }} as c
join {{ ref('stg_customer_segments') }} as s
    on c.segment_id = s.segment_id
