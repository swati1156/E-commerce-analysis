USE e_commerce;
--------------------------------------------------------------------------------------------------


-- analyses all the tables by describing their contents
Desc Customers;
Desc Products;
Desc Orders;
Desc OrderDetails;


--------------------------------------------------------------------------------------------------


-- Identifying the top 3 cities with the highest number of customers 
-- to determine key markets for targeted marketing and logistic optimization.

SELECT 
    location, COUNT(*) AS number_of_customers
FROM
    Customers
GROUP BY location
ORDER BY number_of_customers DESC
LIMIT 3;


--------------------------------------------------------------------------------------------------


-- Determining the distribution of customers by the number of orders placed. 
-- to get insight like segmenting customers into one-time buyers, occasional shoppers, and regular customers 
-- for tailored marketing strategies

SELECT 
    NumberOfOrders, COUNT(*) AS CustomerCount
FROM
    (SELECT 
        COUNT(*) AS NumberOfOrders
    FROM
        Orders
    GROUP BY customer_id) AS t
GROUP BY NumberOfOrders
ORDER BY NumberOfOrders;


--------------------------------------------------------------------------------------------------


-- Identifying products where the average purchase quantity per order is 2 but with a high total revenue, 
-- suggesting premium product trends.

SELECT 
    product_id AS Product_Id,
    AVG(quantity) AS AvgQuantity,
    SUM(quantity * price_per_unit) AS TotalRevenue
FROM
    OrderDetails
GROUP BY product_id
HAVING AVG(quantity) = 2
ORDER BY TotalRevenue DESC;


--------------------------------------------------------------------------------------------------


-- For each product category, calculated the unique number of customers purchasing from it. 
-- This will help understand which categories have wider appeal across the customer base.

SELECT 
    category, COUNT(DISTINCT customer_id) AS unique_customers
FROM
    Products pt
        JOIN
    OrderDetails od ON pt.product_id = od.product_id
        JOIN
    Orders os ON od.order_id = os.order_id
GROUP BY category
ORDER BY unique_customers DESC;



--------------------------------------------------------------------------------------------------


-- Analyzed the month-on-month percentage change in total sales to identify growth trends.

WITH helper_table AS (
    SELECT 
		DATE_FORMAT(order_date, '%Y-%m') AS Month,
		SUM(total_amount) AS TotalSales
    FROM Orders
    GROUP BY Month
)

SELECT 
	Month,
	TotalSales,
	ROUND(
	   (
		   (TotalSales - LAG(TotalSales) OVER (ORDER BY Month)) / 
		   LAG(TotalSales) OVER (ORDER BY Month)
	   ) * 100, 
	   2
	) AS PercentChange
FROM helper_table;


--------------------------------------------------------------------------------------------------


-- Examine how the average order value changes month-on-month. 
-- Insights can guide pricing and promotional strategies to enhance order value.

WITH helper_table AS
(
    SELECT 
		DATE_FORMAT(order_date,'%Y-%m') as Month,
		Avg(total_amount) AS AvgOrderValue
    FROM Orders
    GROUP BY Month
)

SELECT 
	Month, 
	AvgOrderValue,
	ROUND((AvgOrderValue - (lag(AvgOrderValue) over (order by Month))),2) AS ChangeInValue
FROM helper_table;


--------------------------------------------------------------------------------------------------


-- Based on sales data, identify products with the fastest turnover rates, 
-- suggesting high demand and the need for frequent restocking.

SELECT 
    product_id, COUNT(*) SalesFrequency
FROM
    OrderDetails
GROUP BY product_id
ORDER BY SalesFrequency DESC
LIMIT 5;


--------------------------------------------------------------------------------------------------


-- List products purchased by less than 40% of the customer base, 
-- indicating potential mismatches between inventory and customer interest.

set @total_count = (select count(distinct customer_id) from customers);
-- Total number of unique customers
WITH product_detail AS
(
    SELECT 
		products.product_id, 
        COUNT(distinct orders.customer_id) UniqueCustomerCount
    FROM products
    JOIN OrderDetails
        on products.product_id = OrderDetails.product_id
            join orders
                on OrderDetails.order_id = orders.order_id
    GROUP BY products.product_id
),
helper_table as (
  --  select product_detail.product_id,products.name as Name,UniqueCustomerCount
    select 
		pd.product_id,
        name,
        UniqueCustomerCount
    From products p
    JOIN product_detail pd on p.product_id = pd.product_id
)
SELECT * 
FROM helper_table
where UniqueCustomerCount/@total_count < 0.4;


--------------------------------------------------------------------------------------------------


-- Evaluate the month-on-month growth rate in the customer base to 
-- understand the effectiveness of marketing campaigns and market expansion efforts.

with helper_table as
(
    select 
		customer_id, 
        min(order_date) firstpurchasedate
    from orders
    group by customer_id
)
select 
	DATE_FORMAT(firstpurchasedate,'%Y-%m') firstpurchasemonth,
	count(*) TotalNewCustomers
from helper_table
group by firstpurchasemonth
order by firstpurchasemonth;


--------------------------------------------------------------------------------------------------


-- Identify the months with the highest sales volume, aiding in planning for stock levels, 
-- marketing efforts, and staffing in anticipation of peak demand periods.

SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS Month,
    SUM(total_amount) TotalSales
FROM
    Orders
GROUP BY Month
ORDER BY TotalSales DESC
LIMIT 3;

--------------------------------------------------------------------------------------------------



