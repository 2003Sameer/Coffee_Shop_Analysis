# Coffee_Shop_Analysis
This analysis gives a brief description about the coffee consumption in various cities. This analysis helps to understand in which cities we can expand our coffee outlet, by analysis customer preferences ,sales in that city and the estimated rent in that city so that it would be profitable for us to open there. 


### Objective
The goal of this project is to analyze the sales data of Coffee Shop, and to recommend the top three major cities in India for opening new coffee shop locations based on consumer demand and sales performance.

### Workflow
#### 1) Creat a database named "Coffee_Shop_Db"
#### 2) In a database query named "Schemas.sql" I created the tables "city", "products", "customers", "sales" and enter the data.
#### 3) In another query named "Coffee_Shop_Analyis" I answered business questions through sql queries


### Questions and Answer 
#### 1) Coffee Consumers Count
How many people in each city are estimated to consume coffee, given that 25% of the population does?

``` sql
SELECT 
		city_name,
		ROUND((population * 0.25) / 1000000 , 2) AS Coffee_Consumer_in_Millions,
		city_rank
FROM city
ORDER BY 2 DESC
```


#### 2) Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

``` sql
SELECT
		ci.city_name,
		SUM(s.total) AS Total_Revenue
FROM sales as s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
		EXTRACT (YEAR FROM s.sale_date) = 2023
		AND
		EXTRACT (QUARTER FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;
```

#### 3) Sales Count for Each Product
How many units of each coffee product have been sold?

``` sql
SELECT 
		p.product_name,
		COUNT(s.sale_id) AS Sales_Count
FROM products AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP by 1
ORDER BY 2 DESC;
```

#### 4) Average Sales Amount per City
What is the average sales amount per customer in each city?

``` sql
SELECT  
	ci.city_name,
	SUM(s.total) AS Total_Sales,
	COUNT(DISTINCT s.customer_id) AS Total_Customers,
	ROUND(
			SUM(s.total):: numeric/ 
				COUNT(DISTINCT s.customer_id):: numeric
			,2) AS Per_City_Avg
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id 
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;
```

#### 5) City Population and Coffee Consumers
Provide a list of cities along with their populations and estimated coffee consumers.

``` sql
SELECT
		ci.city_name,
		ci.population,
		COUNT(DISTINCT c.customer_id) AS Estimated_Coffee_Consumer
FROM city AS ci
JOIN customers AS c
ON ci.city_id = c.city_id
GROUP BY 1,2
ORDER BY 2 DESC;
```

#### 6) Top Selling Products by City
What are the top 3 selling products in each city based on sales volume?

``` sql
SELECT *
FROM 
(
SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id),
		DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS RANK
FROM city AS ci
JOIN customers AS c
ON ci.city_id = c.city_id
JOIN sales AS s
ON c.customer_id = s.customer_id
JOIN products AS p
ON s.product_id = p.product_id
GROUP BY 1,2
) AS T1
WHERE RANK <= 3;
```

#### 7) Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products?

``` sql
SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) AS Unique_Customers
FROM city AS ci
LEFT JOIN customers AS c
ON ci.city_id = c.city_id
JOIN sales AS s
ON s.customer_id = c.customer_id
WHERE 
		s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14) -- As other are not coffee products
GROUP BY 1
ORDER BY 2 DESC;
```

#### 8) Average Sale vs Rent
Find each city and their average sale per customer and avg rent per customer

``` sql
SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(total)::numeric/ COUNT(DISTINCT s.customer_id)::numeric,2) 
    AS average_sales_per_customer,
    ROUND(ci.estimated_rent::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as average_rent
FROM sales AS s
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN city AS ci 
ON ci.city_id = c.city_id
GROUP BY 1, ci.estimated_rent
ORDER BY 5 DESC
```

#### 9) Monthly Sales Growth
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

``` sql

WITH my_cte
AS
	(
		SELECT
				ci.city_name,
				EXTRACT(MONTH FROM s.sale_date) AS Month,
				EXTRACT(YEAR FROM s.sale_date) AS Year,
				SUM(s.total) AS total_sale
		FROM sales AS s
		JOIN customers AS c
		ON s.customer_id = c.customer_id
		JOIN city AS ci
		ON c.city_id = ci.city_id
		GROUP BY 1,2,3
		ORDER BY 1,3,2
	),
Next_Cte 
AS
(
	SELECT 
			city_name,
			Month,
			Year,
			total_sale AS Current_Month_Sale,
			LAG(total_sale,1) OVER (PARTITION BY city_name ORDER BY Year, Month) AS Last_Month_Sale
	FROM my_cte
)		
SELECT 
		city_name,
		Month,
		Year,
		Current_Month_Sale,
		Last_Month_Sale,
		ROUND(
		((Current_Month_Sale - Last_Month_Sale)::numeric / Last_Month_Sale ::numeric * 100)
		,2) AS Growth_Percentage
FROM Next_Cte
WHERE last_month_sale IS NOT NULL;
```

#### 10) Market Potential Analysis
Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

``` sql
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC
```

### Recommendations
After analyzing the data, the recommended top three cities for new store openings are:

#### City 1: Pune
1) Average rent per customer is very low.
2) Highest total revenue.
3) Average sales per customer is also high.

#### City 2: Delhi
1) Highest estimated coffee consumers at 7.7 million.
2) Highest total number of customers, which is 68.
3) Average rent per customer is 330 (still under 500).

#### City 3: Jaipur
1) Highest number of customers, which is 69.
2) Average rent per customer is very low at 156.
3) Average sales per customer is better at 11.6k.
