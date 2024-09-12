-- creating database
CREATE DATABASE IF NOT EXISTS electronic_sales;
USE electronic_sales;

-- creating sales table with value names
CREATE TABLE IF NOT EXISTS sales (
	product_id INT PRIMARY KEY,
    category VARCHAR(20),
    brand VARCHAR(20),
    price DECIMAL(10, 2),
    customer_age INT,
    gender INT,
    purchase_frequency INT,
    satisfaction INT,
    purchase_intent INT
);

-- adding product_revenue column
ALTER TABLE sales
ADD COLUMN product_revenue DECIMAL(20, 2);

UPDATE sales
SET product_revenue = price * purchase_frequency;

-- select first five entries from sales dataframe
SELECT * FROM sales
LIMIT 5;


-- what is the total revenue, total sales, and revenue
-- per sale numbers per company
SELECT brand, 
       SUM(product_revenue) AS total_revenue,
       SUM(purchase_frequency) AS total_sales,
       ROUND((SUM(product_revenue) / SUM(purchase_frequency)), 2) AS revenue_per_sale
FROM sales
GROUP BY brand
ORDER BY total_revenue DESC;

-- how might average satisfaction per company influence
-- the company's total revenue ranking
SELECT brand, 
       AVG(satisfaction) AS avg_satisfaction, 
       RANK() OVER(ORDER BY SUM(product_revenue) DESC) AS revenue_ranking
FROM sales
GROUP BY brand
ORDER BY avg_satisfaction DESC;

-- how does each category and their revenues stack up 
-- with satisfaction and age
SELECT category,
       AVG(satisfaction) AS avg_satisfaction,
       SUM(purchase_frequency) AS total_purchases,
       SUM(product_revenue) AS total_revenue,
       SUM(product_revenue) / SUM(purchase_frequency) AS revenue_per_sale,
       AVG(customer_age) AS avg_age
FROM sales
GROUP BY category
ORDER BY total_revenue DESC;



-- which brand and category combination produces 
-- the most revenue
SELECT brand,
	   category,
       SUM(purchase_frequency) AS total_sales,
       RANK() OVER(ORDER BY SUM(purchase_frequency) DESC) AS total_sales_rank,
       SUM(product_revenue) AS total_revenue,
       RANK() OVER(ORDER BY SUM(product_revenue) DESC) AS revenue_rank
FROM sales
GROUP BY brand, category
ORDER BY brand, category;


-- how does each company's product revenue rankings 
-- stack up compared to average satisfaction ratings
SELECT brand,
	   category,
       AVG(satisfaction) AS avg_satisfaction,
       RANK() OVER(ORDER BY AVG(satisfaction) DESC) AS satisfaction_rank,
       RANK() OVER(ORDER BY SUM(product_revenue) DESC) AS revenue_rank
FROM sales
GROUP BY brand, category
ORDER BY brand, category;

-- how many of each brand's products have an average satisfaction
-- rating above the dataframes average satisfaction rating
SELECT brand, 
       category, 
       AVG(satisfaction) AS avg_satisfaction,
       RANK() OVER(ORDER BY AVG(satisfaction) DESC) AS satisfaction_rank
FROM sales
GROUP BY brand, category
HAVING AVG(satisfaction) > (
    SELECT AVG(satisfaction)
    FROM sales 
)
ORDER BY brand;


-- get the expected revenenues for all products that 
-- have above a 3 satisfaction rating, which is the average
WITH revenue_per_satisfaction AS (
    SELECT 
        SUM(product_revenue) / SUM(satisfaction) AS revenue_per_satisfaction_unit
    FROM sales
)
SELECT brand, 
	   category, 
       AVG(satisfaction) AS avg_satisfaction,
       SUM(product_revenue) AS total_revenue,
       ROUND(((AVG(satisfaction) * 
       (SELECT revenue_per_satisfaction_unit
		FROM revenue_per_satisfaction)) + 
        (SELECT AVG(total_product_rev) - 
				(3 * (SELECT (SUM(product_revenue) / SUM(satisfaction)) AS rev_per_satisfaction_unit
					  FROM sales)) AS intercept
		 FROM (SELECT brand, 
					  category, 
					  SUM(product_revenue) AS total_product_rev, 
					  AVG(satisfaction) AS avg_satisfaction
			   FROM sales
			   GROUP BY brand, category) AS satisfaction_query)), 2) AS estimated_total_revenue
FROM sales
GROUP BY brand, category
HAVING AVG(satisfaction) > (
    SELECT AVG(satisfaction)
    FROM sales 
)
ORDER BY brand;

-- male vs. female spending, avg intent and purchase frequency
SELECT CASE WHEN gender = 1 THEN 'F' ELSE 'M' END AS gender,
	   SUM(purchase_frequency) AS total_sales,
       SUM(product_revenue) / SUM(purchase_frequency) AS spending_per_sale,
       AVG(purchase_frequency) AS avg_purchase_frequency,
       AVG(satisfaction) AS avg_satisfaction,
       AVG(purchase_intent) AS avg_intent
FROM sales
GROUP BY gender;


-- intent, spending, average spending, and most frequently
-- bought brands and categories for every age and gender
WITH category_frequency AS (
    SELECT customer_age, 
           CASE WHEN gender = 1 THEN 'F' ELSE 'M' END AS gender,
           category, 
           SUM(purchase_frequency) AS purchase_count
    FROM sales
    GROUP BY customer_age, gender, category
),
brand_frequency AS (
    SELECT customer_age, 
           CASE WHEN gender = 1 THEN 'F' ELSE 'M' END AS gender,
           brand, 
           SUM(purchase_frequency) AS brand_count
    FROM sales
    GROUP BY customer_age, gender, brand
),
most_frequent_category AS (
    SELECT customer_age, gender, category,
           RANK() OVER (PARTITION BY customer_age, gender ORDER BY purchase_count DESC) AS category_rank
    FROM category_frequency
),
most_frequent_brand AS (
    SELECT customer_age, gender, brand, 
           RANK() OVER (PARTITION BY customer_age, gender ORDER BY brand_count DESC) AS brand_rank
    FROM brand_frequency
)
SELECT s.customer_age, 
       CASE WHEN s.gender = 1 THEN 'F' ELSE 'M' END AS gender, 
       AVG(s.purchase_intent) AS avg_intent,
       ROUND((SUM(product_revenue) / SUM(purchase_frequency)), 2) AS avg_spending,
       RANK() OVER(ORDER BY SUM(product_revenue) / SUM(purchase_frequency) DESC) AS avg_spending_rank,
       RANK() OVER(ORDER BY SUM(product_revenue) DESC) AS total_spending_rank,
       mfc.category AS most_frequent_category,
       mfb.brand AS most_frequent_brand
FROM sales s
LEFT JOIN most_frequent_category mfc 
    ON s.customer_age = mfc.customer_age 
   AND (CASE WHEN s.gender = 1 THEN 'F' ELSE 'M' END) = mfc.gender
   AND mfc.category_rank = 1  
LEFT JOIN most_frequent_brand mfb
    ON s.customer_age = mfb.customer_age
    AND (CASE WHEN s.gender = 1 THEN 'F' ELSE 'M' END) = mfb.gender
   AND mfb.brand_rank = 1 
GROUP BY s.customer_age, gender, mfc.category, mfb.brand
ORDER BY s.customer_age, gender;


-- what is the average customer age and gender by brand/category
-- along with avg satisfaction and intent/ total count
SELECT brand, 
       category, 
       AVG(customer_age) AS avg_customer_age, 
	   AVG(gender) AS avg_gender, 
       SUM(purchase_frequency) AS count_sold, 
	   AVG(satisfaction) AS avg_satisfaction,
       AVG(purchase_intent) AS avg_intent,
       RANK() OVER(ORDER BY AVG(customer_age)) AS age_rank
FROM sales
GROUP BY brand, category
ORDER BY brand, category;

-- what is the average age and gender per each brand 
-- along with intent and satisfaction
SELECT brand, 
       AVG(customer_age) AS avg_customer_age, 
	   AVG(gender) AS avg_gender, 
       SUM(purchase_frequency) AS count_sold, 
	   AVG(satisfaction) AS avg_satisfaction,
       AVG(purchase_intent) AS avg_intent,
       RANK() OVER(ORDER BY AVG(customer_age)) AS age_rank
FROM sales
GROUP BY brand
ORDER BY brand;


-- what are the satisfaction, frequency, revenue
-- and favorite brand and categories for each age group
-- when divided into seven age groups
WITH category_frequency AS (
    SELECT  
           CASE 
       WHEN customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN customer_age BETWEEN 62 AND 69 THEN '62-69'
    END AS age_group,
           category, 
           SUM(purchase_frequency) AS purchase_count
    FROM sales
    GROUP BY age_group, category
),
brand_frequency AS (
    SELECT  
           CASE 
       WHEN customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN customer_age BETWEEN 62 AND 69 THEN '62-69'
    END AS age_group,
           brand, 
           SUM(purchase_frequency) AS brand_count
    FROM sales
    GROUP BY age_group, brand
),
most_frequent_category AS (
    SELECT age_group, category,
           RANK() OVER (PARTITION BY age_group ORDER BY purchase_count DESC) AS category_rank
    FROM category_frequency
),
most_frequent_brand AS (
    SELECT age_group, brand, 
           RANK() OVER (PARTITION BY age_group ORDER BY brand_count DESC) AS brand_rank
    FROM brand_frequency
)
SELECT 
       CASE 
       WHEN s.customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN s.customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN s.customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN s.customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN s.customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN s.customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN s.customer_age BETWEEN 62 AND 69 THEN '62-69'
    END AS age_group,
        SUM(s.purchase_frequency) AS customers_per_group,
		AVG(s.satisfaction) AS avg_satisfaction,
		AVG(s.purchase_frequency) AS avg_frequency,
		SUM(s.product_revenue) AS total_rev,
		ROUND((SUM(s.product_revenue) / SUM(s.purchase_frequency)), 2) AS rev_per_customer,
		RANK() OVER(ORDER BY SUM(s.product_revenue) / SUM(s.purchase_frequency) DESC) AS rank_rev_per_customer,
        mfc.category AS most_frequent_category,
        mfb.brand AS most_frequent_brand
FROM sales s
LEFT JOIN most_frequent_category mfc 
    ON (CASE 
       WHEN s.customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN s.customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN s.customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN s.customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN s.customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN s.customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN s.customer_age BETWEEN 62 AND 69 THEN '62-69'
    END) = mfc.age_group
   AND mfc.category_rank = 1  
LEFT JOIN most_frequent_brand mfb
    ON (CASE 
       WHEN s.customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN s.customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN s.customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN s.customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN s.customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN s.customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN s.customer_age BETWEEN 62 AND 69 THEN '62-69'
    END) = mfb.age_group
   AND mfb.brand_rank = 1 
GROUP BY 
	CASE 
        WHEN s.customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN s.customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN s.customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN s.customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN s.customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN s.customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN s.customer_age BETWEEN 62 AND 69 THEN '62-69'
    END, mfc.category, mfb.brand
ORDER BY CASE 
        WHEN s.customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN s.customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN s.customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN s.customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN s.customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN s.customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN s.customer_age BETWEEN 62 AND 69 THEN '62-69'
    END;

-- do different aged customers spend more on 
-- different types of products?
SELECT 
	   CASE 
       WHEN customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN customer_age BETWEEN 62 AND 69 THEN '62-69'
    END AS age_group,
    category,
    SUM(purchase_frequency) AS sales_per_group,
	AVG(purchase_frequency) AS avg_frequency,
    SUM(product_revenue) AS total_rev,
    RANK() OVER(ORDER BY SUM(purchase_frequency) DESC) AS total_purchase_rank,
    RANK() OVER(ORDER BY (SUM(product_revenue) / SUM(purchase_frequency)) DESC) AS rev_per_purchase_rank
FROM sales
GROUP BY age_group, category
ORDER BY age_group, category;

-- which age group and gender combinations bring
-- in the most revenue per customer
SELECT 
	   CASE 
       WHEN customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN customer_age BETWEEN 62 AND 69 THEN '62-69'
    END AS age_group,
    CASE WHEN gender = 1 THEN 'F' ELSE 'M' END AS gender,
    SUM(purchase_frequency) AS customers_per_group,
    AVG(satisfaction) AS avg_satisfaction,
	AVG(purchase_frequency) AS avg_frequency,
    SUM(product_revenue) AS total_rev,
    ROUND((SUM(product_revenue) / SUM(purchase_frequency)), 2) AS rev_per_customer,
    RANK() OVER(ORDER BY SUM(product_revenue) / SUM(purchase_frequency) DESC) AS rank_rev_per_customer
FROM sales
GROUP BY age_group, gender
ORDER BY age_group, gender;



-- age group purchasing breakdown by brand
SELECT 
	   CASE 
       WHEN customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN customer_age BETWEEN 25 AND 31 THEN '25-31'
        WHEN customer_age BETWEEN 32 AND 39 THEN '32-39'
        WHEN customer_age BETWEEN 40 AND 46 THEN '40-46'
        WHEN customer_age BETWEEN 47 AND 54 THEN '47-54'
        WHEN customer_age BETWEEN 55 AND 61 THEN '55-61'
        WHEN customer_age BETWEEN 62 AND 69 THEN '62-69'
    END AS age_group,
    brand,
    SUM(purchase_frequency) AS customers_per_group,
	AVG(purchase_frequency) AS avg_frequency,
    SUM(product_revenue) AS total_rev,
    RANK() OVER(ORDER BY (SUM(product_revenue) / SUM(purchase_frequency)) DESC) AS rev_rank
FROM sales
GROUP BY age_group, brand
ORDER BY age_group, brand;

-- highest individual groups of people by reliability
-- in spending and frequency by percentile rank
WITH customer_spending AS (
    SELECT customer_age, 
           gender, 
           SUM(product_revenue) AS total_spent,
           AVG(purchase_frequency) AS avg_frequency
    FROM sales
    GROUP BY customer_age, gender
),
customer_rankings AS (
    SELECT customer_age, 
           gender, 
           total_spent, 
           avg_frequency,
           PERCENT_RANK() OVER (ORDER BY total_spent) AS spending_percentile,
           PERCENT_RANK() OVER (ORDER BY avg_frequency) AS frequency_percentile
    FROM customer_spending
)
SELECT customer_age, 
       CASE WHEN gender = 1 THEN 'F' ELSE 'M' END AS gender,
       total_spent,
       avg_frequency,
       spending_percentile,
       frequency_percentile
FROM customer_rankings
WHERE spending_percentile >= 0.8 AND frequency_percentile >= 0.8
ORDER BY total_spent DESC;


-- which customers are the most valuable
WITH customer_lifetime_value AS (
    SELECT customer_age, 
           gender, 
           SUM(product_revenue) AS total_spent,
           ROUND(
            (SUM(product_revenue) / SUM(purchase_frequency)) * (AVG(purchase_frequency) * 5) * 
            (AVG(purchase_intent) / 1) * 
            (AVG(satisfaction) / 5),       
            2
        ) AS clv
    FROM sales
    GROUP BY customer_age, gender
)
SELECT customer_age, 
       CASE WHEN gender = 1 THEN 'F' ELSE 'M' END AS gender,
       total_spent,
       ROUND(clv, 2) AS lifetime_value
FROM customer_lifetime_value
ORDER BY clv DESC;

