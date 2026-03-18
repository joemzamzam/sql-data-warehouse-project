/*
========================================================
Project: SQL Data Warehouse Project
Author: Youssef Zamzam
Purpose: Exploratory Data Analysis (EDA) on Gold Layer
Description:
This script explores sales, customers, and products
to understand business performance, customer behavior,
and product trends.
========================================================
*/


/* =====================================================
1? - DATABASE STRUCTURE EXPLORATION
Understand the schema and available tables
===================================================== */

-- View all tables in the database
SELECT *
FROM INFORMATION_SCHEMA.TABLES;

-- View columns of the customer dimension
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customer';



/* =====================================================
2? - BASIC DIMENSION EXPLORATION
Understand the available values in dimensions
===================================================== */

-- List unique customer countries
SELECT DISTINCT country
FROM gold.dim_customer;

-- Explore product hierarchy
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY 1,2,3;



/* =====================================================
3? - DATA RANGE ANALYSIS
Understand time coverage of sales data
===================================================== */

SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales;



/* =====================================================
4? - CUSTOMER AGE ANALYSIS
Explore the age range of customers
===================================================== */

SELECT
    MIN(birthdate) AS oldest_birthdate,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), MAX(birthdate)) AS age_gap
FROM gold.dim_customer;



/* =====================================================
5? - KEY BUSINESS METRICS (KPIs)
High-level performance indicators
===================================================== */

SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(DISTINCT customer_key) FROM gold.dim_customer;



/* =====================================================
6? - TIME ANALYSIS (NEW)
Analyze sales trends over time
===================================================== */

-- Sales per year
SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales
GROUP BY YEAR(order_date)
ORDER BY order_year;

-- Sales per month
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS monthly_sales
FROM gold.fact_sales
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY order_year, order_month;

-- Orders per year
SELECT
    YEAR(order_date) AS order_year,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales
GROUP BY YEAR(order_date)
ORDER BY order_year;



/* =====================================================
7? - CUSTOMER ANALYSIS
Understand customer distribution
===================================================== */

-- Customers by country
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customer
GROUP BY country
ORDER BY total_customers DESC;

-- Customers by gender
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customer
GROUP BY gender
ORDER BY total_customers DESC;



/* =====================================================
8? - CUSTOMER SEGMENTATION (NEW)
Segment customers based on spending
===================================================== */

-- Customer lifetime value
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_spent
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC;


-- Segment customers into spending tiers
SELECT
    customer_segment,
    COUNT(*) AS number_of_customers
FROM
(
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spent,
        CASE
            WHEN SUM(f.sales_amount) >= 5000 THEN 'High Value'
            WHEN SUM(f.sales_amount) >= 1000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customer c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
) t
GROUP BY customer_segment
ORDER BY number_of_customers DESC;



/* =====================================================
9? - PRODUCT ANALYSIS
Understand product distribution and cost
===================================================== */

-- Number of products per category
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Average product cost by category
SELECT
    category,
    AVG(cost) AS average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC;



/* =====================================================
10 - SALES PERFORMANCE ANALYSIS
Revenue by category and geography
===================================================== */

-- Revenue per category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Items sold per country
SELECT
    c.country,
    SUM(f.quantity) AS total_items_sold
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_items_sold DESC;



/* =====================================================
11? - PRODUCT PERFORMANCE
Identify best and worst products
===================================================== */

-- Top 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Bottom 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;



/* =====================================================
12? - ADVANCED PRODUCT RANKING
Using window functions
===================================================== */

SELECT *
FROM
(
    SELECT
        p.product_name,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS product_rank,
        SUM(f.sales_amount) AS total_revenue
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.product_name
) ranked_products
WHERE product_rank <= 5;



/* =====================================================
13? - TOP CUSTOMERS
===================================================== */

-- Top 10 customers by revenue
SELECT TOP 10
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;

-- Customers with most orders
SELECT TOP 3
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders DESC;
