--Cleaning Data

--1
UPDATE customers
SET customer_city = REPLACE(LOWER(customer_city), 'ã', 'a');

--2
SELECT 
    order_id ,
    COALESCE(payment_value, 0) AS payment_value_clean
FROM payments;

/*SELECT order_id
FROM payments
WHERE payment_value IS NULL;

UPDATE payments
SET payment_value = 0
WHERE payment_value IS NULL;
*/



--Transform Data & Create Engineered Metrics

--1 RFM Segmentation
CREATE OR REPLACE VIEW rfm_segmentations AS
WITH rfm_base AS (
    SELECT 
        o.customer_id,
        MAX(o.order_purchase_timestamp::date) AS last_order_date,
        COUNT(o.order_id) AS frequency,
        SUM(COALESCE(p.payment_value, 0)) AS monetary
    FROM orders o
    JOIN payments p 
        ON o.order_id = p.order_id
    GROUP BY o.customer_id
)
SELECT 
    customer_id,
    CURRENT_DATE - last_order_date AS recency_days,
    6 - NTILE(5) OVER (ORDER BY CURRENT_DATE - last_order_date ASC) AS r_score,
    6 - NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
    6 - NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
FROM rfm_base;

SELECT * FROM rfm_segmentations
LIMIT 10;

--Installment Interest

CREATE VIEW installment_interests AS
SELECT 
    o.order_id,
    SUM(oi.price + oi.freight_value) AS total_product_value,
    SUM(p.payment_value) AS total_payment_value,
    SUM(p.payment_value) - SUM(oi.price + oi.freight_value) AS installment_interest_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY o.order_id;

SELECT * FROM installment_interests
LIMIT 20;


