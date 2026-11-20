/*
===============================================================================
Business Insights: queries on the Gold layer
===============================================================================
Script Purpose:
    Answers basic business questions using the star schema
    (gold.fact_sales, gold.dim_customers, gold.dim_products).
    The results are summarised in the README under "Business Insights".

Usage:
    Run after the Gold views are created. Each query can be run on its own.
===============================================================================
*/

-- 1. Overall numbers
SELECT
    COUNT(*)                     AS order_lines,
    COUNT(DISTINCT order_number) AS orders,
    COUNT(DISTINCT customer_key) AS customers,
    SUM(sales_amount)            AS total_revenue,
    MIN(order_date)              AS first_order,
    MAX(order_date)              AS last_order
FROM gold.fact_sales;

-- 2. Revenue share by product category
SELECT
    p.category,
    SUM(f.sales_amount) AS revenue,
    CAST(100.0 * SUM(f.sales_amount) / SUM(SUM(f.sales_amount)) OVER () AS DECIMAL(5,1)) AS revenue_pct
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY revenue DESC;

-- 3. Revenue and revenue per customer by country
SELECT
    c.country,
    COUNT(DISTINCT c.customer_key)                        AS customers,
    SUM(f.sales_amount)                                   AS revenue,
    SUM(f.sales_amount) / COUNT(DISTINCT c.customer_key)  AS revenue_per_customer
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY revenue DESC;

-- 4. Top 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS revenue
FROM gold.fact_sales f
JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue DESC;

-- 5. Yearly trend
SELECT
    YEAR(order_date)             AS order_year,
    SUM(sales_amount)            AS revenue,
    COUNT(DISTINCT customer_key) AS customers,
    SUM(quantity)                AS units_sold
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year;
