-- ===============================================================
-- SILVER LAYER DELTA TABLES (Correct Streaming / DQ setup
-- Description: Clean Bronze data, remove nulls & duplicates,
--              apply constraints, advanced DQ checks
-- ===============================================================


-- ===============================================================
-- Silver Customers Table (Streaming)
-- ===============================================================
CREATE OR REFRESH STREAMING LIVE TABLE workspace.declarative_poc.silver_customers
TBLPROPERTIES ("quality" = "silver")
AS
SELECT DISTINCT
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    state,
    country,
    signup_date,
    load_timestamp,
    source_file
FROM STREAM workspace.declarative_poc.bronze_customers
WHERE customer_id IS NOT NULL
  AND email IS NOT NULL
  AND email LIKE '%_@__%.__%'
  AND phone IS NOT NULL;


-- ===============================================================
-- Silver Products Table (Streaming)
-- ===============================================================
CREATE OR REFRESH STREAMING LIVE TABLE workspace.declarative_poc.silver_products
TBLPROPERTIES ("quality" = "silver")
AS
SELECT DISTINCT
    product_id,
    product_name,
    category,
    brand,
    price,
    currency,
    launch_date,
    load_timestamp,
    source_file
FROM STREAM workspace.declarative_poc.bronze_products
WHERE product_id IS NOT NULL
  AND product_name IS NOT NULL
  AND price IS NOT NULL
  AND price > 0
  AND currency IS NOT NULL
  AND launch_date IS NOT NULL
  AND launch_date <= current_date();


-- ===============================================================
-- Silver Stores Table (Streaming)
-- ===============================================================
CREATE OR REFRESH STREAMING LIVE TABLE workspace.declarative_poc.silver_stores
TBLPROPERTIES ("quality" = "silver")
AS
SELECT DISTINCT
    store_id,
    store_name,
    location_city,
    location_state,
    location_country,
    opened_date,
    manager_name,
    load_timestamp,
    source_file
FROM STREAM workspace.declarative_poc.bronze_stores
WHERE store_id IS NOT NULL
  AND store_name IS NOT NULL
  AND opened_date IS NOT NULL
  AND opened_date <= current_date();


-- ===============================================================
-- Silver Sales Table (Streaming with Referential Integrity)
-- ===============================================================
CREATE OR REFRESH STREAMING LIVE TABLE workspace.declarative_poc.silver_sales
TBLPROPERTIES ("quality" = "silver")
AS
SELECT DISTINCT
    sale_id,
    customer_id,
    product_id,
    store_id,
    quantity,
    price,
    sale_date,
    load_timestamp,
    source_file
FROM STREAM workspace.declarative_poc.bronze_sales AS b
WHERE sale_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND product_id IS NOT NULL
  AND store_id IS NOT NULL
  AND quantity > 0
  AND price > 0
  AND sale_date IS NOT NULL
  AND sale_date <= current_date()
  AND EXISTS (SELECT 1 FROM workspace.declarative_poc.silver_customers c WHERE c.customer_id = b.customer_id)
  AND EXISTS (SELECT 1 FROM workspace.declarative_poc.silver_products p WHERE p.product_id = b.product_id)
  AND EXISTS (SELECT 1 FROM workspace.declarative_poc.silver_stores s WHERE s.store_id = b.store_id);


