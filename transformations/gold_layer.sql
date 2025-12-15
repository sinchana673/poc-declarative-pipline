-- ===============================================================
-- GOLD LAYER SCRIPT (gold.sql)
-- ===============================================================
-- Purpose:
--   This script creates materialized views in the Gold layer.
--   These views provide curated business metrics by applying
--   aggregations on Silver tables for analytics and dashboarding.
--
-- Input Tables (Silver Layer):
--   workspace.declarative_poc.silver_customers
--   workspace.declarative_poc.silver_products
--   workspace.declarative_poc.silver_stores
--   workspace.declarative_poc.silver_sales
--
-- Output Views (Gold Layer):
--   workspace.declarative_poc.gold_store_sales
--   workspace.declarative_poc.gold_product_sales
--   workspace.declarative_poc.gold_customer_sales
--   workspace.declarative_poc.gold_daily_sales
--   workspace.declarative_poc.gold_top_products
-- ===============================================================


-- 1. Store-Level Sales Metrics
-- Aggregates sales data at the store level to analyze performance.
-- Metrics include total sales count, quantity, revenue, and avg sale value.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_store_sales AS
SELECT
    s.store_id,
    s.store_name,
    COUNT(sa.sale_id) AS total_sales,
    SUM(sa.quantity) AS total_quantity,
    SUM(sa.quantity * sa.price) AS total_revenue,
    AVG(sa.quantity * sa.price) AS avg_sale_value
FROM workspace.declarative_poc.silver_sales sa
JOIN workspace.declarative_poc.silver_stores s ON sa.store_id = s.store_id
GROUP BY s.store_id, s.store_name;


-- 2. Product-Level Sales Metrics
-- Aggregates sales at the product level to identify product performance.
-- Metrics include sales count, quantity, revenue, and avg sale value.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_product_sales AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COUNT(sa.sale_id) AS total_sales,
    SUM(sa.quantity) AS total_quantity,
    SUM(sa.quantity * sa.price) AS total_revenue,
    AVG(sa.quantity * sa.price) AS avg_sale_value
FROM workspace.declarative_poc.silver_sales sa
JOIN workspace.declarative_poc.silver_products p ON sa.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category;


-- 3. Customer-Level Sales Metrics
-- Aggregates sales data at the customer level for behavior analysis.
-- Metrics include order count, total spend, and avg order value.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_customer_sales AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(sa.sale_id) AS total_orders,
    SUM(sa.quantity) AS total_quantity,
    SUM(sa.quantity * sa.price) AS total_spent,
    AVG(sa.quantity * sa.price) AS avg_order_value
FROM workspace.declarative_poc.silver_sales sa
JOIN workspace.declarative_poc.silver_customers c ON sa.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;


-- 4. Daily Sales Trends per Store
-- Tracks daily sales activity for trend analysis and forecasting.
-- Metrics include daily sales count, quantity sold, and revenue.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_daily_sales AS
SELECT
    s.store_id,
    s.store_name,
    sa.sale_date,
    COUNT(sa.sale_id) AS daily_sales_count,
    SUM(sa.quantity) AS daily_total_quantity,
    SUM(sa.quantity * sa.price) AS daily_revenue
FROM workspace.declarative_poc.silver_sales sa
JOIN workspace.declarative_poc.silver_stores s ON sa.store_id = s.store_id
GROUP BY s.store_id, s.store_name, sa.sale_date
ORDER BY s.store_id, sa.sale_date;


-- 5. Top-Selling Products per Store
-- Identifies best-performing products by store based on sales volume and revenue.
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_top_products AS
SELECT
    s.store_id,
    s.store_name,
    p.product_id,
    p.product_name,
    SUM(sa.quantity) AS total_quantity_sold,
    SUM(sa.quantity * sa.price) AS total_revenue
FROM workspace.declarative_poc.silver_sales sa
JOIN workspace.declarative_poc.silver_stores s ON sa.store_id = s.store_id
JOIN workspace.declarative_poc.silver_products p ON sa.product_id = p.product_id
GROUP BY s.store_id, s.store_name, p.product_id, p.product_name
ORDER BY s.store_id, total_quantity_sold DESC;
