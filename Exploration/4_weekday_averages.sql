/*
Objective: Identify weekday sales trends to support business decisions
*/


-- Which days of the week have the most orders?
-- This will let us know which days of the week have the highest volume
-- This metric could affect staffing, allowing for more hours to be allotted to
-- high traffic days of the week.

WITH daily_orders AS (
    SELECT
        o.order_id,
        TRIM(TO_CHAR(o.order_date, 'Day')) AS order_day
    FROM order_details o
) 
SELECT 
    order_day,
    COUNT(DISTINCT order_id) AS daily_total_orders --Overall count may include invalid orders or orders without menu items
FROM daily_orders 
GROUP BY order_day
ORDER BY daily_total_orders DESC;


-- Which day of the week has the highest SUM of sales?
SELECT
    TRIM(TO_CHAR(o.order_date, 'Day')) AS order_day,
    SUM(m.price) AS total_price
FROM order_details o
INNER JOIN menu_items m ON o.item_id = m.menu_item_id
GROUP BY order_day
ORDER BY total_price DESC;



-- Which day of the week has the highest average order value?
-- How do individual orders compare to their weekday baseline?
-- This helps determine whether averages are driven by outliers
-- or reflect typical customer behavior.


-- Adding on to our daily order count we are going to get the average daily sales
WITH order_totals AS (
    SELECT
        o.order_id,
        TRIM(TO_CHAR(o.order_date, 'Day')) AS order_day,
        SUM(m.price) AS order_total
    FROM order_details o
    INNER JOIN menu_items m -- Using INNER JOIN to ensure we only count orders with valid menu items
        ON o.item_id = m.menu_item_id 
    GROUP BY o.order_id, order_day
) SELECT
    order_day,
    COUNT(DISTINCT order_id) AS total_daily_orders,
    ROUND(AVG(order_total), 2) AS avg_order_value
FROM order_totals
GROUP BY order_day
ORDER BY avg_order_value DESC;


-- Finally, we will compare individual orders to their weekday baseline
-- check whether weekday averages are driven by outliers
-- or reflect typical order behavior

WITH order_price AS (
    SELECT
        o.order_id,
        TRIM(TO_CHAR(o.order_date, 'Day')) AS order_day,
        SUM(m.price) AS total_price
    FROM order_details o
    INNER JOIN menu_items m ON o.item_id = m.menu_item_id
    GROUP BY 
        o.order_id, 
        order_day
), sum_of_sales AS (
    SELECT
        TRIM(TO_CHAR(o.order_date, 'Day')) AS order_day,
        SUM(m.price) AS total_daily_sales
    FROM order_details o
    INNER JOIN menu_items m ON o.item_id = m.menu_item_id
    GROUP BY 
        order_day
) SELECT 
    order_id,
    order_price.order_day,
    total_price,
    total_daily_sales,
    ROUND(AVG(total_price) OVER(PARTITION BY order_price.order_day),2) AS average_day_price,
    total_price - AVG(total_price) OVER(PARTITION BY order_price.order_day) AS diff_from_avg,
    COUNT(order_id) OVER(PARTITION BY order_price.order_day) AS total_daily_orders,
    CASE 
        WHEN total_price > AVG(total_price) OVER(PARTITION BY order_price.order_day) THEN 'Above Average'
        ELSE 'Below Average'
    END AS avg_order_comparison
FROM order_price
LEFT JOIN sum_of_sales ON order_price.order_day = sum_of_sales.order_day
;


/*
Insights:
    - Monday has overall low average sale price by order but has the highest total sales and order volume
    - Tuesday has the highest average sales, but the third highest overall sales and low volume
    - Friday consistently has high sales, high volume, and a high average order cost
*/