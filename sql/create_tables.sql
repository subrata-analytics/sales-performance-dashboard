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
    total_sales          NUMERIC(14,2) CHECK (total_sales >= 0)
);

-- Create staging_sales_raw based on staging_sales schema
CREATE TABLE IF NOT EXISTS staging_sales_raw (
	LIKE staging_sales INCLUDING ALL
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
    cost_factor NUMERIC(5,4) NOT NULL 
        CHECK (cost_factor > 0 AND cost_factor < 1)
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
	total_sales			NUMERIC(14,2) CHECK (total_sales >= 0)
);