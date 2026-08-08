-- ==============================================================================
-- Script 02: Exploratory Data Analysis & Executive Reporting
-- Project: Olist E-Commerce Analytics
-- Objective: Evaluate logistics metrics and localized category revenue
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Scenario 1: Operations Delivery Health Audit (COO Request)
-- Objective: Calculate on-time vs. delayed orders and average fulfillment speed
-- ------------------------------------------------------------------------------

WITH clean_orders AS (
    SELECT 
        order_id,
        order_status,
        -- Calculate delivery duration dynamically
        TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delivery_duration,
        -- Categorize logistics performance on the fly
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

-- ------------------------------------------------------------------------------
-- Scenario 2: Revenue Category Audit (CFO Request)
-- Objective: Rank top 10 product categories by total sales and freight costs
-- ------------------------------------------------------------------------------

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
    ON op.product_category_name = pc.﻿product_category_name
WHERE o.order_status = 'delivered'
GROUP BY 
    COALESCE(
        pc.product_category_name_english,  
        op.product_category_name,
        'Uncategorized'                  
    )
ORDER BY total_revenue DESC
LIMIT 10;

-- ==============================================================================
-- Milestone 3: Business Intelligence & Customer Analytics
-- Objective: Rank Top 5 repeat spenders per state using CTEs & Window Functions
-- ==============================================================================

WITH total_orders AS (
    -- Step 1: Pre-aggregate price + freight at order level to prevent fan-out
    SELECT 
        order_id, 
        ROUND(SUM(price + freight_value), 2) AS total_spend
    FROM olist_order_items_dataset 
    GROUP BY order_id
),

customer_linked_to_orders AS (
    -- Step 2: Connect delivered orders to unique customer identities and states
    SELECT 
        o.order_id, 
        c.customer_unique_id, 
        c.customer_state, 
        t_o.total_spend
    FROM total_orders t_o 
    JOIN orders o 
        ON t_o.order_id = o.order_id
    JOIN olist_customers_dataset c 
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

rolling_up_total_spend AS (
    -- Step 3: Aggregate customer lifetime spend and total order count
    SELECT 
        customer_unique_id, 
        customer_state,
        COUNT(order_id) AS order_count, 
        ROUND(SUM(total_spend), 2) AS lifetime_spend
    FROM customer_linked_to_orders
    GROUP BY customer_unique_id, customer_state
),

ranking_customers_per_state AS (
    -- Step 4: Rank spenders per state using DENSE_RANK to handle spend ties cleanly
    SELECT 
        customer_unique_id, 
        customer_state, 
        order_count,
        lifetime_spend,
        DENSE_RANK() OVER (
            PARTITION BY customer_state 
            ORDER BY lifetime_spend DESC
        ) AS state_rank
    FROM rolling_up_total_spend
) 

-- Final Output: Top 5 spenders grouped cleanly by state
SELECT 
    customer_state,
    state_rank,
    customer_unique_id,
    order_count,
    lifetime_spend
FROM ranking_customers_per_state
WHERE state_rank <= 5
ORDER BY customer_state, state_rank;

-- ==============================================================================
-- Milestone 4: Database Views & Business Automation
-- Task 1: vw_regional_sales_summary (Executive KPI View)
-- Objective: Aggregates monthly revenue and AOV by state without item fan-out
-- ==============================================================================

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

-- Example View Verification:
-- SELECT * FROM vw_regional_sales_summary WHERE state = 'SP' ORDER BY sales_month DESC;

-- ==============================================================================
-- Milestone 4: Database Automation & Stored Procedures
-- Procedure: sp_get_customer_history
-- Objective: Retrieve full order history and total spend for a specific customer
-- Features: Parameter shadowing prevention, EXISTS check, custom exception SIGNAL
-- ==============================================================================

DROP PROCEDURE IF EXISTS sp_get_customer_history;

DELIMITER $

CREATE PROCEDURE sp_get_customer_history (
    IN p_customer_unique_id VARCHAR(255)
)
BEGIN
    -- 1. Defensive Check: Verify customer existence to prevent unnecessary joins
    IF NOT EXISTS (
        SELECT 1 
        FROM olist_customers_dataset 
        WHERE customer_unique_id = p_customer_unique_id
    ) THEN
        SELECT CONCAT('Customer ID "', p_customer_unique_id, '" was not found.') AS message;
    ELSE
    -- 2. Main Query: Aggregate spend and retrieve order statuses
    SELECT 
        c.customer_unique_id, 
        o.order_id, 
        o.order_status,
        ROUND(SUM(oo.price + oo.freight_value), 2) AS total_spent 
    FROM orders o 
    JOIN olist_order_items_dataset oo
        ON o.order_id = oo.order_id
    JOIN olist_customers_dataset c
        ON c.customer_id = o.customer_id
    WHERE c.customer_unique_id = p_customer_unique_id
    GROUP BY c.customer_unique_id, o.order_id, o.order_status;
    END IF;
END $

DELIMITER ;

-- Test Execution:
CALL sp_get_customer_history('8d5054d015c90be01a6c7b6b2fe5f07b');

-- ==============================================================================
-- Milestone 5: Triggers & Audit Automation
-- Task 1: Order Status Change Audit System
-- Objective: Automatically log order lifecycle updates into a dedicated audit table
-- ==============================================================================

-- 1. Create Audit Log Table
CREATE TABLE IF NOT EXISTS order_status_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create Audit Trigger
DROP TRIGGER IF EXISTS trg_log_order_status_change;

DELIMITER $

CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON orders 
FOR EACH ROW
BEGIN
    -- Log changes only when order_status changes value
    IF OLD.order_status <> NEW.order_status THEN
        INSERT INTO order_status_audit (order_id, old_status, new_status) 
        VALUES (NEW.order_id, OLD.order_status, NEW.order_status);
    END IF;
END $

DELIMITER ;

-- Example Trigger Test Execution:
-- UPDATE orders SET order_status = 'shipped' WHERE order_id = '1a9543c90f188e2e4fb14327ad4a9c9b';
-- UPDATE orders SET order_status = 'delivered' WHERE order_id = '1a9543c90f188e2e4fb14327ad4a9c9b';
-- SELECT * FROM order_status_audit;

-- ==============================================================================
-- Milestone 5: Database Maintenance Automation
-- Task 2: Scheduled Audit Cleanup Event
-- Objective: Automatically purge audit log entries older than 30 days every night
-- ==============================================================================

-- 1. Ensure Event Scheduler Thread is Active
SET GLOBAL event_scheduler = ON;

-- 2. Create Maintenance Event
DROP EVENT IF EXISTS evt_daily_sales_cleanup;

DELIMITER $

CREATE EVENT evt_daily_sales_cleanup
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 0 HOUR)
DO
BEGIN
    -- Remove audit records older than 30 days to optimize storage
    DELETE FROM order_status_audit
    WHERE updated_at < NOW() - INTERVAL 30 DAY;
END $

DELIMITER ;

-- Verification Queries:
-- SHOW EVENTS FROM olist_db;
-- SHOW CREATE EVENT evt_daily_sales_cleanup;

