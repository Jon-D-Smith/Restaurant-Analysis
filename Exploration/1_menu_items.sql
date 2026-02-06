/*
Objective:
Explore the items table
    Your first objective is to better understand the items table by
    finding the number of rows in the table, the least and most expensive items,
    and the item prices within each category.
*/

-- View the menu items table and write a query to find the number of items on the menu

SELECT 
    COUNT(DISTINCT menu_item_id)
FROM menu_items

-- What are the least and most expensive items on the menu?
SELECT
    item_name,
    price
FROM menu_items
WHERE 
    price = (SELECT MIN(price) FROM menu_items)
    OR price = (SELECT MAX(price) FROM menu_items)



-- How many Italian dishes are on the menu? 

SELECT
    COUNT(*) AS italian_item_count
FROM menu_items
WHERE
    category = 'Italian'

-- What are the least and most expensive Italian dishes on the menu?

SELECT *
FROM menu_items
WHERE 
    category = 'Italian'
  AND (
        price = (SELECT MIN(price) FROM menu_items WHERE category = 'Italian')
        OR price = (SELECT MAX(price) FROM menu_items WHERE category = 'Italian')
      );



-- How many dishes are in each category?


SELECT 
    category, 
    COUNT(category)
FROM menu_items
GROUP BY category



-- What is the average dish price within each category?
SELECT 
    category,
    ROUND(AVG(price),2)
FROM menu_items
GROUP BY category