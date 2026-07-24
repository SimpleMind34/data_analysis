select * from olist_customers_dataset;
select * from olist_order_payments_dataset;
select  * from olist_orders_dataset;

-- join them all in one table
CREATE TABLE raw_customer_orders AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_city,
    c.customer_state,
    p.payment_type,
    p.payment_value
FROM olist_orders_dataset o
LEFT JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id;

-- start cleaning

-- all the time stamps in this column end with 00:00:00
select order_estimated_delivery_date 
from raw_customer_orders
where substring(order_estimated_delivery_date,12) != '00:00:00'; -- /nothing returns

-- so it's not needed, good for saving space
update raw_customer_orders
set order_estimated_delivery_date = substring(order_estimated_delivery_date,1,10)
WHERE order_estimated_delivery_date IS NOT NULL 
  AND order_estimated_delivery_date != '';


select order_estimated_delivery_date
from raw_customer_orders
limit 5;


-- now we format it 

-- UPDATE raw_customer_orders
-- SET order_purchase_timestamp = STR_TO_DATE(order_estimated_delivery_date, '%Y-%m-%d');
-- this is a huge blunder, will make us loose all our data!! let's fix it.
-- since we have the original tables, we can just update our values with a join

-- updating a large data set directly can cause issues like timing out
-- so we have to do some things first
SET net_read_timeout = 600;
SET net_write_timeout = 600;
SET innodb_lock_wait_timeout = 600;
-- these updates will make the timing out happen after a longer period


CREATE INDEX idx_raw_order_id ON raw_customer_orders(order_id(255));
CREATE INDEX idx_orig_order_id ON olist_orders_dataset(order_id(255));
-- these indexes will make the joining happen instantly

-- now let's update
UPDATE raw_customer_orders target
JOIN olist_orders_dataset source 
    ON target.order_id = source.order_id
SET target.order_purchase_timestamp = source.order_purchase_timestamp;

-- these next lines will allow smooth formatting update
-- also a good practice to turn all blank values to null
UPDATE raw_customer_orders
SET order_purchase_timestamp = NULL
WHERE order_purchase_timestamp = '' 
   OR TRIM(order_purchase_timestamp) = '';
   
UPDATE raw_customer_orders
SET order_purchase_timestamp = STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s')
WHERE order_purchase_timestamp IS NOT NULL 
  AND order_purchase_timestamp != '';

UPDATE raw_customer_orders
SET order_delivered_customer_date = NULL
WHERE order_delivered_customer_date = '' 
   OR TRIM(order_delivered_customer_date) = '';
   
UPDATE raw_customer_orders
SET order_delivered_customer_date = STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
WHERE order_delivered_customer_date IS NOT NULL 
  AND order_delivered_customer_date != '';
  
-- final step on the dates formatting; updating our data types
ALTER TABLE raw_customer_orders 
    MODIFY COLUMN order_purchase_timestamp DATETIME,
    MODIFY COLUMN order_delivered_customer_date DATETIME,
    MODIFY COLUMN order_estimated_delivery_date DATE;
    
-- we are done with dates, let's go to our locations
select customer_city, customer_state 
from raw_customer_orders
limit 100;

select customer_city, customer_state
from raw_customer_orders
where customer_city like ' %'
or customer_state like ' %';

update raw_customer_orders
set customer_city = trim(customer_city)
where customer_city is not null;

update raw_customer_orders
set customer_state = trim(customer_state)
where customer_state is not null;

select customer_city, customer_state
from raw_customer_orders
limit 100;

update raw_customer_orders
set customer_city = upper(customer_city);

select payment_type
from raw_customer_orders
where payment_type is null
limit 100;

update raw_customer_orders
set payment_type = 'Unspecified'
where payment_type is null
or payment_type = '';

select payment_type
from raw_customer_orders
where payment_type = 'Unspecified'
limit 100;

-- finding duplicates
select *, ROW_NUMBER() OVER(PARTITION BY order_id, customer_id ORDER BY order_purchase_timestamp)
from raw_customer_orders;

with duplicate_finder as (
select *, ROW_NUMBER() OVER(PARTITION BY order_id, customer_id ORDER BY order_purchase_timestamp) row_num
from raw_customer_orders)
select * 
from duplicate_finder
where row_num > 1;

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM raw_customer_orders;

DELETE r
FROM raw_customer_orders r
JOIN (
    SELECT 
        order_id,
        customer_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER(
            PARTITION BY order_id, customer_id 
            ORDER BY order_purchase_timestamp
        ) AS row_num
    FROM raw_customer_orders
) ranked ON r.order_id = ranked.order_id 
        AND r.customer_id = ranked.customer_id
WHERE ranked.row_num > 1;

