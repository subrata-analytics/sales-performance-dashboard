-- Populate Dimension Tables (Based on staging table)
-- Populate dim_date
INSERT INTO dim_date (sale_date)
SELECT DISTINCT
	sale_date
FROM staging_sales
ON CONFLICT (sale_date) DO NOTHING;

UPDATE dim_date
SET
    sale_year    = EXTRACT(YEAR    FROM sale_date)::INTEGER,
    sale_month   = EXTRACT(MONTH   FROM sale_date)::INTEGER,
    sale_quarter = EXTRACT(QUARTER FROM sale_date)::INTEGER,
    weekday      = TRIM(TO_CHAR(sale_date, 'Day')); -- e.g., 'Monday'

-- Populate dim_store
INSERT INTO dim_store (store_name, region)
SELECT DISTINCT
	store,
	region
FROM staging_sales
ON CONFLICT (store_name, region) DO NOTHING;

-- Populate dim_product
INSERT INTO dim_product (product_name, category)
SELECT DISTINCT
	product,
	category
FROM staging_sales
ON CONFLICT (product_name, category) DO NOTHING;


SELECT * FROM dim_date;
SELECT * FROM dim_store;
SELECT * FROM dim_product;