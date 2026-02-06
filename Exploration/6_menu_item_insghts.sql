
/*
Objective: Gain insights into the top performing, 
and lowest performing items in terms of revenue and volume
*/


-- calculate item performance and percentage of total sales
WITH item_sales AS (
    SELECT
        m.item_name,
        m.menu_item_id,
        m.price,
        SUM(m.price) AS total_item_sales
    FROM order_details o 
    JOIN menu_items m ON o.item_id = m.menu_item_id
    GROUP BY 
        m.item_name,
        m.menu_item_id,
        m.price
    ORDER BY
        total_item_sales DESC
), all_sales AS (
    SELECT
        *,
        SUM(total_item_sales) OVER() AS all_sales
    FROM item_sales
)
SELECT
    *,
    RANK() OVER(ORDER BY total_item_sales DESC) as total_sales_rank,
    ROUND(total_item_sales * 100.0 / all_sales, 2) AS pct_of_total_sales
    
FROM all_sales
ORDER BY
    total_item_sales DESC


-- calculate weekday item sales volume and overall item sales 


WITH menu_item_order_details AS (
    SELECT
        m.item_name,
        m.menu_item_id,
        m.price,
        TRIM(TO_CHAR(o.order_date, 'Day')) AS dow
    FROM order_details o
    INNER JOIN menu_items m ON o.item_id = m.menu_item_id
)
SELECT
    md.item_name,
    md.dow,
    md.price,
    COUNT(*) AS volume_sold,
    SUM(md.price) AS menu_item_total_revenue
FROM menu_item_order_details md
GROUP BY 
    md.item_name,
    md.dow,
    md.price
ORDER BY
    menu_item_total_revenue DESC;

/*
Insights:
    - Korean beef bowls are the highest item in volume and overall net revenue. This occurs regardless of weekday.
    - Pot stickers and chicken tacos are the lowest performing items on the menu in terms of volume and overall revenue.
    - There seems to be a correlation to volume and revenue, but no correlation to volume and price leading me to believe the menu items are appropriately priced.
*/