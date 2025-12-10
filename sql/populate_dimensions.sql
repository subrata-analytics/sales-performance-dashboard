-- Populate Dimension Tables (Based on staging table)
-- Populate dim_date
INSERT INTO dim_date (sale_date, sale_year, sale_month, sale_quarter, weekday)
SELECT DISTINCT
	sale_date,
	sale_year,
	sale_month,
	sale_quarter,
	weekday
FROM staging_sales
ON CONFLICT (sale_date) DO NOTHING;

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

-- Populate dim_sales_metrics
INSERT INTO dim_sales_metrics (unit_price, estimated_cost, estimated_profit)
SELECT DISTINCT
	unit_price,
	estimated_cost,
	estimated_profit
FROM staging_sales
ON CONFLICT DO NOTHING;

SELECT * FROM dim_date;
SELECT * FROM dim_store;
SELECT * FROM dim_product;
SELECT * FROM dim_sales_metrics;