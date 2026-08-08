# 🛒 Olist E-Commerce End-to-End SQL Analytics Suite

## 📌 Executive Summary
This repository delivers an enterprise-grade relational database solution and executive analytics suite for **Olist**, the largest e-commerce department store marketplace in Brazil. 

Using **MySQL**, the project spans the full data engineering and analytics lifecycle: initial schema staging, defensive data cleansing, complex multi-table relational joins with fallback imputation, and executive reporting for leadership (COO / CFO).

---

## 🗄️ Repository Structure
```
olist-ecommerce-analytics/
│
├── README.md                          <-- Project Documentation
├── docs/
│   └── entity_relationship_diagram.png <-- ERD Schema Diagram
│
├── sql_scripts/
│   ├── 01_schema_setup_and_cleaning.sql  <-- Staging, Deduplication & Type Casting
│   └── 02_exploratory_data_analysis.sql  <-- Executive Reports (COO/CFO Prompts)
│
└── executive_summary.md                <-- High-level Business Takeaways
```

---

## 🛠️ Key Technical Solutions & Architecture

### 1. Defensive Schema Staging & Cleansing
* **Primary Key Integrity & Deduplication:** Audited table granularity using window functions (`ROW_NUMBER() OVER (PARTITION BY ...)`).
* **Null Value Standardization:** Handled empty strings (`''`) to standardize date fields into true `NULL`s before running timestamp functions, mitigating MySQL `Error 1292`.

### 2. Relational Analytics & Fallback Imputation
* **Logistics Performance Analysis:** Calculated actual delivery duration vs. estimated delivery windows dynamically using CTEs without altering underlying base tables.
* **Multi-Language Category Attribution:** Solved missing translations across 4 relational tables using a 3-tier `COALESCE()` fallback ladder:
  $$\text{Category} = \text{COALESCE}(\text{English Translation}, \text{Portuguese Name}, \text{'Uncategorized'})$$

---

## 📊 Core Analytical Scripts (`02_exploratory_data_analysis.sql`)

### Scenario 1: Operations Delivery Health Audit (COO Request)
```sql
WITH clean_orders AS (
    SELECT 
        order_id,
        order_status,
        TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delivery_duration,
        CASE 
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
            ELSE 'Delayed'
        END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered' 
      AND order_delivered_customer_date IS NOT NULL
)
SELECT 
    delivery_status,
    COUNT(order_id) AS orders_num,
    ROUND(AVG(delivery_duration), 1) AS avg_delivery_duration
FROM clean_orders
GROUP BY delivery_status;
```

### Scenario 2: Revenue Category Audit (CFO Request)
```sql
SELECT  
    COALESCE(
        pc.product_category_name_english,  
        op.product_category_name,
        'Uncategorized'                  
    ) AS product_category,
    ROUND(SUM(oo.price), 2) AS total_revenue,
    ROUND(SUM(oo.freight_value), 2) AS total_freight
FROM orders o
LEFT JOIN olist_order_items_dataset oo
    ON o.order_id = oo.order_id
LEFT JOIN olist_products_dataset op
    ON oo.product_id = op.product_id
LEFT JOIN product_category_name_translation pc
    ON op.product_category_name = pc.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 10;
```

### 📊 Sprint 3: Regional Customer Lifetime Value & State Rankings

#### **Business Problem**
The Growth and Sales leadership teams wanted to identify key customer segments across regions. Specifically, they needed a regional leaderboard showing the **Top 5 highest-spending customers per state**, alongside their order count and total lifetime value (LTV).

#### **Technical Challenges Solved**
1. **Fan-Out Prevention:** Joining `olist_order_items_dataset` (one-to-many) directly with `orders` creates duplicate rows per item. Pre-aggregating spend at the `order_id` level inside `total_orders` ensured accurate financial numbers.
2. **Window Function Partitioning:** Utilized `DENSE_RANK() OVER (PARTITION BY customer_state ORDER BY lifetime_spend DESC)` to independently calculate regional rankings without collapsing the dataset.
3. **Multi-Stage Processing:** Used a 4-stage CTE chain to keep transformation logic modular, readable, and performant.

#### **Sample Output Structure**
| customer_state | state_rank | customer_unique_id | order_count | lifetime_spend |
|---|---|---|---|---|
| AC | 1 | `78a...` | 1 | $1,250.80 |
| AC | 2 | `2bc...` | 2 | $980.50 |
| ... | ... | ... | ... | ... |
| SP | 1 | `0a1...` | 4 | $6,920.00 |
---

### 📊 Sprint 4: Regional Sales Summary Executive View

#### **Business Goal**
Executive stakeholders need high-level visibility into monthly revenue trends and Average Order Value (AOV) across geographic regions without needing to re-run heavy 3-table joins across millions of order items.

#### **Technical Highlights & Best Practices**
1. **Grain Control & Accuracy:** Grouped by `state, sales_month` to preserve granular time-series analytics. Utilized `COUNT(DISTINCT o.order_id)` rather than simple `COUNT()` to prevent item-level fan-out from inflating total order metrics.
2. **Standardized Business Metrics:** Encapsulates gross revenue (`price + freight_value`) and calculates monthly per-order averages directly at the database layer.
3. **Optimized Analytics Layer:** Reusable view for direct connection to BI tools (Power BI / Tableau) or automated reporting queries.

#### **View Definition**

```sql
CREATE OR REPLACE VIEW vw_regional_sales_summary AS 
SELECT 
    c.customer_state AS state,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oo.price + oo.freight_value), 2) AS monthly_revenue,
    ROUND(
        SUM(oo.price + oo.freight_value) / COUNT(DISTINCT o.order_id), 
        2
    ) AS avg_order_value
FROM olist_order_items_dataset oo 
JOIN orders o 
    ON oo.order_id = o.order_id 
JOIN olist_customers_dataset c 
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');

### ⚙️ Sprint 4: Automated Customer Lookup Stored Procedure

#### **Business Goal**
Customer support and analytical teams frequently need to audit individual customer histories without writing manual multi-table joins. This module automates customer order tracking through a reusable MySQL Stored Procedure.

#### **Technical Highlights & Best Practices**
1. **Preventing Variable Shadowing:** Used the `p_` naming convention (`p_customer_unique_id`) for procedure parameters to prevent column-name collision inside the `WHERE` clause.
2. **Defensive Validation & Exception Handling:** Incorporated an `IF NOT EXISTS` pre-check with `SIGNAL SQLSTATE '45000'` to raise a explicit error if an invalid ID is provided.
3. **Optimized Aggregation:** Pre-validates existence before joining datasets, avoiding unnecessary database operations on invalid lookups.

#### **Procedure Usage**

```sql
-- Execute lookup for a valid customer:
CALL sp_get_customer_history('8d5054d015c90be01a6c7b6b2fe5f07b');

-- Result Set:
-- +----------------------------------+----------------------------------+--------------+-------------+
-- | customer_unique_id               | order_id                         | order_status | total_spent |
-- +----------------------------------+----------------------------------+--------------+-------------+
-- | 8d5054d015c90be01a6c7b6b2fe5f07b | 128a101a029302198031208a38109312 | delivered    | 142.50      |
-- +----------------------------------+----------------------------------+--------------+-------------+

### 🔔 Sprint 5: Automated Order Audit System & Triggers

#### **Business Problem**
In an enterprise e-commerce system, tracking the lifecycle of an order is critical for operational visibility, logistics SLA auditing, and dispute management. Updating order states directly on the main database can obscure historical lifecycle transitions if changes are overwritten.

#### **Technical Implementation**
1. **Dedicated Audit Schema (`order_status_audit`):** Created an append-only audit tracking table that captures state transitions with auto-incrementing surrogate keys and automated timestamps (`updated_at`).
2. **Event-Driven Audit Trigger (`trg_log_order_status_change`):** Implemented an `AFTER UPDATE` row-level trigger on the core `orders` table.
3. **Change Validation:** Enclosed insert execution inside an `IF OLD.order_status <> NEW.order_status` block to prevent redundant logging during non-status field updates (e.g., date corrections).

#### **Database Objects Definition**

```sql
-- Audit Schema
CREATE TABLE IF NOT EXISTS order_status_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Event Trigger
DROP TRIGGER IF EXISTS trg_log_order_status_change;

DELIMITER $

CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON orders 
FOR EACH ROW
BEGIN
    IF OLD.order_status <> NEW.order_status THEN
        INSERT INTO order_status_audit (order_id, old_status, new_status) 
        VALUES (NEW.order_id, OLD.order_status, NEW.order_status);
    END IF;
END $

DELIMITER ;

-- Test Trigger Action
UPDATE orders 
SET order_status = 'shipped' 
WHERE order_id = '1a9543c90f188e2e4fb14327ad4a9c9b';

UPDATE orders 
SET order_status = 'delivered' 
WHERE order_id = '1a9543c90f188e2e4fb14327ad4a9c9b';

-- Query Audit Trail
SELECT * FROM order_status_audit;

-- Result Set:
-- +----------+----------------------------------+------------+------------+---------------------+
-- | audit_id | order_id                         | old_status | new_status | updated_at          |
-- +----------+----------------------------------+------------+------------+---------------------+
-- | 1        | 1a9543c90f188e2e4fb14327ad4a9c9b | processing | shipped    | 2026-08-08 17:28:00 |
-- | 2        | 1a9543c90f188e2e4fb14327ad4a9c9b | shipped    | delivered  | 2026-08-08 17:28:05 |
-- +----------+----------------------------------+------------+------------+---------------------+

### 🧹 Sprint 5 (Task 2): Automated Maintenance via Scheduled Events

#### **Business Goal**
Audit logs grow rapidly over time in transactional systems. Retaining stale logs indefinitely degrades database performance and increases storage overhead. This module automates background database hygiene by running automated cleanup jobs during off-peak hours.

#### **Technical Highlights & Best Practices**
1. **Background Job Automation:** Utilized MySQL's native `EVENT` engine to schedule recurring maintenance without external dependencies (e.g., cron jobs or Airflow).
2. **Predictable Nightly Scheduling:** Configured execution using dynamic date math (`CURRENT_DATE + INTERVAL 1 DAY`) to target midnight execution daily.
3. **Rolling Retention Window:** Enforced a strict 30-day log retention policy using `NOW() - INTERVAL 30 DAY`.

#### **Event Definition**

```sql
SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS evt_daily_sales_cleanup;

DELIMITER $

CREATE EVENT evt_daily_sales_cleanup
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 0 HOUR)
DO
BEGIN
    DELETE FROM order_status_audit
    WHERE updated_at < NOW() - INTERVAL 30 DAY;
END $

DELIMITER ;

## 🚀 Getting Started
1. Clone the repo: `git clone https://github.com/yourusername/olist-ecommerce-analytics.git`
2. Download the Olist dataset from Kaggle and load CSVs into your MySQL database.
3. Run `sql_scripts/01_schema_setup_and_cleaning.sql` for table setup.
4. Execute `sql_scripts/02_exploratory_data_analysis.sql` to generate executive reports.