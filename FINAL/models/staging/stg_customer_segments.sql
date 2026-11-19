select segment_id, segment_name
from {{ source('crm', 'customer_segments') }}
