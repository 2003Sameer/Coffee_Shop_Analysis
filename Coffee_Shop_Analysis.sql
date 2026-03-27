

-- Coffee_Shop Data Analysis -- 


SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM sales;
SELECT * FROM customers;


-- Reports and Data Analysis --

-- Q1. COFFEE CONSUMER COUNT
-- HOW MANY IN EACH CITY ARE ESTIMATED TO CONSUME COFFEE, GIVEN THAT 25% OF THE POPULATION DOES ?

SELECT 
		city_name,
		ROUND((population * 0.25) / 1000000 , 2) AS Coffee_Consumer_in_Millions,
		city_rank
FROM city
ORDER BY 2 DESC
  

-- Q2. TOTAL REVENUE FROM COFFEE SALES
-- WHAT IS THE TOTAL REVENUE GENERATED FROM COFFEE SALES ACROSS ALL CITIES IN THE LAST QUARTER OF 2023 ?

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


-- Q3. SALES COUNT FOR EACH PRODUCT
-- HOW MANY UNITS OF EACH COFFEE PRODUCT HAVE BEEN SOLD ?

SELECT 
		p.product_name,
		COUNT(s.sale_id) AS Sales_Count
FROM products AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP by 1
ORDER BY 2 DESC;


-- Q4. AVERAGE SALES AMOUNT PER CITY
-- WHAT IS THE AVERAGE SALES AMOUNT PER CUSTOMER IN EACH CITY ?

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


-- Q5. CITY POPULATION AND COFFEE CONSUMERS (25% OF POPULATION CONSUME COFFEE)
-- PROVIDE A LIST OF CITIES ALONG WITH THEIR POPULATION AND ESTIMATED COFFEE CONSUMERS

SELECT
		ci.city_name,
		ci.population,
		COUNT(DISTINCT c.customer_id) AS Estimated_Coffee_Consumer
FROM city AS ci
JOIN customers AS c
ON ci.city_id = c.city_id
GROUP BY 1,2
ORDER BY 2 DESC;


-- Q6. TOP SELLING PRODUCT BY CITY
-- WHAT ARE THE TOP 3 SELLING PRODUCT IN EACH CITY BASED ON SALES VOLUME ?

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


-- Q7. CUSTOMERS SEGMENTATION BY CITY
-- HOW MANY UNIQUE CUSTOMERS ARE THERE IN EACH CITY WHO HAVE PURCHASED COFFEE PRODUCTS

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


-- Q8. AVERAGE SALE VS RENT
--  FIND EACH CITY AND THEIR AVERAGE SALE PER CUSTOMERS AND AVERAGE RENT PER CUSTOMERS

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


-- Q9. MONTHLY SALES GROWTH
-- CALCULATE THE PERCENTAGE GROWTH OR DECLINE IN SALES OVER DIFFERENT TIME PERIOD (MONTHLY) FOR EACH CITY

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
		

-- Q10. MARKET POTENTIAL ANALYSIS
-- IDENTIFY TOP 3 CITIES BASED ON HIGHEST SALES, RETURN CITY NAME, TOTAL SALES, TOTAL RENT, TOTAL CUSTOMERS, ESTIMATED COFFEE CONSUMERS

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
