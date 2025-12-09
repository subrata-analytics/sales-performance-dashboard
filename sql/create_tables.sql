-- Run each block of this script separately to avoid errors
-- Drop tables safely
DROP TABLE IF EXISTS staging_sales;
DROP TABLE IF EXISTS product_margin;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_product;
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

-- Add the new date-derived columns to the staging_sales
ALTER TABLE staging_sales
ADD COLUMN sale_year		INTEGER,
ADD COLUMN sale_month		INTEGER,
ADD COLUMN sale_quarter		INTEGER,
ADD COLUMN weekday			TEXT;

-- Create a cost factor table
CREATE TABLE IF NOT EXISTS product_margin (
    category TEXT PRIMARY KEY,
    cost_factor NUMERIC(5,4) NOT NULL CHECK (cost_factor > 0 AND cost_factor < 1)
);

-- Create dimension tables --
-----------------------------
-- dim_date: includes all the analytic attributes
-- extracted from the dateset
CREATE TABLE IF NOT EXISTS dim_date (
	date_key			SERIAL PRIMARY KEY,
	sale_date			DATE UNIQUE,
	sale_year			INTEGER,
	sale_month			INTEGER,
	sale_quarter		INTEGER,
	weekday				TEXT
);

-- dim_store: Normalized store and region table
CREATE TABLE IF NOT EXISTS dim_store (
    store_key       SERIAL PRIMARY KEY,
    store_name      TEXT,
    region          TEXT,
    UNIQUE (store_name, region)
);

-- dim_product: Noramlized product information
CREATE TABLE IF NOT EXISTS dim_product (
	product_key		SERIAL PRIMARY KEY,
	product_name 	TEXT,
	category		TEXT,
	UNIQUE (product_name, category)
);

-- dim_sales_metrics: Usable numeric attributes for modeling
CREATE TABLE IF NOT EXISTS dim_sales_metrics (
	metrics_key			SERIAL PRIMARY KEY,
	unit_price			NUMERIC(12,2) CHECK (unit_price >= 0),
	estimated_cost		NUMERIC (14,2),
	estimated_profit	NUMERIC (14,2)
);

-- The fact table references all dimensions and stores 
-- the transaction-level measures.
-- fact_sales: It references all dimensions and transactions
CREATE TABLE IF NOT EXISTS fact_sales (
	sales_id			SERIAL PRIMARY KEY,

	date_key			INTEGER REFERENCES dim_date(date_key),
	store_key			INTEGER REFERENCES dim_store(store_key),
	product_key			INTEGER REFERENCES dim_product(product_key),
	metrics_key			INTEGER REFERENCES dim_sales_metrics(metrics_key),

	quantity			INTEGER NOT NULL CHECK (quantity >= 0),
	total_sales			NUMERIC(14,2), CHECK (total_sales >= 0)
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

-- Other queries
SELECT * FROM product_margin;
SELECT * FROM staging_sales;
SELECT sale_date, quantity, estimated_cost, estimated_profit FROM staging_sales;

ROLLBACK;