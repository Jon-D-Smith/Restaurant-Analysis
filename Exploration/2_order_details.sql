/*
Objective 2
Explore the orders table
Your second objective is to better understand the orders table by finding
the date range, the number of items within each order, and the orders with 
the highest number of items.
*/

-- View the order_details table. 

SELECT *
FROM order_details;

-- What is the date range of the table?

SELECT
    MIN(order_date),
    MAX(order_date)
FROM order_details;

-- How many orders were made within this date range?

SELECT 
    COUNT(DISTINCT order_id)
FROM order_details;

-- How many items were ordered within this date range?

SELECT 
    COUNT(*)
FROM order_details;

-- Which orders had the most number of items?

SELECT 
    order_id,
    COUNT(item_id) AS item_count
FROM order_details
GROUP BY order_id
ORDER BY item_count DESC;


-- How many orders had more than 12 items?
SELECT COUNT(*)
FROM (
SELECT 
    COUNT(item_id) AS item_count
FROM order_details
GROUP BY order_id
HAVING
    COUNT(item_id) > 12
ORDER BY item_count DESC
);