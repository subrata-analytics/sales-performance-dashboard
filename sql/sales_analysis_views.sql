-- sales_analysis_views.sql
-- Analytical queries and materialized views to support dashboards and exports
-- Run after cleaning_queries.sql

BEGIN;

------------------------------------------------------------
-- 1) Monthly Sales (time-series)
------------------------------------------------------------
DROP VIEW IF EXISTS vw_monthly_sales;
CREATE VIEW vw_monthly_sales AS
SELECT
    date_trunc('month', d.sale_date)::DATE AS month_start,
    EXTRACT(YEAR FROM d.sale_date)::INT AS year,
    EXTRACT(MONTH FROM d.sale_date)::INT AS month,
    SUM(f.total_sales) AS total_revenue,
    SUM(f.quantity) AS total_units,
    AVG(f.unit_price) AS avg_unit_price
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY 1,2,3
ORDER BY 1;

------------------------------------------------------------
-- 2) Top Products by Revenue
------------------------------------------------------------
DROP VIEW IF EXISTS vw_top_products;
CREATE VIEW vw_top_products AS
SELECT
    p.product_name,
    p.category,
    SUM(f.total_sales) AS revenue,
    SUM(f.quantity) AS units_sold,
    ROUND(AVG(f.unit_price), 2) AS avg_price
FROM fact_sales f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.product_name, p.category
ORDER BY revenue DESC;

------------------------------------------------------------
-- 3) Regional Performance (store/region)
------------------------------------------------------------
DROP VIEW IF EXISTS vw_region_performance;
CREATE VIEW vw_region_performance AS
SELECT
    s.region,
    s.store_name,
    SUM(f.total_sales) AS revenue,
    SUM(f.quantity) AS units_sold,
    AVG(f.unit_price) AS avg_price
FROM fact_sales f
JOIN dim_store s ON s.store_key = f.store_key
GROUP BY s.region, s.store_name
ORDER BY revenue DESC;

------------------------------------------------------------
-- 4) Weekly Sales (7-day aggregates)
------------------------------------------------------------
DROP VIEW IF EXISTS vw_weekly_sales;
CREATE VIEW vw_weekly_sales AS
SELECT
    date_trunc('week', d.sale_date)::DATE AS week_start,
    SUM(f.total_sales) AS weekly_revenue,
    AVG(f.total_sales) AS avg_daily_revenue
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY 1
ORDER BY week_start;

------------------------------------------------------------
-- 5) Category Performance (yearly)
------------------------------------------------------------
DROP VIEW IF EXISTS vw_category_performance;
CREATE VIEW vw_category_performance AS
SELECT
    p.category,
    EXTRACT(YEAR FROM d.sale_date) AS year,
    SUM(f.total_sales) AS revenue,
    SUM(f.quantity) AS units_sold,
    ROUND(
        100.0 * SUM(f.total_sales)
        / SUM(SUM(f.total_sales)) OVER (PARTITION BY EXTRACT(YEAR FROM d.sale_date)),
        2
    ) AS pct_of_year_revenue
FROM fact_sales f
JOIN dim_product p ON p.product_key = f.product_key
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY p.category, EXTRACT(YEAR FROM d.sale_date)
ORDER BY year, revenue DESC;

------------------------------------------------------------
-- 6) Average Order Value (AOV) by month
-- NOTE: fact_sales has no transaction_id in your schema.
-- We compute AOV as revenue / number of sales rows.
------------------------------------------------------------
DROP VIEW IF EXISTS vw_aov_monthly;
CREATE VIEW vw_aov_monthly AS
SELECT
    date_trunc('month', d.sale_date)::DATE AS month_start,
    SUM(f.total_sales) / NULLIF(COUNT(*), 0) AS avg_order_value
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY 1
ORDER BY 1;

COMMIT;

-- Optional: materialized views
CREATE MATERIALIZED VIEW mv_top_products AS SELECT * FROM vw_top_products;
CREATE INDEX ON mv_top_products (revenue DESC);

-- End of sales_analysis_queries.sql