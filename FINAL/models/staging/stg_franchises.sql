select franchise_id, franchise_name
from {{ source('erp', 'franchises') }}
