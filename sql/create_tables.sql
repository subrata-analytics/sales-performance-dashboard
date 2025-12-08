-- Run each block of this script separately to avoid errors
-- Drop tables safely
DROP TABLE IF EXISTS staging_sales;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS fact_sales;

-- Create staging table safely
CREATE TABLE IF NOT EXISTS staging_sales (
    sale_date            DATE,
    store                TEXT,
    region               TEXT,
    product              TEXT,
    category             TEXT,
    unit_price           NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    quantity             INTEGER NOT NULL CHECK (quantity >= 0),
    total_sales          NUMERIC(14,2) CHECK (total_sales >= 0),
    estimated_cost       NUMERIC(14,2),
    estimated_profit     NUMERIC(14,2)
);

-- Create a cost factor table
CREATE TABLE IF NOT EXISTS product_margin (
    category TEXT PRIMARY KEY,
    cost_factor NUMERIC(5,4) NOT NULL CHECK (cost_factor > 0 AND cost_factor < 1)
);

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

-- Insert default cost factors
INSERT INTO product_margin (category, cost_factor) VALUES
    ('Electronics', 0.62),
    ('Accessories', 0.82),
    ('Other', 0.70)
ON CONFLICT (category) DO NOTHING;


UPDATE staging_sales s
SET estimated_cost = 
		s.total_sales * m.cost_factor,
	estimated_profit = 
		s.total_sales * (1 - m.cost_factor)
FROM product_margin m
WHERE s.category = m.category;

-- More simpler way is to use a fixed cost factor
-- Example: Assume cost = 65% of revenue
-- UPDATE staging_sales
-- SET estimated_cost   = total_sales * 0.65,
--     estimated_profit = total_sales * (1 - * 0.65);

SELECT * FROM product_margin;
SELECT sale_date, quantity, estimated_cost, estimated_profit FROM staging_sales;

ROLLBACK;