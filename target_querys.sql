#1.Data type of all columns in the “customers” table.

SELECT COLUMN_NAME, DATA_TYPE FROM
`target-427007.target_retails.INFORMATION_SCHEMA.COLUMNS`
WHERE TABLE_NAME = 'customers'

#2.Get the time range between which the orders were placed.

SELECT MIN(order_purchase_timestamp) AS Start_date,
MAX(order_purchase_timestamp) AS End_date
FROM `target_retails.orders`


#3Count the Cities & States of customers who ordered during the given period.
SELECT COUNT(DISTINCT geolocation_city) AS Total_Citys,
COUNT(DISTINCT geolocation_state) AS Total_State
FROM `target_retails.geolocation`


#1.Is there a growing trend in the no. of orders placed over the past years
SELECT COUNT(order_id)Numbers_Order,
EXTRACT(MONTH FROM order_purchase_timestamp) Month_trends,
EXTRACT(YEAR FROM order_purchase_timestamp) Year_trends
FROM `target-427007.target_retails.orders`
GROUP BY Year_trends, Month_trends
ORDER BY Year_trends, Month_trends


#2.Can we see some kind of monthly seasonality in terms of the no. of orders
being placed

SELECT COUNT(order_id) AS total_count,
EXTRACT(MONTH FROM order_purchase_timestamp) Month_trends
FROM `target-427007.target_retails.orders`
GROUP BY Month_trends
ORDER BY Month_trends


@3.During what time of the day, do the Brazilian customers mostly place their
orders? (Dawn, Morning, Afternoon or Night

WITH CTE AS(SELECT order_id,
CASE
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6
THEN "DAWN"
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12
THEN "MORNING"
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18
THEN "AFTERNOON"
ELSE "NIGHT"
END AS HOURS
FROM `target-427007.target_retails.orders`
GROUP BY order_purchase_timestamp, HOURS, order_id
)
SELECT COUNT(CTE.order_id) No_of_orders,
CTE.HOURS AS Time
FROM CTE
GROUP BY HOURS
ORDER BY No_of_orders DESC
LIMIT 1

#1 Get the month on month no. of orders placed in each state.

SELECT COUNT(order_id) AS Total_Orders ,customer_state AS States,
EXTRACT(MONTH FROM order_purchase_timestamp) AS Months,
EXTRACT(YEAR FROM order_purchase_timestamp) AS Years
FROM `target-427007.target_retails.orders` AS O
RIGHT JOIN `target-427007.target_retails.customers` AS C
ON O.customer_id = C.customer_id
GROUP BY Months,Years, customer_state
ORDER BY Months,years

#2How are the customers distributed across all the states

SELECT COUNT(distinct customer_id) Total_Unique_Customers,
customer_state
FROM `target-427007.target_retails.customers`
GROUP BY customer_state

#1. Get the % increase in the cost of orders from year 2017 to 2018 (include monthsbetween Jan to Aug only

WITH CTE AS (SELECT COUNT(P.order_id) ,
SUM(payment_value) pay_value,
EXTRACT(MONTH FROM order_purchase_timestamp ) AS MONTHS ,
EXTRACT(YEAR FROM order_purchase_timestamp ) AS YEARS
FROM `target-427007.target_retails.payments` AS P
JOIN `target-427007.target_retails.orders` AS O
ON P.order_id = O.order_id
WHERE EXTRACT(YEAR FROM order_purchase_timestamp ) BETWEEN 2017 AND 2018 AND
EXTRACT(MONTH FROM order_purchase_timestamp ) BETWEEN 1 AND 8
GROUP BY MONTHS, YEARS
)
SELECT T1.MONTHS,
((SUM(T2.pay_value) - SUM(T1.Pay_value)) /SUM(T1.pay_value))* 100 AS
Precentage_increment
FROM CTE AS T1
JOIN CTE AS T2
ON T1.MONTHS = T2.MONTHS
AND T1.YEARS =2017 AND T2.YEARS = 2018
GROUP BY T1.MONTHS
ORDER BY T1.MONTHS

#2Calculate the Total & Average value of order price for each state

SELECT COUNT(IO.order_id) AS ORDER_ID,
customer_state AS STATE,
ROUND(SUM(price)) AS TOTAL_PRICE,
ROUND(SUM(price)/COUNT(DISTINCT io.order_id)) AS AVG_PRICE
FROM `target-427007.target_retails.customers` AS C
JOIN `target-427007.target_retails.case.orders` AS O
ON C.customer_id= O.customer_id
JOIN `target-427007.target_retails.order_items` AS IO
ON O.order_id = IO.order_id
GROUP BY customer_state

#3.Calculate the Total & Average value of order freight for each state.

SELECT COUNT(IO.order_id) AS ORDER_ID,
customer_state AS STATE,
ROUND(SUM(freight_value)) AS TOTAL_Freight_Value,
ROUND(SUM(freight_value) / COUNT(DISTINCT io.order_id)) AS AVG_Freight_Value
FROM `target-427007.target_retails.customers` AS C
JOIN `target-427007.target_retails.orders` AS O
ON C.customer_id= O.customer_id
JOIN `target-427007.target_retails.order_items` AS IO
ON O.order_id = IO.order_id
GROUP BY customer_state


#1: Find the no. of days taken to deliver each order from the order’s purchase dateas delivery time.

  SELECT order_id, DATE_DIFF( order_delivered_customer_date,order_purchase_timestamp, DAY )
AS No_days_to_deliver ,
DATE_DIFF ( order_estimated_delivery_date,order_delivered_customer_date, day) AS
Diff_Estimated_days
FROM `target-427007.target_retails.orders`


  #2. . Find out the top 5 states with the highest & lowest average freight value.
  
SELECT
customer_state AS STATE ,
SUM(freight_value) as TOTAL_freight_value,
SUM(OI.freight_value) / COUNT(DISTINCT O.order_id) AS Average_Freight_values
FROM `target-427007.target_retails.customers` AS C
JOIN `target-427007.target_retails.orders` AS O
ON O.customer_id = C.customer_id
JOIN `target-427007.target_retails.order_items` AS OI
ON O.order_id = OI.order_id
GROUP BY customer_state
ORDER BY Average_Freight_values
LIMIT 5;


#3 Find out the top 5 states with the highest & lowest average delivery time.

  SELECT DISTINCT customer_state,
ROUND(SUM(DATE_DIFF( order_delivered_customer_date ,order_purchase_timestamp, DAY)) /
COUNT(DISTINCT order_id),2) Average_days
FROM `target-427007.target_retails.orders`
join `target-427007.target_retails.customers`
USING(customer_id)
GROUP BY customer_state
order by Average_days DESC
LIMIT 5

  #4. Find out the top 5 states where the order delivery is really fast as compared to
the estimated date of delivery

  WITH CTE AS (SELECT customer_state,
SUM(EXTRACT(DAY FROM order_delivered_customer_date))/count( distinct order_id) AVG_actual,
SUM(EXTRACT(DAY FROM order_estimated_delivery_date))/count( distinct order_id)
AVG_Estimated
FROM `target-427007.target_retails.orders` AS O
JOIN `target-427007.target_retails.customers` AS C
ON O.customer_id = C.customer_id
WHERE order_status = "delivered"
GROUP BY customer_state)
SELECT ( customer_state),
round((AVG_actual - AVG_Estimated),2) Fast_deliverd,
FROM CTE
GROUP BY customer_state,Fast_deliverd
ORDER BY Fast_deliverd DESC
LIMIT 5


#1. Find the month on month no. of orders placed using different payment types.

  SELECT
payment_type,
EXTRACT(MONTH FROM order_purchase_timestamp) AS Month ,
EXTRACT(YEAR FROM order_purchase_timestamp) AS Year,
COUNT(P.order_id) Numbers_orders
FROM `target-427007.target_retails.payments` AS P
JOIN `target-427007.target_retails.orders` AS O
ON P.order_id = O.order_id
GROUP BY payment_type,Month,Year
ORDER BY Month,Year

  #2. Find the no. of orders placed on the basis of the payment installments that have
been paid.

  SELECT COUNT(DISTINCT order_id) Total_count_of_orders,
payment_installments
FROM `target-427007.target_retails.payments`
WHERE payment_installments > 1
GROUP BY payment_installments
ORDER BY payment_installments

  


  





