TRUNCATE fact_sales;

-- Populate fact_sales
INSERT INTO fact_sales (
    date_key,
    store_key,
    product_key,
    quantity,
    unit_price,
    total_sales,
    estimated_cost,
    estimated_profit
)
SELECT
    dd.date_key,
    ds.store_key,
    dp.product_key,
    st.quantity,
    st.unit_price,
    st.total_sales,
    st.total_sales * pm.cost_factor,
    st.total_sales - (st.total_sales * pm.cost_factor)
FROM staging_sales st
JOIN dim_date dd
    ON st.sale_date = dd.sale_date
JOIN dim_store ds
    ON st.store = ds.store_name 
   AND st.region = ds.region
JOIN dim_product dp
    ON st.product = dp.product_name 
   AND st.category = dp.category
JOIN product_margin pm
    ON st.category = pm.category;

-- Update fcat_sales for estimated cost and profit
UPDATE fact_sales fs
SET
    estimated_cost = fs.total_sales * pm.cost_factor,
    estimated_profit = fs.total_sales - (fs.total_sales * pm.cost_factor)
FROM dim_product dp
JOIN product_margin pm
    ON dp.category = pm.category
WHERE fs.product_key = dp.product_key;


SELECT 
	COUNT(date_key) AS dpts,
	SUM(estimated_cost) AS total_cost,
	SUM(estimated_profit) AS total_profit
FROM fact_sales;