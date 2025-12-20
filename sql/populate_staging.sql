-- Import CSV data into staging table
-- Give the postgres user read access to 
-- the file before running this command 
-- Use absolute path of the CSV file if needed
COPY staging_sales_raw (
    sale_date,
    store,
    region,
    product,
    category,
    unit_price,
    quantity,
    total_sales
)
FROM '../data/retail_sales_50krows.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');


SELECT COUNT(sale_date) AS total_count FROM staging_sales_raw;
-- pgsql> 50000