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

SELECT sale_date, quantity, unit_price FROM staging_sales;