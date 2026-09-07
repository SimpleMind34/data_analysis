ALTER TABLE `online_retail_ii` 
RENAME COLUMN customer_id TO CustomerID;

SELECT COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'online_retail_store'
  AND TABLE_NAME = 'online_retail_ii';
  
SELECT COUNT(*) AS total_rows 
FROM online_retail_ii;

select * from online_retail_ii;


-- Create the clean staging table in one single pass
CREATE TABLE online_retail_staging AS
SELECT 
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price AS UnitPrice,
    CAST(CustomerID AS UNSIGNED) AS CustomerID,
    (Quantity * Price) AS TotalLineAmount
FROM online_retail_ii
WHERE CustomerID IS NOT NULL 
  AND CustomerID != ''
  AND Invoice NOT LIKE 'C%'
  AND Invoice NOT LIKE 'c%'
  AND Quantity > 0
  AND Price > 0;
  
  -- Step 1: Calculate raw Recency, Frequency, and Monetary values per customer
CREATE TABLE rfm_raw AS
SELECT 
    CustomerID,
    DATEDIFF(
		(SELECT DATE_ADD(MAX(InvoiceDate), INTERVAL 1 DAY) from online_retail_staging)
        , MAX(s.InvoiceDate)
        ) AS recency_days,
    COUNT(DISTINCT Invoice) AS frequency_orders,
    ROUND(SUM(TotalLineAmount), 2) AS monetary_value
FROM online_retail_staging 
GROUP BY CustomerID;

select * from rfm_raw;

CREATE TABLE rfm_scores AS
SELECT 
    CustomerID,
    recency_days,
    frequency_orders,
    monetary_value,
    NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(4) OVER (ORDER BY frequency_orders ASC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary_value ASC) AS m_score
FROM rfm_raw;

select * from rfm_scores;

-- Step 3: Combine scores into named segments
CREATE TABLE rfm_segmented AS
SELECT 
    CustomerID,
    recency_days,
    frequency_orders,
    monetary_value,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell,
    CASE 
        WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score < 3 THEN 'Promising / New'
        WHEN r_score = 2 AND f_score >= 2 THEN 'At Risk'
        WHEN r_score = 1 AND f_score >= 3 THEN 'Cant Lose Them'
        WHEN r_score = 1 AND f_score < 3 THEN 'Lost'
        ELSE 'Needs Attention'
    END AS customer_segment
FROM rfm_scores;

select * from rfm_segmented;

-- Check distribution of segments and total spend per segment
SELECT 
    customer_segment,
    COUNT(CustomerID) AS total_customers,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency_orders), 1) AS avg_orders,
    ROUND(AVG(monetary_value), 2) AS avg_spend,
    ROUND(SUM(monetary_value), 2) AS total_revenue
FROM rfm_segmented
GROUP BY customer_segment
ORDER BY total_revenue DESC;