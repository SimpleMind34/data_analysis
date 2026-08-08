-- ==============================================================================
-- Script 01: Schema Setup & Data Cleansing Pipeline
-- Project: Olist E-Commerce Analytics
-- Objective: Stage raw order data, verify PK uniqueness, and standardize nulls
-- ==============================================================================

-- 1. Create Staging Table (Preserve Raw Ingestion)
CREATE TABLE IF NOT EXISTS orders AS
SELECT * FROM olist_orders_dataset;

-- 2. Audit: Check Primary Key Integrity & Deduplication
WITH duplicate_removal AS (
    SELECT *, 
           ROW_NUMBER() OVER(
               PARTITION BY order_id, customer_id, order_status, 
                            order_purchase_timestamp, order_approved_at, 
                            order_delivered_customer_date, order_delivered_carrier_date, 
                            order_estimated_delivery_date
           ) AS row_num
    FROM orders
) 
SELECT * FROM duplicate_removal
WHERE row_num > 1;

-- 3. Data Cleansing: Standardize Empty Strings to True NULLs
UPDATE orders
SET order_delivered_customer_date = NULL
WHERE order_delivered_customer_date = '';