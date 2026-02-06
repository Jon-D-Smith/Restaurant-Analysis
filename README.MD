# Restaurant Sales Analysis Portfolio

## Overview
This project analyzes three months of restaurant sales data to uncover revenue drivers, customer ordering patterns, and operational inefficiencies. Using SQL for data analysis and Tableau for visualization, I examined weekday demand trends, menu category performance, and individual item profitability.

The analysis focuses on translating raw sales data into actionable business insights that support staffing optimization, menu design, inventory planning, and pricing decisions. Each section follows a business-driven approach, connecting analytical findings directly to practical recommendations stakeholders could act on.

## Database Tables

### menu_items 
| menu_item_id | item_name | category | price   |
| ------------ | --------- | -------- | ------- |
| smallint     |  VARCHAR  | VARCHAR  | Numeric |
### order_details
| order_details_id | order_id | order_date | order_time | item_id |
| ---------------- | -------- | ---------- | ---------- | ------- |
| smallint         | smallint |   Date     |   Time     | smallint|

## SQL and Analyses

### 1. Weekday Sales Trends

#### Objective: Identify weekday sales trends to support business decisions such as staffing and marketing

#### Analysis Highlights
 - Calculated daily total orders, total revenue, and average order value
 - Compared individual orders to daily averages to identify outliers


<details>
  <summary><strong>Full SQL Analysis</strong></summary>
<pre><code class="language-sql">
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
</code></pre>
</details>

#### Key Insights
- Monday has overall low average sale price by order but has the highest total sales and order volume
- Tuesday has the highest average sales, but the third highest overall sales and low volume
- Friday consistently has high sales, high volume, and a high average order cost
- Sunday and Wednesday have the lowest average order value

#### Visualizations
![Sales Trend Dashboard](charts\sales_and_orders_dashboard.JPG)
- Sales Per Day - A bar chart showing the total sales per day of the week, supporting the higher total sales observed on Monday and Friday
- Total Orders Per Day - A bar chart showing the total order volume per weekday supporting the large volume on Monday and the relatively low volume for Tuesday.
- Sales to Order Ratio - A scatterplot showing sales and order volume per day of the week. The trend line shows the expected orders to sales ratio.
- Orders to Revenue Ranking - A circle chart showing each weekdays rank in terms of order volume to sales revenue. This is a more succinct visualization of the trend line from the previous chart. This chart reinforces that Tuesday brings in strong sales despite it's low volume.

#### Recommendations
- Higher staffing allocation on Mondays due to significantly higher traffic.
- Lower staffing allocation on Wednesdays due to significantly lower traffic.
- The efficiency rating for all weekdays is fairly consistent with Sunday and Wednesday being the lowest rate. Further analysis needed to find the root cause. Run an analysis on any happy hours, specials, or high volume items on those days to see if there needs to be pricing adjustments.

### 2. Category Insights

#### Objective: Rank menu categories by their contribution to overall sales and daily revenue contribution

#### Analysis Highlights
- Calculated total sales, average item price, and percentage of total sales by category
- Determined the total number of items sold per category per day
- Calculated the percentage of orders containing each category per day


<details>
    <summary><strong>Full SQL Analysis</strong></summary>
    <pre><code class="language-sql">
        
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

    </code></pre>
</details>

#### Key Insights
- The Asian category generates the highest revenue.
- There is a fairly even distribution of category items ordered per day, suggesting consistent demand for each category.
- American food items are the lowest average price which contributes to the low category revenue despite maintaining a similar average volume to other categories. 
- Mexican food has the highest level of volatility per weekday.

#### Visualizations
![Category Dashboard](charts\category_dashboard.JPG)
- Category Share By day - A stacked bar chart showing the distribution of volume per category, which supports the overall performance of Asian and Italian categories, as well as the volatility of the Mexican category.
- Catregory Trends - A line chart showing categorical trends per weekday, which reinforces the Asian category is consistently the highest performer and the American categry is consistently the lowest performer as far as volume of orders.
- Category Variability by Day - A box and whisker chart showing the volatility of each category, reinforcing the Mexican category as the most volatile category.
- Category dominance index - A bar chart showcasing each categories overall percentage of orders, which supports the claim of the Asian category as the strongest performer

#### Recommendations
- Increase capacity and prep for Asian dishes on Monday, Wednesday, and Thursday due to high demand
- Further market analysis on American food pricing to see if demand will stay the same with a slight increase in price
- Increase capacity and prep for Mexican dishes on Friday due to a high spike in demand compared to the rest of the week

### 3. Menu Item Insights

#### Objective: Identify the highest and lowest performing menu items in terms of volume and revenue

#### Analysis Highlights
- Ranked items by total revenue and calculated percent contribution to overall sales.
- Calculated item revenue and volume per day to detect trends

<details>
    <summary><strong>Full SQL Analysis</strong></summary>
    <pre><code class="language-sql">
        
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
    </code></pre>
</details>

#### Key Insights
- Korean beef bowls are the highest item in volume and overall net revenue. This occurs regardless of weekday.
- Pot stickers and chicken tacos are the lowest performing items on the menu in terms of volume and overall revenue.
- There seems to be a correlation to volume and revenue, but no obvious relationship to volume and price leading me to believe the menu items are appropriately priced.
- Edamame has one of the largest sales volume but one of the lowest revenues.

#### Visualizations
![Item sales and volume dashboard](charts\Item_sales_and_volume_dashboard.JPG)
![Item weekday performance](charts\Item_weekday_performance_dashboard.JPG)
- Item Level Sales - A vertical bar chart showcasing sales on a per item basis. This chart reinforces that the Korean Beef Bowl is the highest performer for revenue, and Chicken Tacos are the lowest performer.
- Volume Sold and Price - A scatterplot showing the relationship between volume and sales which showcases edamame as our highest volume item and relatively low price.
- Revenue per DOW - A horizontal stacked bar chart showcasing each items revenue per day of the week reinforcing the top items as high performers across each day of the week.
- Item performance Heatmap - A heatmap for total revenue per menu item per weekday. This reinforces the concentration of sales for our top performers like the Korean Beef Bowl, Spaghetti and Meatballs, and Tofu Pad Thai

#### Recommendations
- Korean beef bowl is a top revenue item across the week. Give large placement in menus and delivery apps to see if we can increase volume
- Burgers are high volume items with mid revenue. Add premium options, or bundle it with larger items to increase sales.
- Consider removing or repricing chicken tacos, potstickers, and hot dogs due to low overall performance, or potentially move them into a kids menu
- Run a price analysis on edamame to see if an increase in price will increase or decrease overall revenue. (I.E. Is the volume driven by price or popularity)

## Skills Demonstrated
- SQL (CTE's, Window functions, Aggregations, etc.)
- Dashboard design for decision making
- Business analysis & stakeholder-driven insights


## Analysis Disclaimer
- The dataset is limited to a 3 month time frame making long term insights more difficult to assess, and could mean some of our insights are not correct due to seasonality.
- Due to the database lacking any customer information we are not able to use demographics or customer retention. I would love to be able to run an analysis on rewards members vs. regular customers, or a cohort analysis on repeat customers.
- The database does have some null values that have been removed from the analysis but the overall data was clean. I was able to make some assumptions that item names and categories would be consistent and without spelling errors which allowed me to skip the majority of the cleaning phase.
