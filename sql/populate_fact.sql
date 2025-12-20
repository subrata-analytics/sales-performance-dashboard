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
SELECT DISTINCT
	d.date_key,
	s.store_key,
	p.product_key,
	st.quantity,
	st.unit_price,
	st.total_sales,
	st.total_sales * pm.cost_factor AS estimated_cost,
    st.total_sales - (st.total_sales * pm.cost_factor) AS estimated_profit
FROM staging_sales st
JOIN dim_date d
	ON st.sale_date = d.sale_date
JOIN dim_store s
	ON st.store = s.store_name AND st.region = s.region
JOIN dim_product p
	ON st.product = p.product_name AND st.category = p.category
JOIN product_margin pm ON st.category = pm.category;

SELECT * FROM fact_sales;