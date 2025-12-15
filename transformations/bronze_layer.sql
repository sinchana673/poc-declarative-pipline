-- ===============================================================
-- BRONZE LAYER STREAMING TABLES
-- Description: Ingest raw CSV files from /volume/data/raw/
--              into Bronze streaming tables with processing
--              timestamp and source file information.
-- ===============================================================


-- ===============================================================
-- Bronze Customers Table
-- Description: Ingest all customer data from raw folder
-- ===============================================================
CREATE OR REPLACE streaming table workspace.declarative_poc.bronze_customers
AS
SELECT
    *,
    current_timestamp() AS load_timestamp,
    _metadata.file_name AS source_file
FROM STREAM read_files(
    '/Volumes/workspace/declarative_poc/volume/data/raw/customers/',
    format => 'csv',
    header => 'true',
    includeExistingFiles => 'true'
);


-- ===============================================================
-- Bronze Products Table
-- Description: Ingest all product data from raw folder
-- ===============================================================
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


-- ===============================================================
-- Bronze Stores Table
-- Description: Ingest all store data from raw folder
-- ===============================================================
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


-- ===============================================================
-- Bronze Sales Table
-- Description: Ingest all sales data from raw folder
-- ===============================================================
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
