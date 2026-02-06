/*
Objective 3
Analyze customer behavior
Your final objective is to combine the items and orders tables, 
find the least and most ordered categories, 
and dive into the details of the highest spend orders.
*/

-- Combine the menu_items and order_details tables into a single table
SELECT *
FROM order_details
LEFT JOIN menu_items ON order_details.item_id = menu_items.menu_item_id;

-- What were the least and most ordered items? 
SELECT 
    item_name,
    COUNT(order_details_id)        
FROM order_details
LEFT JOIN menu_items ON order_details.item_id = menu_items.menu_item_id
GROUP BY item_name
ORDER BY count DESC
;
-- What categories were they in?
SELECT 
    item_name,
    category,
    COUNT(order_details_id)        
FROM order_details
LEFT JOIN menu_items ON order_details.item_id = menu_items.menu_item_id
GROUP BY item_name, category
ORDER BY count DESC
;
-- What were the top 5 orders that spent the most money?
SELECT
    order_details.order_id,
    SUM(menu_items.price) AS order_price
FROM order_details
LEFT JOIN menu_items ON order_details.item_id = menu_items.menu_item_id
GROUP BY
    order_details.order_id
HAVING  
    SUM(menu_items.price) IS NOT NULL
ORDER BY
    SUM(menu_items.price) DESC
LIMIT 5
-- View the details of the highest spend order. Which specific items were purchased?

SELECT
    category,
    COUNT(item_id) AS num_items
FROM order_details
LEFT JOIN menu_items ON order_details.item_id = menu_items.menu_item_id
WHERE
    order_id = 440
GROUP BY
    category;

-- BONUS: View the details of the top 5 highest spend orders

SELECT
    order_id,
    category,
    COUNT(item_id) AS num_items
FROM order_details
LEFT JOIN menu_items ON order_details.item_id = menu_items.menu_item_id
WHERE
    order_id IN (440, 2075, 1957, 330, 2675)
GROUP BY
    order_id, category;
