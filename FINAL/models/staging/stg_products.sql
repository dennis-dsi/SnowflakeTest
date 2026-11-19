-- Tag 1: Die aktuelle Produktkosten-Spalte wird nicht zur Verkaufsberechnung genutzt.
select
    product_id,
    sku,
    franchise_id,
    category_id,
    platform_id,
    product_name,
    edition,
    fulfillment_type,
    release_date
from {{ source('erp', 'products') }}
