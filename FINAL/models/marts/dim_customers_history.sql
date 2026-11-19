select
    dbt_scd_id as customer_version_key,
    customer_id,
    segment_id,
    first_name,
    last_name,
    country_code,
    dbt_valid_from as valid_from,
    dbt_valid_to as valid_to
from {{ ref('customers_snapshot') }}

