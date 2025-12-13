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
GROUP BY 1, 2
ORDER BY 1, 2;

-- 2.2 Sales by Quarter
SELECT
    dd.sale_year,
    dd.sale_quarter,
    SUM(fs.total_sales) AS quaterly_sales
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY 1, 2
ORDER BY 1, 2;

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
GROUP BY 1, 2
ORDER BY 1, 3 DESC;