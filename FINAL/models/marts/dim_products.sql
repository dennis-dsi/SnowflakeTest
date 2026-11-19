-- Tag 1: Beschreibende Merkmale stehen gemeinsam in einer flachen Dimension.
select
    p.product_id,
    p.sku,
    p.product_name,
    p.edition,
    p.fulfillment_type,
    f.franchise_name,
    c.category_name,
    pl.platform_name
from {{ ref('stg_products') }} as p
join {{ ref('stg_franchises') }} as f
    on p.franchise_id = f.franchise_id
join {{ ref('stg_product_categories') }} as c
    on p.category_id = c.category_id
-- Nicht jedes Produkt hat eine Plattform. LEFT JOIN erhält diese Produkte.
left join {{ ref('stg_platforms') }} as pl
    on p.platform_id = pl.platform_id
