USE ecommerce_project;

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price FLOAT,
    freight_value FLOAT
);
USE ecommerce_project;

CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);
USE ecommerce_project;

CREATE TABLE sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);


DROP TABLE `products - products`;

                                                        -- Analytics part

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM payments;
                                                       -- unique cities
SELECT DISTINCT customer_city 
FROM customers;

                                            -- total orders in year 2017
SELECT COUNT(*) AS total_orders_2017
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2017; 
-- insight- A total of 45,101 orders were placed in 2017, indicating significant platform activity. This serves as a baseline to compare growth trends in subsequent years.

                                                -- Total Sales Per Category
SELECT p.product_category_name,
       ROUND(SUM(oi.price),2) AS total_sales
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_sales DESC;
-- insight- top categoryies as per sales are HEALTH BEAUTY, Wtches present and bed table bath, whereas HEALTH BEAUTY contributing majorly in sales with 1258681.34 and then following with Watches present with 1205005 nearly equal with HEALTH BEAUTY.

                                  -- percentage order placed in installments


SELECT 
ROUND(
    COUNT(DISTINCT CASE WHEN payment_installments > 1 THEN order_id END) * 100.0 
    / COUNT(DISTINCT order_id), 2
) AS installment_percentage
FROM payments;
SELECT payment_installments,
       COUNT(*) AS total_orders
FROM payments
GROUP BY payment_installments
ORDER BY payment_installments;
-- insight - Nearly half (49.42%) of all orders are paid using installments, indicating a strong customer preference for flexible payment options. This suggests that offering installment plans is a key driver for conversions and should be maintained or expanded and also most transtaction are concentrated in lower installments of 1, 2 and 3.



                                               -- Customer per state
SELECT customer_state,
       COUNT(*) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;
-- top 3 states are SP,RJ and Mg with coustomer concentration of about 41745, 12852 and 11635 repectively.

                                                -- Orders per month 
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(*) AS total_orders
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2018
GROUP BY month
ORDER BY month;
-- insight 01-2018 has maximum of total ordrs as 7269 followed by 02-2018 6728

                                              -- Average products per order city
SELECT 
    c.customer_city,
    AVG(order_count) AS avg_products
FROM (
    SELECT 
        o.customer_id,
        oi.order_id,
        COUNT(oi.product_id) AS order_count
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    GROUP BY o.customer_id, oi.order_id
) sub
JOIN customers c ON sub.customer_id = c.customer_id
GROUP BY c.customer_city;                

SELECT 
    c.customer_city,
    ROUND(AVG(order_product_count), 2) AS avg_products_per_order
FROM (
    SELECT 
        oi.order_id,
        COUNT(*) AS order_product_count
    FROM order_items oi
    GROUP BY oi.order_id
) t
JOIN orders o ON t.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_city; 

SELECT 
    c.customer_city,
    ROUND(AVG(t.product_count), 2) AS avg_products_per_order
FROM (
    SELECT 
        oi.order_id,
        COUNT(*) AS product_count
    FROM order_items oi
    GROUP BY oi.order_id
) t
JOIN orders o ON t.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY avg_products_per_order DESC;                             
-- insight - Franca with 1.2516 followed by sao bernardo do campo with 1.1422 

                                           -- Revenue contribution by category
SELECT * FROM products LIMIT 5;
SELECT * FROM products LIMIT 1;
                                           
SELECT 
    p.product_category_name,
    SUM(oi.price) AS category_revenue,
    ROUND(
        SUM(oi.price) * 100.0 / 
        (SELECT SUM(price) FROM order_items),
        2
    ) AS revenue_percentage
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY category_revenue DESC;


SELECT 
(
    COUNT(*) * SUM(avg_price * purchase_count) 
    - SUM(avg_price) * SUM(purchase_count)
)
/
SQRT(
    (COUNT(*) * SUM(avg_price * avg_price) - POWER(SUM(avg_price), 2)) *
    (COUNT(*) * SUM(purchase_count * purchase_count) - POWER(SUM(purchase_count), 2))
) AS correlation
FROM (
    SELECT 
        product_id,
        COUNT(*) AS purchase_count,
        AVG(price) AS avg_price
    FROM order_items
    GROUP BY product_id
) t;
											-- seller revenue ranking
SELECT 
    oi.seller_id,
    SUM(oi.price) AS revenue,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS rnk
FROM order_items oi
GROUP BY oi.seller_id;     

 -- comulative monthly sales--
SELECT 
    YEAR(o.order_purchase_timestamp) AS year,
    MONTH(o.order_purchase_timestamp) AS month,
    MONTHNAME(o.order_purchase_timestamp) AS month_name,
    
    SUM(oi.price) AS monthly_sales,
    
    SUM(SUM(oi.price)) OVER (
        PARTITION BY YEAR(o.order_purchase_timestamp)
        ORDER BY MONTH(o.order_purchase_timestamp)
    ) AS cumulative_sales

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id

GROUP BY year, month, month_name
ORDER BY year, month;

                                               -- Top 3 customers per year
SELECT *
FROM (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS year,
        o.customer_id,
        SUM(oi.price) AS total_spent,
        RANK() OVER (
            PARTITION BY YEAR(o.order_purchase_timestamp)
            ORDER BY SUM(oi.price) DESC
        ) AS rnk
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY year, o.customer_id
) t
WHERE rnk <= 3;         


                                              
        

                                  -- Yearly sales                  
                                    
SELECT 
    year,
    total_sales,
    
    LAG(total_sales) OVER (ORDER BY year) AS previous_year_sales,
    
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY year)) 
        / LAG(total_sales) OVER (ORDER BY year) * 100,
    2) AS yoy_growth_percentage

FROM (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS year,
        SUM(oi.price) AS total_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY year
) t
ORDER BY year;                                    
                                    -- First Purchase Per Customer
SELECT 
    customer_id,
    MIN(order_purchase_timestamp) AS first_purchase
FROM orders
GROUP BY customer_id;                                    

                                          -- Full order history with first purchase
SELECT 
    o.customer_id,
    o.order_id,
    o.order_purchase_timestamp,
    f.first_purchase
FROM orders o
JOIN (
    SELECT customer_id, MIN(order_purchase_timestamp) AS first_purchase
    FROM orders
    GROUP BY customer_id
) f
ON o.customer_id = f.customer_id;   

						              -- Moving Average of Order Value--
                                   
WITH order_value AS (
    SELECT 
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_id, o.order_purchase_timestamp
)

SELECT 
    customer_id,
    order_id,
    order_purchase_timestamp,
    order_value,
    
    AVG(order_value) OVER (
        PARTITION BY customer_id
        ORDER BY order_purchase_timestamp
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg

FROM order_value
ORDER BY customer_id, order_purchase_timestamp;
 WITH order_value AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id, o.order_id, o.order_purchase_timestamp
)
SELECT 
    customer_unique_id,
    order_id,
    order_purchase_timestamp,
    order_value,
    
    AVG(order_value) OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchase_timestamp
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg

FROM order_value
ORDER BY customer_unique_id, order_purchase_timestamp;

                                           -- Commulative sales per month--
SELECT 
    year,
    month,
    monthly_sales,
    SUM(monthly_sales) OVER (
        PARTITION BY year 
        ORDER BY month
    ) AS cumulative_sales
FROM (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS year,
        MONTH(o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS monthly_sales
    FROM orders o
    JOIN order_items oi 
    ON o.order_id = oi.order_id
    GROUP BY year, month
) t;                                           

                                         -- Year over year growth rate--
SELECT 
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales,
    ROUND(
        ((total_sales - LAG(total_sales) OVER (ORDER BY year)) 
        / LAG(total_sales) OVER (ORDER BY year)) * 100, 2
    ) AS yoy_growth
FROM (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS year,
        SUM(oi.price) AS total_sales
    FROM orders o
    JOIN order_items oi 
    ON o.order_id = oi.order_id
    GROUP BY year
) t;       

                                -- customer retention within 6 months--
WITH first_orders AS (
    SELECT 
        customer_id,
        MIN(order_purchase_timestamp) AS first_order
    FROM orders
    GROUP BY customer_id
),
repeat_customers AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    JOIN first_orders f 
    ON o.customer_id = f.customer_id
    WHERE o.order_purchase_timestamp > f.first_order
    AND o.order_purchase_timestamp <= DATE_ADD(f.first_order, INTERVAL 6 MONTH)
)
SELECT 
    ROUND(
        COUNT(DISTINCT r.customer_id) * 100.0 / 
        COUNT(DISTINCT f.customer_id), 2
    ) AS retention_rate
FROM first_orders f
LEFT JOIN repeat_customers r 
ON f.customer_id = r.customer_id;                                

                                                -- Top customer per year--
SELECT *
FROM (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS year,
        o.customer_id,
        SUM(oi.price) AS total_spent,
        RANK() OVER (
            PARTITION BY YEAR(o.order_purchase_timestamp)
            ORDER BY SUM(oi.price) DESC
        ) AS rnk
    FROM orders o
    JOIN order_items oi 
    ON o.order_id = oi.order_id
    GROUP BY year, o.customer_id
) t
WHERE rnk <= 3;                                                