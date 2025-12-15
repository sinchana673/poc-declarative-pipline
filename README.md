# poc-retail-declarative-pipline
# Declarative Medallion Pipeline (Databricks + Delta)

This project is a proof-of-concept declarative data pipeline implemented on Databricks using the Medallion Lakehouse architecture (Bronze, Silver, Gold). It ingests raw CSV files into streaming Bronze tables, applies data quality rules and constraints in Silver streaming Delta tables, and exposes curated Gold materialized views for analytics and dashboards.[web:20]

## Architecture Overview

- **Bronze Layer (Streaming Tables)**  
  - Ingests raw CSV files from `/Volumes/workspace/declarative_poc/volume/data/raw/*`.  
  - Uses `read_files` as a streaming source with `includeExistingFiles = true` to capture both historical and new data.  
  - Adds `load_timestamp` and `source_file` metadata columns for traceability and lineage.  

- **Silver Layer (Streaming Delta Tables)**  
  - Consumes data from Bronze streaming tables.  
  - Removes nulls and duplicates using `SELECT DISTINCT` and `WHERE` filters.  
  - Enforces business rules (valid emails, positive price/quantity, non-future dates).  
  - Implements referential integrity in the `silver_sales` table using `EXISTS` checks against Customers, Products, and Stores.  

- **Gold Layer (Materialized Views)**  
  - Builds business-ready, aggregated tables on top of Silver.  
  - Uses `CREATE OR REFRESH MATERIALIZED VIEW` for performant, incremental refresh.  
  - Provides store-, product-, customer-, and day-level metrics for BI tools and dashboards.  

## Tables and Views

| Layer  | Object                               | Description |
|--------|--------------------------------------|-------------|
| Bronze | `bronze_customers`                  | Raw customers from CSV with load timestamp and source file metadata. |
| Bronze | `bronze_products`                   | Raw products with price, currency, and metadata. |
| Bronze | `bronze_stores`                     | Raw stores with location and opened date. |
| Bronze | `bronze_sales`                      | Raw sales transactions with quantities and prices. |
| Silver | `silver_customers`                  | Cleaned, deduplicated customers with email/phone and basic validation. |
| Silver | `silver_products`                   | Valid products with positive price and non-future launch dates. |
| Silver | `silver_stores`                     | Valid stores with non-future opened dates. |
| Silver | `silver_sales`                      | Sales with positive quantity/price, valid dates, and referential integrity to customers, products, and stores. |
| Gold   | `gold_store_sales`                  | Store-level revenue, quantity, and sales counts. |
| Gold   | `gold_product_sales`                | Product-level revenue and quantity by category. |
| Gold   | `gold_customer_sales`               | Customer-level spend, order count, and average order value. |
| Gold   | `gold_daily_sales`                  | Daily revenue and volume per store. |
| Gold   | `gold_top_products`                 | Top-selling products per store by quantity and revenue. |

## How to Run in Databricks

1. **Create the Catalog and Volume**  
   - Create the catalog and schema (e.g. `workspace.declarative_poc`) and the external volume pointing to your raw data paths.  
   - Place CSV files under:
     - `/Volumes/workspace/declarative_poc/volume/data/raw/customers/`
     - `/Volumes/workspace.declarative_poc/volume/data/raw/products/`
     - `/Volumes/workspace.declarative_poc/volume/data/raw/stores/`
     - `/Volumes/workspace.declarative_poc/volume/data/raw/sales/`

2. **Deploy the Bronze Layer**  
   - Run the SQL script that defines the four `CREATE OR REFRESH STREAMING TABLE` statements for `bronze_customers`, `bronze_products`, `bronze_stores`, and `bronze_sales`.  
   - Confirm that streaming tables start ingesting data and the metadata columns are populated.  

3. **Deploy the Silver Layer**  
   - Run the SQL script for the Silver streaming tables (`silver_customers`, `silver_products`, `silver_stores`, `silver_sales`).  
   - Validate data quality rules:
     - No null `customer_id`, `product_id`, `store_id`, `sale_id` where required.
     - Positive `price` and `quantity`.
     - Non-future `launch_date`, `opened_date`, and `sale_date`.
     - `silver_sales` only contains records that exist in the corresponding Silver dimension tables.  

4. **Deploy the Gold Layer**  
   - Execute the script that creates the materialized views:
     - `gold_store_sales`
     - `gold_product_sales`
     - `gold_customer_sales`
     - `gold_daily_sales`
     - `gold_top_products`  
   - Use these views as sources for dashboards or downstream analytics tools.  

5. **Scheduling & Refresh**  
   - Configure Databricks jobs or workflows to:
     - Keep Bronze and Silver streaming tables running or triggered on a schedule.  
     - Periodically refresh Gold materialized views if needed, depending on latency requirements.[web:20]  

## Project Structure

A typical layout for this repository is:

├── README.md
├── PROJECT_DOCUMENTATION.md
├── sql
│ ├── 01_bronze_layer.sql
│ ├── 02_silver_layer.sql
│ └── 03_gold_layer.sql
└── notebooks


- `PROJECT_DOCUMENTATION.md` contains the detailed description of each layer and the full SQL definitions.  
- `sql/` holds the executable SQL scripts you can run directly in Databricks.  

## Prerequisites

- Databricks workspace with Delta Live Tables / streaming tables and materialized views enabled.  
- Access to create catalogs, schemas, and volumes in the `workspace.declarative_poc` namespace.  
- CSV data files in the expected raw directories under the configured volume.  

## Future Enhancements

- Add unit/integration tests for data quality rules.  
- Add CI/CD with Databricks Repos and GitHub Actions for automated deployment.  
- Extend Gold views with additional dimensions (time, geography, channels) and KPIs.  

