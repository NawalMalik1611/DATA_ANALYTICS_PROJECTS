SELECT * FROM [dbo].[gold.fact_sales];
SELECT * FROM [dbo].[gold.dim_customers];

USE [DataWarehouseAnalytics];
GO
SELECT * FROM [dbo].[gold.dim_products];

--total sales
SELECT YEAR(order_date) AS YEARS , SUM(sales_amount) AS TOTAL_SALES
FROM [dbo].[gold.fact_sales]
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--addition of new customers and the total sales in years
SELECT YEAR(order_date) AS YEARS , SUM(sales_amount) AS TOTAL_SALES, COUNT(DISTINCT customer_key) AS new_customers, SUM(quantity) AS total_quatity
FROM [dbo].[gold.fact_sales]
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--addition of new customers and the total sales in months
SELECT MONTH(order_date) AS YEARS , SUM(sales_amount) AS TOTAL_SALES, COUNT(DISTINCT customer_key), SUM(quantity)
FROM [dbo].[gold.fact_sales]
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

--using best of both(getting the total sales and new customers of each month of each year)
SELECT DATETRUNC(month,order_date) AS YEARS , SUM(sales_amount) AS TOTAL_SALES, COUNT(DISTINCT customer_key) AS new_customers, SUM(quantity) AS total_quatity
FROM [dbo].[gold.fact_sales]
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)


--which category's products are sold most IN EVERY YEAR
SELECT category, YEAR(start_date) as YEARS, 
FROM [dbo].[gold.dim_products]
GROUP BY YEAR(start_date)
ORDER BY YEAR(start_date)



--CUMILITIVE SALE AND AVG PRICE OVER THE YEARS
SELECT order_date,total_sales, SUM(total_sales) OVER (ORDER BY order_date) AS running_sales, AVG(average_price) OVER (ORDER BY order_date) AS running_average
FROM(
SELECT DATETRUNC(YEAR,order_date) AS order_date, SUM(sales_amount) AS total_sales, AVG(price) AS average_price
FROM [dbo].[gold.fact_sales]
WHERE order_date is NOT NULL
GROUP by DATETRUNC(YEAR,order_date)
)AS monthly_sales



--ANALYZE THE YEARLY PERFORMANCE OF EACH PRODUCT BY COMPARING THEIR SALES TO THE AVERAGE SALES OF THE PORUCT AND PREVIOUS YEARS SALES
WITH yearly_product_sales AS(
SELECT SUM(fs.sales_amount) as CURRENT_sales, YEAR(fs.order_date) as order_date, p.product_name as product_name
FROM [dbo].[gold.fact_sales] fs
LEFT JOIN [dbo].[gold.dim_products] p
ON fs.product_key=p.product_key
WHERE order_date is NOT NULL
GROUP BY YEAR(fs.order_date),p.product_name
)
SELECT order_date,product_name, CURRENT_sales,AVG(CURRENT_sales) OVER (PARTITION BY product_name ) AS AVERAGE_SALES, CURRENT_sales-AVG(CURRENT_sales) OVER (PARTITION BY product_name ) as diff_avg,
CASE WHEN CURRENT_sales-AVG(CURRENT_sales) OVER (PARTITION BY product_name ) > 0 THEN 'ABOVE AVERAGE'
     WHEN CURRENT_sales-AVG(CURRENT_sales) OVER (PARTITION BY product_name ) < 0 THEN 'BELOW AVERAGE'
	 ELSE 'AVERAGE'
	 END AS 'AVG_CHANGE',
LAG(CURRENT_sales) OVER (PARTITION BY product_name ORDER BY order_date) AS PREVIOUS,
CURRENT_sales - LAG(CURRENT_sales) OVER (PARTITION BY product_name ORDER BY order_date) AS PREVIOUS_DIFF,
CASE WHEN CURRENT_sales- LAG(CURRENT_sales) OVER (PARTITION BY product_name ORDER BY order_date) > 0 THEN 'INCREASING'
     WHEN CURRENT_sales- LAG(CURRENT_sales) OVER (PARTITION BY product_name ORDER BY order_date)< 0 THEN 'DECREASING'
	 ELSE 'NO DIFFERENCE'
	 END AS 'PREVIOUS YEAR COMPARISON'
FROM yearly_product_sales
ORDER BY product_name,order_date
--GROUP BY order_date,product_name
--


--part-to-whole
--WHICH CATEGORY CONTRIBUTED MOST IN THE TOTAL SLAES
WITH CATEGORY_SALES AS(
SELECT category, SUM(sales_amount) AS TOTAL_SALES
FROM [gold.fact_sales] F LEFT JOIN [gold.dim_products] P
ON F.product_key=P.product_key
GROUP BY category
)
SELECT category, TOTAL_SALES, SUM(TOTAL_SALES) OVER () AS OVERALL_SALES,CONCAT (ROUND ((CAST (TOTAL_SALES AS FLOAT)/SUM(TOTAL_SALES) OVER () )*100,2),'%') AS PERCENTAGE_SALES
FROM CATEGORY_SALES
ORDER BY TOTAL_SALES DESC



-- DATA DIMENSION
WITH CUSTOMER_SEGMENTATION_LIFESPAN AS (
    SELECT 
        C.customer_key, 
        SUM(F.sales_amount) AS total_spending, 
        MAX(F.order_date) AS last_order, 
        MIN(F.order_date) AS first_order,
        DATEDIFF(month, MIN(F.order_date), MAX(F.order_date)) AS life_span
    FROM [gold.fact_sales] F 
    LEFT JOIN [gold.dim_customers] C
        ON F.customer_key = C.customer_key
    GROUP BY C.customer_key
)

SELECT 
    [CUSTOMER SEGMENTATION], 
    COUNT(customer_key) AS total_customers
FROM (
    SELECT 
        customer_key,
        total_spending,
        life_span,
        CASE 
            WHEN life_span >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN life_span > 12 AND total_spending <= 5000 THEN 'REGULAR'
            ELSE 'NEW'
        END AS [CUSTOMER SEGMENTATION]
    FROM CUSTOMER_SEGMENTATION_LIFESPAN
) AS segmented_customers
GROUP BY [CUSTOMER SEGMENTATION]
ORDER BY total_customers DESC;



/*
===============================================================================
Customer Report
===============================================================================
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
===============================================================================
*/
CREATE VIEW GOLD_CUSTOMER_REPORT AS
WITH base_query AS (
    SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS CUSTOMER_NAME,
        DATEDIFF(year, c.birthdate, GETDATE()) AS CUSTOMER_AGE
    FROM [gold.fact_sales] f
    LEFT JOIN [gold.dim_customers] c ON c.customer_key = f.customer_key
),

customer_summary AS (
    SELECT 
        customer_key,
        customer_number,
        CUSTOMER_NAME,
        CUSTOMER_AGE,
        SUM(sales_amount) AS TOTAL_SALES,
        COUNT(DISTINCT order_number) AS TOTAL_ORDERS,
        SUM(quantity) AS TOTAL_QUANTITY,
        COUNT(DISTINCT product_key) AS TOTAL_PRODUCTS,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS life_span,
        MAX(order_date) AS LAST_ORDER_DATE
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        CUSTOMER_NAME,
        CUSTOMER_AGE
)

SELECT
    customer_key,
    customer_number,
    CUSTOMER_NAME,
    CUSTOMER_AGE,
    TOTAL_SALES,
    TOTAL_ORDERS,
    TOTAL_QUANTITY,
    TOTAL_PRODUCTS,
    life_span,
    LAST_ORDER_DATE,
    DATEDIFF(month, LAST_ORDER_DATE, GETDATE()) AS RECENCY,

    -- AVERAGE ORDER VALUE
    CASE 
        WHEN TOTAL_ORDERS = 0 THEN 0
        ELSE TOTAL_SALES / TOTAL_ORDERS
    END AS [AVERAGE_ORDER_VALUE],

    -- MONTHLY AVERAGE
    CASE 
        WHEN life_span = 0 THEN TOTAL_SALES
        ELSE TOTAL_SALES / life_span 
    END AS [MONTHLY_AVERAGE_VALUE],

    -- Age Group Categorization
    CASE 
        WHEN CUSTOMER_AGE < 20 THEN 'UNDER 20'
        WHEN CUSTOMER_AGE BETWEEN 20 AND 29 THEN '20-29'
        WHEN CUSTOMER_AGE BETWEEN 30 AND 39 THEN '30-39'
        WHEN CUSTOMER_AGE BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS [AGE_GROUP],

    -- Customer Segmentation
    CASE 
        WHEN life_span >= 12 AND TOTAL_SALES > 5000 THEN 'VIP'
        WHEN life_span > 12 AND TOTAL_SALES <= 5000 THEN 'REGULAR'
        ELSE 'NEW'
    END AS [CUSTOMER_SEGMENTATION]

FROM customer_summary;

/*
===============================================================================
Product Report
===============================================================================
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
===============================================================================
*/
CREATE VIEW gold_report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
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
    FROM [gold.fact_sales] f
    LEFT JOIN [gold.dim_products] p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_revenue

FROM product_aggregations 
