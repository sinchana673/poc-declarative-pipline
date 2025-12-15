-- ===============================================================
-- GOLD FILTERED VIEWS (Filtered MVs)
-- ===============================================================
-- Purpose:
--   These filtered materialized views select subsets of data
--   for specific business scenarios (e.g., recent sales, high-value sales).
-- ===============================================================

-- 6. Recent Sales (Last 30 Days)
-- Provides only recent sales to support near real-time dashboards.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_recent_sales AS
SELECT
    sa.sale_id,
    sa.customer_id,
    sa.product_id,
    sa.store_id,
    sa.quantity,
    sa.price,
    sa.sale_date
FROM workspace.declarative_poc.silver_sales sa
WHERE sa.sale_date >= date_sub(current_date(), 30);


-- 7. High-Value Sales
-- Filters sales transactions where revenue per sale > 1000.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_high_value_sales AS
SELECT
    sa.sale_id,
    sa.customer_id,
    sa.product_id,
    sa.store_id,
    sa.quantity,
    sa.price,
    (sa.quantity * sa.price) AS total_sale_value,
    sa.sale_date
FROM workspace.declarative_poc.silver_sales sa
WHERE (sa.quantity * sa.price) > 1000;


-- 8. Zero-Quantity or Test Sales
-- Captures abnormal/test data for auditing and quality monitoring.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_invalid_sales AS
SELECT
    sa.sale_id,
    sa.customer_id,
    sa.product_id,
    sa.store_id,
    sa.quantity,
    sa.price,
    sa.sale_date
FROM workspace.declarative_poc.silver_sales sa
WHERE sa.quantity <= 0 OR sa.price <= 0;
