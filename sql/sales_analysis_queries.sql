-- Essential sales KPIs (High-level analysis)
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

