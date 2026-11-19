select *
from {{ ref('dim_customers') }}
where first_name != 'Hannah'