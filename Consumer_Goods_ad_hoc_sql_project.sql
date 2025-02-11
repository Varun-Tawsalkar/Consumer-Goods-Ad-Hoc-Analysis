# Q1 
# Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT customer, market 
FROM dim_customer 
WHERE customer = "Atliq Exclusive" AND region = "APAC";

# Q2
#What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
#unique_products_2020
#unique_products_2021
#percentage_chg

WITH fiscal_year_2020 AS (
SELECT COUNT(DISTINCT product_code) as 2020_unique_products
FROM fact_sales_monthly
WHERE fiscal_year = 2020),
fiscal_year_2021 AS (
SELECT COUNT(DISTINCT product_code) as 2021_unique_products
FROM fact_sales_monthly
WHERE fiscal_year = 2021)
SELECT 2020_unique_products, 2021_unique_products,
CONCAT(ROUND(((2021_unique_products-2020_unique_products)/2020_unique_products)*100,2), "%") AS pct_chg
FROM fiscal_year_2020,fiscal_year_2021;

# Q3
#Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
#The final output contains 2 fields,
#segment
#product_count

SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


# Q4  
#Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
#segment
#product_count_2020
#product_count_2021
#difference


SELECT 
    p.segment, 
    COUNT(DISTINCT CASE WHEN s.fiscal_year = 2020 THEN p.product_code END) AS product_count_2020,
    COUNT(DISTINCT CASE WHEN s.fiscal_year = 2021 THEN p.product_code END) AS product_count_2021,
    COUNT(DISTINCT CASE WHEN s.fiscal_year = 2021 THEN p.product_code END) - 
    COUNT(DISTINCT CASE WHEN s.fiscal_year = 2020 THEN p.product_code END) AS difference
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE s.fiscal_year IN (2020, 2021)
GROUP BY p.segment
ORDER BY difference;


# Q5
#Get the products that have the highest and lowest manufacturing costs.
#The final output should contain these fields,
#product_code
#product
#manufacturing_cost

WITH COST_DATA AS (
    SELECT 
        p.product_code, 
        p.product, 
        m.manufacturing_cost,
        MAX(m.manufacturing_cost) OVER () AS max_cost,
        MIN(m.manufacturing_cost) OVER () AS min_cost
    FROM dim_product p
    JOIN fact_manufacturing_cost m
    ON p.product_code = m.product_code
)
SELECT product_code, product, manufacturing_cost 
FROM COST_DATA
WHERE manufacturing_cost = max_cost 
   OR manufacturing_cost = min_cost;


# Q6
#Generate a report which contains the top 5 customers who received an
#average high pre_invoice_discount_pct for the fiscal year 2021 and in the
#Indian market. The final output contains these fields,
#customer_code
#customer
#average_discount_percentage

SELECT 
    c.customer_code, 
    c.customer, 
    CONCAT(ROUND(AVG(p.pre_invoice_discount_pct) * 100, 2), "%") AS average_discount_pct
FROM fact_pre_invoice_deductions p
JOIN dim_customer c
ON p.customer_code = c.customer_code
WHERE c.market = 'India' AND p.fiscal_year = 2021
GROUP BY c.customer_code, c.customer
ORDER BY AVG(p.pre_invoice_discount_pct) * 100 DESC  
LIMIT 5;


# Q7
#Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
#This analysis helps to get an idea of low and high-performing months and take strategic decisions.
# The final report contains these columns:
#Month
#Year
#Gross sales Amount

SELECT 
	s.fiscal_year, 
	MONTHNAME(s.date) AS month, 
    CONCAT(ROUND(SUM((s.sold_quantity*g.gross_price))/1000000,2)," M") AS gross_sales
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price g
ON s.product_code = g.product_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY  MONTHNAME(s.date), s.fiscal_year
ORDER BY fiscal_year;

# Q8
# In which quarter of 2020, got the maximum total_sold_quantity? 
#The final output contains these fields sorted by the total_sold_quantity,
#Quarter
#total_sold_quantity

SELECT 
CASE
    WHEN MONTH(date) IN (9,10,11) THEN "Q1"
    WHEN MONTH(date) IN (12,1,2) THEN "Q2"
    WHEN MONTH(date) IN (3,4,5) THEN "Q3"
    WHEN MONTH(date) IN (6,7,8) THEN "Q4"
    END AS quaters,
    CONCAT(ROUND(SUM(sold_quantity)/1000000,2), " M") as total_sold_quantity
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
    GROUP BY quaters 
    ORDER BY total_sold_quantity DESC;
    
# Q9
# Which channel helped to bring more gross sales in the fiscal year 2021
#and the percentage of contribution? The final output contains these fields,
#channel
#gross_sales_mln
#percentage

WITH CTE AS (
    SELECT 
        c.channel, 
        ROUND(SUM(g.gross_price * s.sold_quantity) / 1000000, 2) AS gross_sales_mln,
        SUM(SUM(g.gross_price * s.sold_quantity) / 1000000) OVER () AS total_gross_sales_mln
    FROM fact_sales_monthly s
    JOIN dim_customer c ON s.customer_code = c.customer_code 
    JOIN fact_gross_price g ON s.product_code = g.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY c.channel
)
SELECT 
    channel, 
    gross_sales_mln, 
    CONCAT(ROUND((gross_sales_mln / total_gross_sales_mln) * 100, 2), "%") AS percentage
FROM CTE
ORDER BY gross_sales_mln DESC;


# 10 
# Get the Top 3 products in each division that have a high
# total_sold_quantity in the fiscal_year 2021? The final output contains these
#fields,
#division
#product_code
#product
#total_sold_quantity
#rank_order

WITH CTE AS(
SELECT p.division, s.product_code, p.product, 
CONCAT(ROUND(SUM(s.sold_quantity)/1000000,2), " M") AS total_sold_quantity,
DENSE_RANK() OVER (PARTITION BY p.division 
ORDER BY SUM(s.sold_quantity) DESC) AS  rank_order
FROM dim_product p 
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE fiscal_year = 2021
GROUP BY p.division, s.product_code, p.product)
SELECT * FROM CTE
WHERE rank_order <=3
ORDER BY division, rank_order;
