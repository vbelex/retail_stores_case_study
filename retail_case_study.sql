----Data type of columns in a table

SELECT table_name, column_name, data_type FROM retail.INFORMATION_SCHEMA.COLUMNS LIMIT 10; 

SELECT table_name, column_name, data_type FROM retail.INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'customers';

-- Time period for which the daata is given

SELECT MIN(order_purchase_timestamp) as start_date, MAX(order_delivered_customer_date) as end_date  FROM `retail.orders`  ;

--Cities and States of customers ordered during the given period

SELECT DISTINCT customer_city, customer_state from `retail.customers` LIMIT 10;



----What time do Brazilian customers tend to buy (Dawn, Morning, Afternoon or Night)?


select count(order_id) as totalorder, case when 
				CAST(order_purchase_timestamp as time) between '5:00:00.001' and '11:59:00.000' then 'Morning' 
				when CAST(order_purchase_timestamp as time) between '12:00:00.000' and '17:00:00.000' then 'Afternoon' 
				when CAST(order_purchase_timestamp as time) between '17:00:00.001' and '22:00:00.000' then 'Down' 
				else 'Night' 
				end  as timeoftheday from `retail.orders`
        group by timeoftheday;
        


---Get month on month orders by states

select distinct order_status from `retail.orders`;

WITH i AS(
SELECT 
FORMAT_DATE('%b-%y', order_purchase_timestamp) as yymm,
count (*) as ct,
c.customer_state
FROM `retail.orders` o JOIN `retail.customers` as c on o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY yymm, c.customer_state 
ORDER BY yymm
)

SELECT i.*, ROUND(((ct - LAG(ct) OVER (ORDER BY i.yymm))/ LAG(ct) OVER (ORDER BY i.yymm) - 1) * 100, 2) || '%' as growth 
FROM  i
ORDER BY yymm LIMIT 10;

---Distribution of customers across the states in Brazil
SELECT 
customer_state, ROUND((count(customer_unique_id) / (SELECT COUNT(customer_unique_id) from `retail.customers`)) * 100, 2) || ' %' as customer_count
FROM `retail.customers`
group by customer_state LIMIT 10


---Get % increase in cost of orders from 2017 to 2018 (include months between Jan to Aug only) - You can use “payment_value” column in payments table

WITH i AS (
SELECT  
FORMAT_DATE('%b-%y', o.order_purchase_timestamp) as month_year,
SUM(payment_value) as cost
FROM `retail.orders` as o JOIN `retail.payments` as p on o.order_id = p.order_id
where ((o.order_purchase_timestamp >=  '2017-01-01 00:00:00' AND o.order_purchase_timestamp <= '2017-08-30 00:00:00') OR (o.order_purchase_timestamp >=  '2018-01-01 00:00:00' AND o.order_purchase_timestamp <= '2018-08-30 23:59:59'))
group by month_year
order by month_year
) 
SELECT i.*, ROUND(((i.cost - LAG(i.cost) OVER (ORDER BY i.month_year))/ LAG(i.cost) OVER (ORDER BY i.month_year) - 1) * 100, 2) || '%' as percentage_in_increase_cost 
FROM  i 
ORDER BY i.month_year LIMIT 10;


----Mean & Sum of price and freight value by customer state

SELECT 
c.customer_state,
SUM(r.price) as sum_price,
SUM(r.price)/COUNT(r.price) as mean_price,
SUM(r.freight_value) as sum_freight_value,
SUM(r.freight_value)/COUNT(r.freight_value) as mean_freight_value
FROM `retail.order_items` as r
JOIN `retail.orders` as o ON o.order_id = r.order_id
JOIN `retail.customers`as c on c.customer_id = o.customer_id
group by c.customer_state LIMIT 10;


---Calculate days between purchasing, delivering and estimated delivery

SELECT 
DATE_DIFF(order_delivered_carrier_date, order_purchase_timestamp, day) as actual_delivery_days
FROM `retail.orders` 



SELECT * FROM `retail.orders` LIMIT 10 



--- Find time_to_delivery & diff_estimated_delivery 

SELECT 

DATE_DIFF(order_delivered_customer_date,order_purchase_timestamp, day) as time_to_delivery,
DATE_DIFF( order_estimated_delivery_date, order_delivered_customer_date, day) as diff_estimated_delivery

FROM `retail.orders` 


----Group data by state, take mean of freight_value, time_to_delivery, diff_estimated_delivery


SELECT 
c.customer_state,
ROUND(SUM(r.freight_value)/COUNT(r.freight_value),2) as mean_freight_value,
ROUND(SUM(DATE_DIFF(o.order_purchase_timestamp, o.order_delivered_customer_date, day))/COUNT(DATE_DIFF(o.order_purchase_timestamp, o.order_delivered_customer_date, day)),2) as mean_time_to_delivery,
ROUND(SUM(DATE_DIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date, day))/COUNT(DATE_DIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date, day)),2) as mean_diff_estimated_delivery
FROM `retail.customers` as c JOIN `retail.orders` as o 
ON c.customer_id = o.customer_id 
JOIN `retail.order_items` as r 
ON o.order_id = r.order_id
GROUP BY c.customer_state



-----Top 5 states with highest/lowest average freight value - sort in desc/asc limit 5

SELECT 
c.customer_state,
ROUND(AVG(r.freight_value), 2) as avg_freight_value
FROM `retail.customers` as c JOIN `retail.orders` as o 
ON c.customer_id = o.customer_id 
JOIN `retail.order_items` as r 
ON o.order_id = r.order_id
GROUP BY c.customer_state 
ORDER BY avg_freight_value
LIMIT 5;


------Top 5 states with highest/lowest average time to delivery


SELECT 
c.customer_state,
ROUND(AVG(DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, day)),2) as avg_time_to_delivery
FROM `retail.customers` as c JOIN `retail.orders` as o 
ON c.customer_id = o.customer_id 
GROUP BY c.customer_state
order by avg_time_to_delivery ASC
LIMIT 5;



----Month over Month count of orders for different payment types

WITH i AS (
SELECT  
FORMAT_DATE('%b-%y', o.order_purchase_timestamp) as month_year,
SUM(payment_value) as cost
FROM `retail.orders` as o JOIN `retail.payments` as p on o.order_id = p.order_id
where ((o.order_purchase_timestamp >=  '2017-01-01 00:00:00' AND o.order_purchase_timestamp <= '2017-08-30 00:00:00') OR (o.order_purchase_timestamp >=  '2018-01-01 00:00:00' AND o.order_purchase_timestamp <= '2018-08-30 23:59:59'))
group by month_year
order by month_year
) 
SELECT i.*, ROUND(((i.cost - LAG(i.cost) OVER (ORDER BY i.month_year))/ LAG(i.cost) OVER (ORDER BY i.month_year) - 1) * 100, 2) || '%' as percentage_in_increase_cost 
FROM  i 
ORDER BY i.month_year LIMIT 10;

WITH i AS (
SELECT  
FORMAT_DATE('%b-%y', o.order_purchase_timestamp) as month_year,
payment_type, 
count(*) as orders
from `retail.payments` as p JOIN `retail.orders` as o
ON p.order_id = o.order_id
group by payment_type, month_year
)
SELECT i.*, ROUND(((i.orders - LAG(i.orders) OVER (ORDER BY i.month_year))/ LAG(i.orders) OVER (ORDER BY i.month_year) - 1), 2) as Count_order_different_payment_type
FROM i
order by month_year

---Count of orders based on the no. of payment installments


SELECT 
payment_installments,
count(*) as orders,
FROM `retail.payments`
GROUP BY payment_installments;



