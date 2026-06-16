-- =========================================
-- STORED PROCEDURE: Customer Loyalty Analysis
-- =========================================
-- DESCRIPTION:
-- This stored procedure runs multiple analytical queries
-- on the customer_behavior table to generate insights
-- about customer spending, loyalty, segmentation, and product performance.
--
-- HOW TO USE:
-- 1. Ensure database "customer_behavior" is selected
-- 2. Execute this script to create the procedure
-- 3. Run the procedure using:
--    EXEC sp_customer_loyalty_analysis;
--
-- OUTPUT:
-- Multiple result sets including:
-- - Revenue by gender
-- - High-value discount customers
-- - Product ratings
-- - Shipping behavior
-- - Loyalty segmentation
-- - Top products per category
-- - Revenue analysis
--
-- =========================================

CREATE PROCEDURE sp_customer_loyalty_analysis
AS
BEGIN

    SET NOCOUNT ON;

    -- Q1: Revenue by gender
    SELECT
        gender,
        SUM(purchase_amount) AS revenue
    FROM customer_behavior
    GROUP BY gender;


    -- Q2: Customers who used discount and spent above average
    WITH avg_cte AS (
        SELECT AVG(purchase_amount) AS avg_purchase
        FROM customer_behavior
    )
    SELECT
        customer_id,
        purchase_amount
    FROM customer_behavior, avg_cte
    WHERE purchase_amount > avg_cte.avg_purchase
    AND discount_applied = 'Yes';


    -- Q3: Count of high-spending discount users
    WITH avg_cte AS (
        SELECT AVG(purchase_amount) AS avg_purchase
        FROM customer_behavior
    )
    SELECT
        COUNT(*) AS total_customers
    FROM customer_behavior, avg_cte
    WHERE purchase_amount > avg_cte.avg_purchase
    AND discount_applied = 'Yes';


    -- Q4: Top 5 products by rating
    SELECT TOP 5
        item_purchased,
        ROUND(AVG(review_rating), 2) AS avg_rating
    FROM customer_behavior
    GROUP BY item_purchased
    ORDER BY avg_rating DESC;


    -- Q5: Shipping impact on spending
    SELECT
        shipping_type,
        AVG(purchase_amount) AS avg_purchase
    FROM customer_behavior
    WHERE shipping_type IN ('Standard', 'Express')
    GROUP BY shipping_type;


    -- Q6: Subscription vs spending behavior
    SELECT
        CASE 
            WHEN subscription_status = 'Yes' THEN 'Subscribed'
            ELSE 'Unsubscribed'
        END AS subscription_status,
        COUNT(*) AS total_customers,
        SUM(purchase_amount) AS revenue,
        AVG(purchase_amount) AS avg_spend
    FROM customer_behavior
    GROUP BY subscription_status;


    -- Q7: Discount usage rate per product
    SELECT TOP 5
        item_purchased,
        ROUND(
            SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            1
        ) AS discount_percentage
    FROM customer_behavior
    GROUP BY item_purchased
    ORDER BY discount_percentage DESC;


    -- Q8: Customer loyalty segmentation
    SELECT
        CASE 
            WHEN previous_purchases > 10 THEN 'Loyal'
            WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
            ELSE 'New'
        END AS loyalty_segment,
        COUNT(*) AS segment_count
    FROM customer_behavior
    GROUP BY 
        CASE 
            WHEN previous_purchases > 10 THEN 'Loyal'
            WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
            ELSE 'New'
        END
    ORDER BY segment_count DESC;


    -- Q9: Top 3 products per category
    SELECT *
    FROM (
        SELECT
            category,
            item_purchased,
            COUNT(*) AS total_orders,
            ROW_NUMBER() OVER (
                PARTITION BY category
                ORDER BY COUNT(*) DESC
            ) AS rank
        FROM customer_behavior
        GROUP BY category, item_purchased
    ) t
    WHERE rank <= 3;


    -- Q10: Revenue by age group
    SELECT
        age_grouped,
        SUM(purchase_amount) AS revenue
    FROM customer_behavior
    GROUP BY age_grouped
    ORDER BY revenue DESC;

END;
GO

EXEC sp_customer_loyalty_analysis
