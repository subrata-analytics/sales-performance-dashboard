-- Populate fact_sales
INSERT INTO fact_sales (
	date_key,
	store_key,
	product_key,
	metrics_key,
	quantity,
	total_sales
)
SELECT 
	d.date_key,
	s.store_key,
	p.product_key,
	m.metrics_key,
	st.quantity,
	st.total_sales
FROM staging_sales st
JOIN dim_date d
	ON st.sale_date = d.sale_date
JOIN dim_store s
	ON st.store = s.store_name AND st.region = s.region
JOIN dim_product p
	ON st.product = p.product_name AND st.category = p.category
JOIN dim_sales_metrics m
	ON st.unit_price = m.unit_price
	AND st.estimated_cost = m.estimated_cost
	AND st.estimated_profit = m.estimated_profit;


SELECT * FROM fact_sales;