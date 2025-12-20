-- 1. Essential sales KPIs (High-level analysis)
-- 1.1 Total Sales
SELECT * FROM fact_sales;

SELECT
    SUM(total_sales) AS total_sales
FROM fact_sales;

-- 1.2 Total Quantity Sold
SELECT
    SUM(quantity) AS total_units_sold
FROM fact_sales;

-- 1.3 Average Order Value (AOV)
SELECT
    SUM(total_sales) / SUM(quantity) AS avg_order_value
FROM fact_sales;

-- 1.4 Profitability
SELECT
    dp.category,
    SUM(total_sales) AS total_sales,
	SUM(estimated_cost) AS total_cost,
	SUM(estimated_profit) AS total_profit
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY 1
ORDER BY 1;

SELECT
    SUM(estimated_profit) AS total_profit,
    SUM(estimated_cost) AS total_cost
FROM fact_sales;



-- 2. Time-Series Analysis (Trend Charts)
-- 2.1 Sales by Month
SELECT
    dd.sale_year,
    dd.sale_month,
    SUM(fs.total_sales) AS monthly_sales
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY 1, 2 -- GROUP BY dd.sale_year, dd.sale_month
ORDER BY 1, 2; -- ORDER BY dd.sale_year, dd.sale_month;

-- 2.2 Sales by Quarter
SELECT
    dd.sale_year,
    dd.sale_quarter,
    SUM(fs.total_sales) AS quaterly_sales
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY 1, 2  -- GROUP BY dd.sale_year, dd.sale_quarter
ORDER BY 1, 2; -- ORDER BY dd.sale_year, dd.sale_quarter;

-- 2.3 Weekday Performance
SELECT
    dd.weekday,
    SUM(fs.total_sales) AS revenue
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY dd.weekday
ORDER BY revenue DESC;

-- 2.4 Yearly-Weekday Performance
SELECT
    dd.sale_year,
    dd.weekday,
    SUM(fs.total_sales) AS revenue
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY 1, 2 -- GROUP BY dd.sale_year, dd.weekday
ORDER BY 1, 3 DESC; -- ORDER BY dd.sale_year, dd.weekday DESC;


-- 3 Store & Region Analysis
-- 3.1 Sales by Region
SELECT
    ds.region,
    SUM(fs.total_sales) AS revenue
FROM fact_sales fs
JOIN dim_store ds ON fs.store_key = ds.store_key
GROUP BY ds.region
ORDER BY revenue DESC;

-- 3.2 Top Stores by Sales
SELECT
    ds.store_name,
    ds.region,
    SUM(fs.total_sales) AS store_sales
FROM fact_sales fs
JOIN dim_store ds ON fs.store_key = ds.store_key
GROUP BY 1, 2 -- GROUP BY ds.store_name, ds.region
ORDER BY store_sales
LIMIT 10;


-- 4. Product & Category Analysis
-- 4.1 Sales by Category
SELECT
    dp.category,
    SUM(fs.total_sales) AS revenue
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.category
ORDER BY revenue DESC;

-- 4.2 Top-selling Products
SELECT
    dp.product_name,
    dp.category,
    SUM(fs.total_sales) AS sales
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY 1, 2 -- GROUP BY dp.product_name, dp.category
ORDER BY sales DESC
LIMIT 5;

-- 4.3 Most Profitable Products
SELECT
    dp.product_name,
    dp.category,
    SUM(estimated_profit) AS profit
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY 1, 2 -- GROUP BY dp.product_name, dp.category
ORDER BY profit
LIMIT 5;


-- 5. Price, Cost, and Profitability Analysis
-- 5.1 Profit Margin by Category
SELECT 
    dp.category,
    SUM(estimated_profit) / NULLIF(SUM(fs.total_sales), 0) AS profit_margin
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.category
ORDER BY profit_margin DESC;

-- 5.2 Price Elasticity Indicator (basic)
SELECT
    dp.product_name,
    dp.category,
    AVG(fs.unit_price) AS avg_price,
    SUM(fs.quantity) AS total_units
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.product_name, dp.category
ORDER BY avg_price DESC;


-- 6. Screening of Anomalies (Data quality, fraud, mispricing)
-- 6.1 Zero-price or Zero-sale anomalies
SELECT *  
FROM fact_sales fs
WHERE fs.unit_price = 0 OR fs.total_sales = 0;

-- 6.2 Negative profit items
SELECT
    dp.product_name,
    ds.store_name,
    fs.estimated_profit
FROM fact_sales as fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_store ds ON fs.store_key = ds.store_key
WHERE fs.estimated_profit < 0;

-- 7. Executive-level Insights
-- 7.1 Monthly YoY Growth
SELECT
    dd.sale_month,
    SUM(CASE WHEN dd.sale_year = 2023 THEN fs.total_sales END ) AS sales_2023,
    SUM(CASE WHEN dd.sale_year = 2024 THEN fs.total_sales END ) AS sales_2024,
    (
    SUM(CASE WHEN dd.sale_year = 2023 THEN fs.total_sales END ) -
    SUM(CASE WHEN dd.sale_year = 2024 THEN fs.total_sales END )
    ) * 100.0 /
    NULLIF(SUM(CASE WHEN dd.sale_year = 2023 THEN fs.total_sales END), 0) AS yoy_growth_pct
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY dd.sale_month
ORDER BY dd.sale_month;

