SELECT  
concat(ROUND(SUM(unit_price*transaction_qty))/1000, "k" )AS Total_sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5 -- for month of (CM-May) 
;
SELECT COUNT(transaction_id) as Total_Orders
FROM coffee_shop_sales 
WHERE MONTH (transaction_date)= 5 -- for month of (CM-May)
;
SELECT SUM(transaction_qty) as Total_Quantity_Sold
FROM coffee_shop_sales 
WHERE MONTH(transaction_date) = 5 -- for month of (CM-May)
;


SELECT
MONTH(transaction_date) AS MONTH , -- Number of months
ROUND(SUM(unit_price*transaction_qty)) AS Total_sales, -- total sales Column
(SUM(unit_price*transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)  -- month sales difference 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1) -- dividion by pm sales 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage  -- percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for months of April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    


SELECT 
    MONTH(transaction_date) AS month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    
    

SELECT 
    MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty)) AS total_quantity_sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5)   -- for April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    
    
SELECT 
      CONCAT(ROUND(SUM(unit_price*transaction_qty)/1000,1), 'K') AS Total_sales ,
      CONCAT(ROUND(SUM(transaction_qty)/1000,1), 'K') AS Total_qty_sold,
      CONCAT(ROUND(COUNT(transaction_id)/1000 ,1), 'K') AS Total_orders
FROM coffee_shop_sales
WHERE transaction_date = '2023-03-27'
;


SELECT 
     CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'Weekends'
     ELSE 'Weekdays'
     END AS day_type,
    CONCAT(ROUND(SUM(unit_price*transaction_qty)/1000,1), 'K') AS Total_sales
FROM coffee_shop_sales
WHERE MONTH (transaction_date) = 2 -- Feb month
GROUP BY 
         CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'Weekends'
         ELSE 'Weekdays'
		 END;
         
-- store location
SELECT
	store_location,
	 CONCAT(ROUND(SUM(unit_price*transaction_qty)/1000,2), 'K') AS Total_sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY store_location 
ORDER BY SUM(unit_price*transaction_qty) DESC
;

SELECT
     CONCAT(ROUND(AVG(Total_sales)/1000,1), 'K') AS avg_sales
FROM 
(SELECT SUM(unit_price*transaction_qty) AS Total_sales
FROM coffee_shop_sales
WHERE MONTH (transaction_date) = 4
GROUP BY transaction_date) as inner_query
;

SELECT 
    DAY(transaction_date) AS day_of_month,
    CONCAT(ROUND(SUM(unit_price*transaction_qty)/1000,1), 'K') AS Total_sales
FROM coffee_shop_sales
WHERE MONTH (transaction_date) = 4
GROUP BY day_of_month
ORDER BY day_of_month ;


SELECT
day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_shop_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;
    
    
SELECT 
	product_category,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) = 5 
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC ;


SELECT 
	product_type,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) = 5 
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 10
;

SELECT 
	product_type,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) = 5 AND product_category = 'coffee'
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 10 ;


SELECT 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    SUM(transaction_qty) AS Total_Quantity,
    COUNT(*) AS Total_Orders
FROM 
    coffee_shop_sales
WHERE 
    DAYOFWEEK(transaction_date) = 3 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
    AND HOUR(transaction_time) = 8 -- Filter for hour number 8
    AND MONTH(transaction_date) = 5; -- Filter for May (month number 5)
;



SELECT 
    HOUR(transaction_time) ,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales 
FROM coffee_shop_sales
WHERE MONTH (transaction_date) = 5
GROUP BY HOUR (transaction_time) 
ORDER BY HOUR (transaction_time) ;


SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END;
