------------------------------------------------------------
-- Applies all cleaning steps as in IPython Notebook
------------------------------------------------------------

---------------------------
-- 1. Remove duplicates
---------------------------
-- Assumes staging_sales_raw contains the raw imported data.
-- You will load cleaned rows into staging_sales.
---------------------------

CREATE TABLE IF NOT EXISTS staging_sales_raw_clean AS
SELECT DISTINCT *
FROM staging_sales_raw;   -- Replace with your raw table name


------------------------------------------------------------
-- 2. Fix invalid date values (remove NULL or malformed dates)
------------------------------------------------------------

DELETE FROM staging_sales_raw_clean
WHERE sale_date IS NULL;


------------------------------------------------------------
-- 3. Normalize text columns (trim, lowercase, remove noise)
------------------------------------------------------------

UPDATE staging_sales_raw_clean
SET 
    store    = INITCAP(TRIM(store)),
    region   = INITCAP(TRIM(region)),
    product  = INITCAP(TRIM(product)),
    category = INITCAP(TRIM(category));


------------------------------------------------------------
-- 4. Remove negative numeric values
------------------------------------------------------------

DELETE FROM staging_sales_raw_clean
WHERE 
    unit_price < 0
    OR quantity < 0
    OR total_sales < 0;


------------------------------------------------------------
-- 5. Coerce invalid numerics to NULL (instead of crash)
------------------------------------------------------------

UPDATE staging_sales_raw_clean
SET
    unit_price = NULLIF(unit_price::TEXT, 'NaN')::NUMERIC,
    quantity   = NULLIF(quantity::TEXT, 'NaN')::INTEGER,
    total_sales = NULLIF(total_sales::TEXT, 'NaN')::NUMERIC;


------------------------------------------------------------
-- 6. Impute missing numerics (use safe defaults or medians)
------------------------------------------------------------

-- Replace NULL quantities with 0
UPDATE staging_sales_raw_clean
SET quantity = 0
WHERE quantity IS NULL;

-- Replace NULL unit_price with the category median
UPDATE staging_sales_raw_clean s
SET unit_price = sub.median_price
FROM (
    SELECT category, PERCENTILE_CONT(0.5) 
           WITHIN GROUP (ORDER BY unit_price) AS median_price
    FROM staging_sales_raw_clean
    GROUP BY category
) sub
WHERE s.unit_price IS NULL
  AND s.category = sub.category;


------------------------------------------------------------
-- 7. Recalculate total_sales if missing or inconsistent
------------------------------------------------------------

UPDATE staging_sales_raw_clean
SET total_sales = unit_price * quantity
WHERE total_sales IS NULL
   OR total_sales <> unit_price * quantity;


------------------------------------------------------------
-- 8. Cap outliers using the IQR method (per category)
------------------------------------------------------------

WITH iqr AS (
    SELECT 
        category,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_sales) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_sales) AS q3
    FROM staging_sales_raw_clean
    GROUP BY category
)
UPDATE staging_sales_raw_clean s
SET total_sales =
    CASE 
        WHEN s.total_sales < i.q1 - 1.5 * (i.q3 - i.q1)
            THEN i.q1 - 1.5 * (i.q3 - i.q1)
        WHEN s.total_sales > i.q3 + 1.5 * (i.q3 - i.q1)
            THEN i.q3 + 1.5 * (i.q3 - i.q1)
        ELSE s.total_sales
    END
FROM iqr i
WHERE s.category = i.category;


------------------------------------------------------------
-- 11. Load cleaned data into final staging table
------------------------------------------------------------

TRUNCATE staging_sales;

INSERT INTO staging_sales (
    sale_date, store, region, product, category,
    unit_price, quantity, total_sales
)
SELECT 
    sale_date, store, region, product, category,
    unit_price, quantity, total_sales
FROM staging_sales_raw_clean;

------------------------------------------------------------
-- End of SQL Cleaning Pipeline
------------------------------------------------------------
