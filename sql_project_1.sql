USE coffee_shop;
SELECT  COUNT(*) FROM transactions;
SELECT  COUNT(*) FROM dim_stores;
SELECT  COUNT(*) FROM dim_products;


SELECT * FROM transactions;
-- Changing the data types text - date & time

-- modify the transaction_time data type text to time
ALTER TABLE transactions
MODIFY COLUMN transaction_time time;

-- modify the transaction_time data type text to date 
ALTER TABLE transactions
MODIFY COLUMN transaction_date DATE;

-- Update the date in YYYY-MM-DD format
UPDATE transactions
SET transaction_date = STR_TO_DATE('01-Jan-2020', '%d-%m-%Y');

-- Display the date in YYYY-MM-DD format
SELECT DATE_FORMAT(transaction_date, '%Y-%m-%d') AS formatted_date
FROM transactions;

DESC transactions;

-- 
-- Total Sales - for the selected period - Yes — Month-over-Month % change

-- Month-over-Month Sales Growth %
WITH monthly_sales AS (
    SELECT YEAR(transaction_date) AS year,MONTH(transaction_date) AS mon,
	SUM(unit_price * transaction_qty) AS curreny_mon_sales
    FROM transactions
--     WHERE MONTH(transaction_date) = 3
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
)
SELECT year,mon,curreny_mon_sales,
LAG(curreny_mon_sales) OVER(ORDER BY year, mon) AS previous_year,
CONCAT(ROUND((curreny_mon_sales -
            LAG(curreny_mon_sales) OVER(ORDER BY year, mon))
            /(LAG(curreny_mon_sales) OVER(ORDER BY year, mon)) * 100,2), '%') AS M_M
FROM monthly_sales;


-- 4
-- Total Orders - transactions for the selected period -  Yes — Month-over-Month % change
-- Month-over-Month QTY Growth %
WITH monthly_orders AS (
    SELECT YEAR(transaction_date) AS year,MONTH(transaction_date) AS mon,
	COUNT(transaction_qty) AS curreny_mon_orders
    FROM transactions
--     WHERE MONTH(transaction_date) = 3
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
)
SELECT year,mon,curreny_mon_orders,
LAG(curreny_mon_orders) OVER(ORDER BY year, mon) AS previous_year_orders,
CONCAT(ROUND((curreny_mon_orders -
            LAG(curreny_mon_orders) OVER(ORDER BY year, mon))
            /(LAG(curreny_mon_orders) OVER(ORDER BY year, mon)) * 100,2), '%') AS M_M
FROM monthly_orders;


-- 5
-- Total Quantity Sold - quantity sold for the selected period - Yes — Month-over-Month % change
-- Month-over-Month QTY Growth %
WITH monthly_QTY AS (
    SELECT YEAR(transaction_date) AS year,MONTH(transaction_date) AS mon,
	COUNT(unit_price * transaction_qty) AS curreny_mon_qty
    FROM transactions
--     WHERE MONTH(transaction_date) = 3
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
)
SELECT year,mon,curreny_mon_qty,
LAG(curreny_mon_qty) OVER(ORDER BY year, mon) AS previous_qty,
CONCAT(ROUND((curreny_mon_qty -
            LAG(curreny_mon_qty) OVER(ORDER BY year, mon))
            /(LAG(curreny_mon_qty) OVER(ORDER BY year, mon)) * 100,2), '%') AS M_M
FROM monthly_qty;

-- 6
-- Daily snapshot: Total Sales, Total Quantity Sold, and Total Orders 
-- for any single selected date.

SELECT  month(transaction_date) AS mon,
YEAR(transaction_date) AS year,
SUM( unit_price * transaction_qty) AS total_sales,
SUM(transaction_qty) AS total_qty ,
COUNT(transaction_id) AS total_orders FROM transactions
 WHERE Transaction_date = '2024-06-30'
GROUP BY month(transaction_date),YEAR(transaction_date);

-- 7
-- Rounded/short-form values for cards, e.g. sales shown as "45.6K" instead of the full number.
SELECT 
CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 2), ' K') AS total_sales
FROM transactions;


--  8
-- Average daily sales trend for the selected month

WITH daily_sales AS (
    SELECT YEAR(transaction_date) AS year,MONTH(transaction_date) AS mon,DAY(transaction_date) AS day,
	SUM(unit_price * transaction_qty) AS total_sales
    FROM transactions
    WHERE MONTH(transaction_date) = 3
    GROUP BY YEAR(transaction_date),MONTH(transaction_date),DAY(transaction_date)
)
SELECT year,mon,day,total_sales,
    AVG(total_sales) OVER(PARTITION BY year, mon) AS avg_daily_sales
FROM daily_sales;

-- Daily sales compared to the monthly average, 
-- labelled as "Above Average" or "Below Average" for each day.2

WITH cte AS( 
SELECT month(transaction_date) as mon_sales,
dayname(transaction_date) as day_sales,
SUM(unit_price * transaction_qty) AS total_sales
FROM transactions
GROUP BY month(transaction_date),dayname(transaction_date) )

SELECT mon_sales,day_sales,AVG(total_sales) OVER() AS  monthly_average,

(CASE 
WHEN day_sales > AVG(total_sales) OVER()
THEN "Above Average"
	ELSE "Below Average"
    END
) AS "Above Average / Below Average"   from CTE;

-- 10
-- Total sales split into two groups: Weekdays and Weekends

-- Sales by Weekday / Weekend
-- Total sales , split into two groups: Weekdays and Weekends
WITH CTE AS (SELECT SUM(unit_price * transaction_qty) AS total_sales, 
DAYOFWEEK(transaction_date) AS day_no FROM transactions
GROUP BY DAYOFWEEK(transaction_date))
SELECT DAY_NO,TOTAL_SALES,
(case 
	WHEN Day_no IN (6, 7) 
    THEN "Weekend"
    ELSE "Weekday"
    END) AS "WEEKEND/WEEKDAY"
FROM CTE;



-- 11
-- Total sales for each day, Monday through Sunday

-- Sales by Day of Week

SELECT SUM(unit_price * transaction_qty) AS total_sales,
DAYOFWEEK(transaction_date) AS day_no FROM transactions
GROUP BY DAYOFWEEK(transaction_date);



-- 12
-- Sales by Hour of Day
-- Total sales for each hour, to find peak selling hours

SELECT hour(transaction_time) as hours,DAY(transaction_date) AS day ,SUM(unit_price * transaction_qty) AS total_sales,
dense_rank() OVER(ORDER BY SUM(unit_price * transaction_qty)  DESC)
 FROM transactions
 GROUP BY hour(transaction_time),DAY(transaction_date) 
 LIMIT 1;
 
 -- 13
 -- Total sales for each store, ranked highest to lowest
 
 SELECT SUM(unit_price * transaction_qty) AS total_sales ,store_location FROM transactions AS t
JOIN dim_stores AS s ON t.store_id = s.store_id
GROUP BY store_location
ORDER BY total_sales DESC; 

-- 14
-- Sales by Product Category
-- Total sales for each product category (e.g., Coffee, Tea, Bakery)

SELECT SUM(unit_price * transaction_qty) AS total_sales ,product_category FROM transactions AS t
JOIN dim_products AS p ON t.PRODUCT_id = p.product_id
GROUP BY product_category ;


-- 15
-- Top 10 Products
-- Top 10 product types by total sales value
WITH cte  as (
SELECT SUM(unit_price * transaction_qty) AS total_sales ,product_TYPE
FROM transactions AS t
JOIN dim_products AS p ON t.PRODUCT_id = p.product_id
GROUP BY product_TYPE)

SELECT
total_sales,product_TYPE,
dense_rank()OVER( ORDER BY total_sales DESC) FROM CTE
LIMIT 10;



-- 16
-- Sales by Day & Hour Combination - Total sales, quantity, and orders for a specific weekday and hour together (e.g., Tuesdays at 8 AM)


SELECT
SUM(transaction_qty) AS QTY,COUNT(transaction_id) AS Total_orders,SUM(unit_price * transaction_qty) AS total_sales,
DAYOFWEEK(transaction_date) AS day,HOUR(transaction_time) AS hours
FROM transactions
WHERE DAYOFWEEK(transaction_date) = 3 AND HOUR(transaction_time) = 8
GROUP BY DAYOFWEEK(transaction_date),HOUR(transaction_time);



-- 17
-- ---> WAQ to find category and Product type wise total_sales , Total_unit_sold  

SELECT PRODUCT_CATEGORY, product_type,SUM(unit_price * transaction_qty) AS total_sales,
SUM(Transaction_qty)AS total_unit_sales FROM transactions as t
JOIN dim_products AS P ON t.product_id = p.product_id
GROUP BY PRODUCT_CATEGORY, product_type;


-- 18

-- -> Waq to find store loaction category and Product type wise total_sales

SELECT Store_location,product_type,SUM(unit_price * transaction_qty) AS total_sales
FROM transactions as t
JOIN dim_products AS P ON t.product_id = p.product_id
JOIN dim_stores AS s ON s.store_id = t.store_id
GROUP BY Store_location,product_type;








