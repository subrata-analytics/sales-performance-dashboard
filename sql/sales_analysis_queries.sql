-- 1. Essential sales KPIs (High-level analysis)
-- 1.1 Total Sales
SELECT * FROM fact_sales;

SELECT 
    SUM(total_sales) AS total_revenue
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
    SUM(dsm.estimated_profit) AS total_profit,
    SUM(dsm.estimated_cost) AS total_cost
FROM fact_sales fs
JOIN dim_sales_metrics dsm ON fs.metrics_key = dsm.metrics_key;


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
    SUM(dsm.estimated_profit) AS profit
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_sales_metrics dsm ON fs.metrics_key = dsm.metrics_key
GROUP BY 1, 2 -- GROUP BY dp.product_name, dp.category
ORDER BY profit
LIMIT 5;


-- 5. Price, Cost, and Profitability Analysis
-- 5.1 Profit Margin by Category
SELECT 
    dp.category,
    SUM(dsm.estimated_profit) / NULLIF(SUM(fs.total_sales), 0) AS profit_margin
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_sales_metrics dsm ON fs.metrics_key = dsm.metrics_key
GROUP BY dp.category
ORDER BY profit_margin DESC;

-- 5.2 Price Elasticity Indicator (basic)
SELECT
    dp.product_name,
    dp.category,
    AVG(dsm.unit_price) AS avg_price,
    SUM(fs.quantity) AS total_units
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_sales_metrics dsm ON fs.metrics_key = dsm.metrics_key
GROUP BY dp.product_name, dp.category
ORDER BY avg_price DESC;
