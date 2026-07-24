select * from raw_customer_orders
where order_delivered_customer_date > order_estimated_delivery_date;

select customer_state,
count(order_delivered_customer_date > order_estimated_delivery_date)
from raw_customer_orders
where customer_state is not null
group by customer_state;

SELECT 
    customer_state,
    SUM(order_delivered_customer_date > order_estimated_delivery_date) AS late_orders_count,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_delivered_customer_date > order_estimated_delivery_date) * 100, 2) AS late_delivery_rate_pct
FROM raw_customer_orders
WHERE customer_state IS NOT NULL
GROUP BY customer_state
ORDER BY late_orders_count DESC;

WITH customer_spend AS (
    SELECT 
        customer_id,
        SUM(payment_value) AS total_spent,
        NTILE(3) OVER (ORDER BY SUM(payment_value) DESC) AS spend_tile
    FROM raw_customer_orders
    GROUP BY customer_id
)
SELECT 
    customer_id,
    total_spent,
    CASE 
        WHEN spend_tile = 1 THEN 'High Spenders'
        WHEN spend_tile = 2 THEN 'Mid Spenders'
        WHEN spend_tile = 3 THEN 'Low Spenders'
    END AS spending_tier
FROM customer_spend;

WITH customer_spend AS (
    SELECT 
        customer_id,
        SUM(payment_value) AS total_spent,
        PERCENT_RANK() OVER (ORDER BY SUM(payment_value) DESC) AS pct_rank
    FROM raw_customer_orders
    GROUP BY customer_id
)
SELECT 
    customer_id,
    total_spent,
    CASE 
        WHEN pct_rank <= 0.15 THEN 'High Spenders'
        WHEN pct_rank <= 0.50 THEN 'Mid Spenders'
        ELSE 'Low Spenders'
    END AS spending_tier
FROM customer_spend;

WITH customer_spend AS (
    SELECT 
        customer_id,
        SUM(payment_value) AS total_spent
    FROM raw_customer_orders
    GROUP BY customer_id
)
SELECT 
    customer_id,
    total_spent,
    CASE 
        WHEN total_spent >= 300 THEN 'High Spenders'
        WHEN total_spent >= 100 THEN 'Mid Spenders'
        ELSE 'Low Spenders'
    END AS spending_tier
FROM customer_spend;

with rolling_total as (
select date_format(order_purchase_timestamp, '%Y-%m') `month`, 
sum(payment_value) total_spent
from raw_customer_orders
group by `month`
-- having total_spent is not null
order by `month`)
select `month`, total_spent, sum(total_spent) over (order by `month`) rol_tot
from rolling_total;


