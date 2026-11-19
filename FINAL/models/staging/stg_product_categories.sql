select category_id, category_name
from {{ source('erp', 'product_categories') }}
