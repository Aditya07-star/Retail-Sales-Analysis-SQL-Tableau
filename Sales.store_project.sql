CREATE DATABASE sales_store;

USE sales_store;

#CLEANING DATA 

CREATE TABLE sales_store_temp AS 
SELECT DISTINCT * FROM sales_store;

SELECT transaction_id, COUNT(*)
FROM sales_store
GROUP BY transaction_id
HAVING COUNT(*) > 1;

SELECT DISTINCT * FROM sales_store_temp;

SELECT * FROM sales_store_temp;

#CORRECTING COLUMN NAME

ALTER TABLE sales_store_temp RENAME COLUMN quantiy TO quantity;

ALTER TABLE sales_store_temp RENAME COLUMN prce TO price;

ALTER TABLE sales_store_temp RENAME COLUMN status TO order_status;

DESCRIBE sales_store_temp;

#FINDING NULL VALUES

SELECT 
    SUM(transaction_id IS NULL OR transaction_id = '') AS transaction_id_empty,
    SUM(customer_id IS NULL OR customer_id = '') AS customer_id_empty,
    SUM(customer_name IS NULL OR customer_name = '') AS customer_name_empty,
    SUM(customer_age IS NULL OR customer_age = '') AS customer_age_empty,
    SUM(gender IS NULL OR gender = '') AS gender_empty,
    SUM(product_id IS NULL OR product_id = '') AS product_id_empty,
    SUM(product_name IS NULL OR product_name = '') AS product_name_empty,
    SUM(product_category IS NULL OR product_category = '') AS product_category_empty,
    SUM(quantity IS NULL OR quantity = '') AS quantity_empty,
    SUM(price IS NULL OR price = '') AS price_empty,
    SUM(payment_mode IS NULL OR payment_mode = '') AS payment_mode_empty,
    SUM(purchase_date IS NULL OR purchase_date = '') AS purchase_date_empty,
    SUM(time_of_purchase IS NULL OR time_of_purchase = '') AS time_of_purchase_empty,
    SUM(order_status IS NULL OR order_status = '') AS order_status_empty
FROM sales_store_temp;

#REMOVING DUPLICATES

CREATE TABLE sales_store_clean AS 
SELECT DISTINCT * FROM sales_store_temp;
   
INSERT INTO sales_store_temp SELECT * FROM sales_store_clean;

DROP TABLE sales_store_clean;

SET SQL_SAFE_UPDATES = 0;

#DELETING NULL VALUES

DELETE FROM sales_store_temp 
WHERE transaction_id IS NULL OR transaction_id = ''
   OR customer_id IS NULL OR customer_id = ''
   OR customer_name IS NULL OR customer_name = ''
   OR customer_age IS NULL OR customer_age = ''
   OR gender IS NULL OR gender = ''
   OR product_id IS NULL OR product_id = ''
   OR product_name IS NULL OR product_name = ''
   OR product_category IS NULL OR product_category = ''
   OR quantity IS NULL OR quantity = ''
   OR price IS NULL OR price = ''
   OR payment_mode IS NULL OR payment_mode = ''
   OR purchase_date IS NULL OR purchase_date = ''
   OR time_of_purchase IS NULL OR time_of_purchase = ''
   OR order_status IS NULL OR order_status= '';

SET SQL_SAFE_UPDATES = 1;
  
  #CORRECTING THE GENDER COLUMN
  
SELECT DISTINCT GENDER FROM sales_store_temp; 

SET SQL_SAFE_UPDATES = 0;

SELECT gender, COUNT(*) 
FROM sales_store_temp 
GROUP BY gender;

UPDATE sales_store_temp SET gender = 'Male' WHERE gender IN ('M' , 'Male');
UPDATE sales_store_temp SET gender = 'Female' WHERE gender IN ('F' , 'Female');

#CORRECTING THE payment_mode COLUMN

SELECT DISTINCT payment_mode
FROM sales_store_temp;

UPDATE sales_store_temp SET payment_mode = 'Credit Card' WHERE payment_mode IN ('CC');

# What are the top five most selling product by quantity?

SELECT product_name, SUM(quantity) AS total_quantity_sold
FROM sales_store_temp
WHERE order_status = 'delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

    ----------------------------------------------------------
# Which Product are frequently cancelled?
SELECT product_name, COUNT(*) AS total_cancellation
FROM sales_store_temp
WHERE order_status = 'cancelled'
GROUP BY product_name
ORDER BY total_cancellation DESC
LIMIT 5;

   ----------------------------------------------------
    
# What time of day has the higest number of purchase??

SELECT HOUR(time_of_purchase) AS hour_of_day, COUNT(*) AS total_purchase
FROM sales_store_temp
GROUP BY hour_of_day 
ORDER BY total_purchase DESC;



    ----------------------------------------------------
    
# Who are the top five most spending customer?

SELECT customer_name,
CONCAT('Rs. ', FORMAT(SUM(price * quantity), 2) )AS top_spends
FROM sales_store_temp
GROUP BY customer_id,customer_name
ORDER BY SUM(price * quantity) DESC
LIMIT 5;


   ----------------------------------------------------

# Which Product categories generate the highest revenue??

SELECT product_category, 
CONCAT('Rs. ',FORMAT(SUM(price * quantity), 2) ) AS revenue
FROM sales_store_temp
GROUP BY product_category
ORDER BY SUM(price * quantity) DESC
LIMIT 5;
#BUSINESS IMPACT - TOP PERFORMING PRODUCT CATEGORIES.
  --------------------------------------------------------
  
# WHAT IS RETURN/CANCELLATION RATE PER PRODUCT?

SELECT 
    product_name, 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status IN ('cancelled', 'returned') THEN 1 ELSE 0 END) AS total_returned_cancelled,
    CONCAT(
        ROUND(
            (SUM(CASE WHEN order_status IN ('cancelled', 'returned') THEN 1 ELSE 0 END) / COUNT(*)) * 100, 
            2
        ), 
        '%'
    ) AS return_cancel_rate
FROM sales_store_temp
WHERE product_name IS NOT NULL AND product_name != ''
GROUP BY product_name
ORDER BY (SUM(CASE WHEN order_status IN ('cancelled', 'returned') THEN 1 ELSE 0 END) / COUNT(*)) DESC;



    -------------------------------------------------------------
    
# WHAT IS THE MOST PREFERRED PAYMENT MODE?
 
 SELECT 
    payment_mode, 
    COUNT(*) AS total_transactions,
    CONCAT(
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sales_store_temp), 2), 
        '%'
    ) AS percentage_share
FROM sales_store_temp
WHERE payment_mode IS NOT NULL AND payment_mode != ''
GROUP BY payment_mode
ORDER BY total_transactions DESC;
---------------------------------------------------------------

# HOW DOES AGE GROUP AFFECT PURCHASHING BEHAVIOUR?

SELECT 
    CASE 
        WHEN customer_age < 18 THEN 'Under 18'
        WHEN customer_age BETWEEN 18 AND 30 THEN '18-30 (Young Adult)'
        WHEN customer_age BETWEEN 31 AND 50 THEN '31-50 (Adult)'
        WHEN customer_age > 50 THEN '50+ (Senior)'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS total_transactions,
    CONCAT('Rs. ', FORMAT(SUM(price * quantity), 2)) AS total_revenue,
    ROUND(AVG(price * quantity), 2) AS avg_order_value
FROM sales_store_temp
WHERE customer_age IS NOT NULL AND customer_age > 0 -- Cleaning step
GROUP BY age_group
ORDER BY SUM(price * quantity) DESC;

-------------------------------------------------------------

# WHAT IS THE MONTHLY SALES TREND?

SELECT 
    YEAR(STR_TO_DATE(purchase_date, '%d-%m-%Y')) AS sales_year,
    MONTHNAME(STR_TO_DATE(purchase_date, '%d-%m-%Y')) AS sales_month,
    CONCAT('Rs. ', FORMAT(SUM(price * quantity), 2)) AS total_revenue
FROM sales_store_temp
WHERE order_status = 'delivered' -- Only count successful sales
GROUP BY sales_year, sales_month, MONTH(STR_TO_DATE(purchase_date, '%d-%m-%Y'))
ORDER BY sales_year, MONTH(STR_TO_DATE(purchase_date, '%d-%m-%Y'));

--------------------------------------------------------------

# ARE CERTAIN GENDER BUYING MORE SPECIFIC PRODUCT CATEGORIES?

SELECT 
    gender, 
    product_category, 
    COUNT(*) AS total_orders,
    SUM(quantity) AS total_quantity_bought,
    CONCAT('Rs. ', FORMAT(SUM(price * quantity), 2)) AS total_revenue
FROM sales_store_temp
WHERE gender IS NOT NULL AND gender != ''
  AND product_category IS NOT NULL AND product_category != ''
GROUP BY gender, product_category
ORDER BY gender, total_quantity_bought DESC;

SELECT @@hostname;

SHOW VARIABLES LIKE 'port';