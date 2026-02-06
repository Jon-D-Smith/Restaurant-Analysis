
/*
Objective: Rank menu categories by their contribution to overall sales, then find daily percentage contribution per category
- This will help classify top-performing categories for potential promotions or inventory focus
*/

-- Ranking categories based on their contribution to sales
-- calculating total sales, average item price, and percentage of total sales by category
WITH category_sales AS (
    SELECT
        m.category,
        SUM(m.price) AS total_sales,
        ROUND(AVG(m.price),2) AS avg_item_price
    FROM order_details o 
    JOIN menu_items m ON o.item_id = m.menu_item_id
    GROUP BY m.category
    )
SELECT
    category,
    total_sales,
    avg_item_price,
    RANK() OVER(ORDER BY total_sales DESC) AS sales_rank,
    ROUND(total_sales * 100.0 / SUM(total_sales) OVER(),2) AS pct_of_total_sales
FROM category_sales
ORDER BY sales_rank;


-- Calculate how many items per category are ordered per day
-- This insight can help with ordering inventory and preparing for daily orders

SELECT 
    m.category,
    COUNT(m.category) AS daily_item_count,
    TRIM(TO_CHAR(o.order_date, 'Day')) AS DOW
FROM menu_items m
JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY
    m.category,
    DOW
ORDER BY
    m.category,
    daily_item_count;



-- Calculate the amount of orders contain a specific category, the total order count per day,
-- and the percentage of orders that a category appears in per day.
-- This insight can help with seeing the overall impact per day of each category and help align
-- the menu. 
-- This insight also allows us to see if certain days contain a larger amount of a specific 
-- category, which could help with marketing, inventory management, and chef staffing

WITH order_category AS (
    SELECT
        o.order_id,
        TRIM(TO_CHAR(o.order_date, 'Day')) AS dow,
        m.category
    FROM order_details o
    JOIN menu_items m
        ON o.item_id = m.menu_item_id
), daily_total_orders AS (
    SELECT 
        TRIM(TO_CHAR(o.order_date, 'Day')) AS DOW,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM order_details o 
    GROUP BY
        DOW
)
SELECT
    oc.category,
    oc.dow,
    COUNT(DISTINCT oc.order_id) AS orders_with_category,
    dto.order_count AS total_order_count,
    ROUND(COUNT(DISTINCT oc.order_id) * 100.0 / dto.order_count, 2) AS percentage_of_total_orders
FROM order_category oc
JOIN daily_total_orders dto ON oc.dow = dto.dow
GROUP BY
    oc.category,
    oc.dow,
    dto.order_count
ORDER BY
    oc.category,
    orders_with_category DESC;


/*
Insights:
    - Italian and Asian categories generate the highest revenue, which appears to be driven by the high average item price.
    - There is a fairly even distribution of category items ordered per day, suggesting consistent demand for each category.
    - American food items are the lowest average price which contributes to the low category revenue even though it maintains a
      similar average volume to other categories. 
*/