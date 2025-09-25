# Data Lakehouse Project: Declarative POC - Customers, Products, Stores, Sales

## Overview

This project implements a multi-layered data lakehouse pipeline using streaming ingestion and Delta tables. The pipeline ingests raw CSV data, applies data quality checks, enforces constraints, and creates curated business metrics for analytics and dashboarding.

The pipeline is organized into three layers:

- **Bronze Layer:** Raw data ingestion from CSV files.
- **Silver Layer:** Data cleansing, deduplication, and quality enforcement.
- **Gold Layer:** Aggregated materialized views for reporting and analytics.

---

## 1. Bronze Layer: Streaming Tables

**Purpose:**  
Ingest raw CSV files from `/volume/data/raw/` into Bronze streaming tables, adding processing timestamps and source file metadata.

```sql
-- BRONZE LAYER STREAMING TABLES
-- Each table ingests files from its respective raw data directory.
-- Adds a load timestamp and the name of the source file for traceability.
-- These tables form the raw, untransformed foundation of the pipeline.

-- Bronze Customers Table
CREATE OR REFRESH STREAMING TABLE workspace.declarative_poc.bronze_customers
AS
SELECT
    *,
    current_timestamp() AS load_timestamp,       -- Timestamp when the row was loaded
    _metadata.file_name AS source_file           -- Source file name for lineage
FROM STREAM read_files(
    '/Volumes/workspace/declarative_poc/volume/data/raw/customers/',
    format => 'csv',
    header => 'true',
    includeExistingFiles => 'true'
);

-- Bronze Products Table
CREATE OR REFRESH STREAMING TABLE workspace.declarative_poc.bronze_products
AS
SELECT
    *,
    current_timestamp() AS load_timestamp,
    _metadata.file_name AS source_file
FROM STREAM read_files(
    '/Volumes/workspace/declarative_poc/volume/data/raw/products/',
    format => 'csv',
    header => 'true',
    includeExistingFiles => 'true'
);

-- Bronze Stores Table
CREATE OR REFRESH STREAMING TABLE workspace.declarative_poc.bronze_stores
AS
SELECT
    *,
    current_timestamp() AS load_timestamp,
    _metadata.file_name AS source_file
FROM STREAM read_files(
    '/Volumes/workspace/declarative_poc/volume/data/raw/stores/',
    format => 'csv',
    header => 'true',
    includeExistingFiles => 'true'
);

-- Bronze Sales Table
CREATE OR REFRESH STREAMING TABLE workspace.declarative_poc.bronze_sales
AS
SELECT
    *,
    current_timestamp() AS load_timestamp,
    _metadata.file_name AS source_file
FROM STREAM read_files(
    '/Volumes/workspace/declarative_poc/volume/data/raw/sales/',
    format => 'csv',
    header => 'true',
    includeExistingFiles => 'true'
);
```

---

## 2. Silver Layer: Delta Tables (Streaming, Data Quality & Constraints)

**Purpose:**  
Clean the Bronze data, remove nulls and duplicates, apply constraints, and advanced data quality checks. Enables referential integrity and prepares the data for analytics.

```sql
-- SILVER LAYER DELTA TABLES
-- Streaming tables with data quality constraints and deduplication.
-- Enforce referential integrity in Sales table using EXISTS clauses.

-- Silver Customers Table (Streaming)
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
WHERE customer_id IS NOT NULL                -- Must have customer_id
  AND email IS NOT NULL                      -- Must have email
  AND email LIKE '%_@__%.__%'                -- Email format validation
  AND phone IS NOT NULL;                     -- Must have phone

-- Silver Products Table (Streaming)
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
WHERE product_id IS NOT NULL                 -- Must have product_id
  AND product_name IS NOT NULL               -- Must have product_name
  AND price IS NOT NULL
  AND price > 0                              -- Price must be positive
  AND currency IS NOT NULL
  AND launch_date IS NOT NULL
  AND launch_date <= current_date();         -- Launch date cannot be in future

-- Silver Stores Table (Streaming)
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
  AND opened_date <= current_date();         -- Store cannot open in future

-- Silver Sales Table (Streaming with Referential Integrity)
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
  AND quantity > 0                            -- Quantity sold must be positive
  AND price > 0                               -- Price must be positive
  AND sale_date IS NOT NULL
  AND sale_date <= current_date()
  -- Referential integrity checks for customers, products, stores
  AND EXISTS (SELECT 1 FROM workspace.declarative_poc.silver_customers c WHERE c.customer_id = b.customer_id)
  AND EXISTS (SELECT 1 FROM workspace.declarative_poc.silver_products p WHERE p.product_id = b.product_id)
  AND EXISTS (SELECT 1 FROM workspace.declarative_poc.silver_stores s WHERE s.store_id = b.store_id);
```

---

## 3. Gold Layer: Materialized Views for Analytics

**Purpose:**  
Create curated, business-ready metrics using aggregations on Silver tables. These views support dashboards and advanced analytics.

```sql
-- GOLD LAYER SCRIPT
-- Materialized views for reporting, each view aggregates Silver table data for analytics.

-- 1. Store-Level Sales Metrics
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_store_sales AS
SELECT
    s.store_id,
    s.store_name,
    COUNT(sa.sale_id) AS total_sales,                 -- Total sale transactions
    SUM(sa.quantity) AS total_quantity,               -- Total quantity sold
    SUM(sa.quantity * sa.price) AS total_revenue,     -- Total revenue by store
    AVG(sa.quantity * sa.price) AS avg_sale_value     -- Average sale value per transaction
FROM workspace.declarative_poc.silver_sales sa
JOIN workspace.declarative_poc.silver_stores s ON sa.store_id = s.store_id
GROUP BY s.store_id, s.store_name;

-- 2. Product-Level Sales Metrics
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
CREATE OR REFRESH MATERIALIZED VIEW workspace.declarative_poc.gold_customer_sales AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(sa.sale_id) AS total_orders,                -- Number of orders per customer
    SUM(sa.quantity) AS total_quantity,
    SUM(sa.quantity * sa.price) AS total_spent,       -- Total spent by customer
    AVG(sa.quantity * sa.price) AS avg_order_value    -- Average order value
FROM workspace.declarative_poc.silver_sales sa
JOIN workspace.declarative_poc.silver_customers c ON sa.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- 4. Daily Sales Trends per Store
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
```

---

## Notes on Constraints & Data Quality

- **NULL checks:** Enforced for all primary keys and critical fields.
- **Format checks:** Enforced for email, dates, and positive numeric values.
- **Referential integrity:** Ensured in the Sales table via EXISTS constraints, guaranteeing that every sale references a valid customer, product, and store.
- **Deduplication:** DISTINCT is used in Silver tables to remove duplicate entries.
- **Temporal constraints:** Dates (launch, opened, sale) are validated to not be in the future.

---

## How to Use

1. **Bronze Layer:** Ingest your raw CSVs into the respective folders. The pipeline auto-loads them with metadata.
2. **Silver Layer:** Cleansed and DQ-enforced tables are created for reliable analytics.
3. **Gold Layer:** Use the views for business reporting, dashboards, and advanced analytics.

---

## Extensibility

- Add new data domains by repeating the Bronze/Silver/Gold pattern.
- Enhance constraints and checks in Silver for evolving DQ needs.
- Add new Gold views for additional business metrics.

---

## Contact

For questions or enhancements, contact the project owner or open an issue in the repository.
