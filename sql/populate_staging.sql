-- Import CSV data into staging table
-- Give the postgres user read access to 
-- the file before running this command 
-- Use absolute path of the CSV file if needed
COPY staging_sales (
    sale_date,
    store,
    region,
    product,
    category,
    unit_price,
    quantity,
    total_sales
)
FROM '../data/retail_sales_50krows_cleaned.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Populate new-derived columns in staging_sales
UPDATE staging_sales
SET
	sale_year 		= EXTRACT(YEAR FROM sale_date)::INTEGER,
	sale_month 		= EXTRACT(MONTH FROM sale_date)::INTEGER,
	sale_quarter	= EXTRACT(QUARTER FROM sale_date)::INTEGER,
	weekday 		= TO_CHAR(sale_date, 'Day'); -- e.g., 'Monday'

-- Remove whitespaces from weekday
UPDATE staging_sales
SET weekday = TRIM(weekday);

-- Insert default cost factors
INSERT INTO product_margin (category, cost_factor) VALUES
-- The arbitrary cost_factors can be replaced with real
-- cost factors or the whole table can be generated from real data
    ('Electronics', 0.62),
    ('Accessories', 0.82),
    ('Other', 0.70)
ON CONFLICT (category) DO NOTHING;

-- Populate estimated_cost and estimated_profit 
-- columns in table staging_sales
UPDATE staging_sales s
SET estimated_cost = 
		s.total_sales * m.cost_factor,
	estimated_profit = 
		s.total_sales * (1 - m.cost_factor)
FROM product_margin m
WHERE s.category = m.category;


SELECT * FROM staging_sales;