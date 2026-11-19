-- Tag 1: Explizite Spalten statt SELECT *; keine fachliche Zusammenfassung.
select
    customer_id,
    segment_id,
    first_name,
    last_name,
    email,
    country_code,
    registered_at,
    updated_at
from {{ source('crm', 'customers') }}
