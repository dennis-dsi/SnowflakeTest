select platform_id, platform_name
from {{ source('erp', 'platforms') }}
