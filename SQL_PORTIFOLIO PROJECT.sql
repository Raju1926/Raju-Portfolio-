


-- Changes Over Time Analysis --

SELECT 
YEAR(order_date) AS order_year,
MONTH (order_date) AS order_month,
SUM(sales_amount) AS Total_sales,
COUNT(DISTINCT customer_key) AS Total_customers,
SUM(quantity) AS Total_quantity 
FROM gold_fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),MONTH (order_date)
ORDER BY YEAR(order_date),MONTH (order_date) ;


-- Cumulative Analysis --

-- calculate the total sales per month 
-- and the running total of sales over time

SELECT
	order_date,
    Total_sales,
	SUM(Total_sales) OVER(ORDER BY order_date ) AS running_total_sales,
    ROUND(AVG(avg_price) OVER(ORDER BY order_date )) AS moving_average_price
FROM
(
	SELECT
	-- DATE_FORMAT(order_date, '%Y-%m') AS order_date,
    YEAR(order_date) AS order_date,
	SUM(sales_amount) AS Total_sales ,
    AVG(price) AS avg_price
	FROM gold_fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(order_date)
)t ;


-- PERFOMANCE ANALYSYS --
/* Analyse the Yearly perfomance of products by comparing thier sales 
to both the average sales perfomance of the product and the previous year's sales */

WITH yearly_product_sales AS
(
SELECT 
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales 
FROM gold_fact_sales f
LEFT JOIN gold_dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY YEAR(f.order_date),p.product_name
)
SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales ,
ROUND(current_sales - AVG(current_sales) OVER(PARTITION BY product_name)) AS diff_avg,
CASE 
     WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0  THEN 'Above avg'
     WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0  THEN 'Below avg'
     ELSE 'avg'
END avg_change,
-- Year-over-yera Analysis
LAG (current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales ,
current_sales - LAG (current_sales) OVER(PARTITION BY product_name ORDER BY order_year) diff_py,
CASE 
     WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name) > 0  THEN 'Increase'
     WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name) < 0  THEN 'Decrease'
     ELSE 'No change'
END py_change
FROM yearly_product_sales
ORDER BY product_name,order_year
;


-- PORT TO WHOLE proportional -- heading --
-- Which categories contribute the most to overall sales 
WITH category_sales AS 
(
SELECT 
category,
SUM(sales_amount) AS Total_sales 
FROM gold_fact_sales f 
LEFT JOIN gold_dim_products p 
ON f.product_key = p.product_key
GROUP BY category)

SELECT
category,
Total_sales,
SUM(Total_sales) OVER () overall_sales ,
CONCAT(ROUND((Total_sales / SUM(Total_sales) OVER () ) *100, 2), '%') percentage_of_Total
FROM category_sales
ORDER BY Total_sales DESC
;


-- DATA SEGMENTATION --
/* segment products into cost ranges and 
count how many products fall into each segment */

WITH product_segments AS 
(
SELECT
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
     WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
     ELSE 'Above 1000'
END cost_range
FROM gold_dim_products)

SELECT
cost_range,
COUNT(product_key) AS Total_products 
FROM product_segments
GROUP BY cost_range
ORDER BY Total_products DESC
;

/* Group customers into three segments based on their spending behaviour:
   - VIP: Customers with at least 12 months of history and spending more than $ 5,000.
   - Regular: Customers with at least 12 months of history but spending $5000 or less.
   - New: Customers with a lifespam less than 12 months.
And find th total number of customers by each group
*/
WITH customer_spending AS 
(
SELECT 
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order ,
TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold_fact_sales f
LEFT JOIN gold_dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT
customer_segment,
COUNT(customer_key) AS total_customers
FROM(
SELECT
customer_key,
total_spending,
lifespan,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
     WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
     ELSE 'New'
END customer_segment
FROM customer_spending )t 
GROUP BY customer_segment
ORDER BY total_customers 
;


/*
===============================================================
Customer Report
===============================================================

Purpose:
 - This report consolidates key customer metrics and behaviors

Highlights:
 1. Gathers essential fields such as names, ages, and transaction details.
 2. Segments customers into categories (VIP, Regular, New) and age groups.
 3. Aggregates customer-level metrics:
    - total orders
    - total sales
    - total quantity purchased
    - total products
    - lifespan (in months)
 4. Calculates valuable KPIs:
    - recency (months since last order)
    - average order value
    - average monthly spend
===============================================================
*/

CREATE VIEW gold_report_customers AS
WITH base_query AS 
/* -----------------------------------------------------------
1)Base query: Retrieves core columns from tables 
--------------------------------------------------------------*/
(
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ',c.last_name) AS customer_name,
TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
FROM gold_fact_sales f
LEFT JOIN gold_dim_customers c
ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL)

, customer_segmentation AS
/* -----------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
--------------------------------------------------------------*/
(
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)

SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
     WHEN age < 20 THEN 'under 20'
     WHEN age BETWEEN 20 AND 29 THEN '20-29'
     WHEN age BETWEEN 30 AND 99 THEN '30-39' 
     WHEN age BETWEEN 40 AND 49 THEN '40-49'
     ELSE '50 and above'
END age_group ,
CASE 
     WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
     WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
     ELSE 'New'
END customer_segment,
last_order_date,
TIMESTAMPDIFF(MONTH, last_order_date, CURDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
-- Compuate Average order value (AVO)
CASE WHEN total_sales = 0 THEN 0
     ELSE ROUND(total_sales/total_orders)
END AS avg_order_value,
-- Compuate Average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
     ELSE ROUND(total_sales/lifespan)
END AS avg_monthly_spend
FROM customer_segmentation
;

/*==============================================================================
Product Report
==============================================================================

Purpose:
 - This report consolidates key product metrics and behaviors.

Highlights:
 1. Gathers essential fields such as product name, category, subcategory, and cost.
 2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
 3. Aggregates product-level metrics:
    - total orders
    - total sales
    - total quantity sold
    - total customers (unique)
    - lifespan (in months)
 4. Calculates valuable KPIs:
    - recency (months since last sale)
    - average order revenue (AOR)
    - average monthly revenue

===============================================================================*/

CREATE VIEW gold_report_products AS
WITH base_query AS 
/* -----------------------------------------------------------
1)Base query: Retrieves core columns fact_sales and dim_products
--------------------------------------------------------------*/
(
SELECT
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
FROM gold_fact_sales f
LEFT JOIN gold_dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL   -- only consider valid sales dates
),

 product_aggregations AS
/* -----------------------------------------------------------
2) product Aggregations: Summarizes key metrics at the product level
--------------------------------------------------------------*/
(
SELECT
product_key,
product_name,
category,
subcategory,
cost,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
	COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	ROUND(AVG(sales_amount / NULLIF(quantity, 0))) AS avg_selling_price
FROM base_query
GROUP BY 
product_key,
product_name,
category,
subcategory,
cost
)

/* -----------------------------------------------------------
3) Final query: Combines all product results into one output
--------------------------------------------------------------*/
SELECT
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
TIMESTAMPDIFF(MONTH, last_sale_date, CURDATE()) AS recency_in_months,
CASE 
     WHEN total_sales >50000 THEN 'High-perfomer'
     WHEN total_sales >=10000 THEN 'Mid-range'
     ELSE 'Low-perfomer'
END product_segment ,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
-- AVG order revenue (AOR)

CASE WHEN total_orders = 0 THEN 0
     ELSE ROUND(total_sales/total_orders)
END AS avg_order_revenue,

--  Average monthly revenue
CASE WHEN lifespan = 0 THEN total_sales
     ELSE ROUND(total_sales/lifespan)
END AS avg_monthly_revenue
FROM product_aggregations
;



