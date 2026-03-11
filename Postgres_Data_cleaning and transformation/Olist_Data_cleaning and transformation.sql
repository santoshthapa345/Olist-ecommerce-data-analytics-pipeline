--step 3
UPDATE customers
SET customer_city = REPLACE(LOWER(customer_city), 'ã', 'a');

SELECT 
    order_id ,
    COALESCE(payment_value, 0) AS payment_value_clean
FROM payments;


--Metrices(Step 4)
CREATE OR REPLACE VIEW rfm_segmentation AS
WITH rfm_base AS (
    SELECT 
        o.customer_id,
        MAX(o.order_purchase_timestamp::date) AS last_order_date,
        COUNT(o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM orders o
    JOIN payments p 
        ON o.order_id = p.order_id
    GROUP BY o.customer_id
)

SELECT 
    customer_id,

    -- Recency (days since last order)
    CURRENT_DATE - last_order_date AS recency_days,

    -- R score
    NTILE(5) OVER (ORDER BY CURRENT_DATE - last_order_date DESC) AS r_score,

    -- F score
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,

    -- M score
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score

FROM rfm_base;

SELECT * FROM rfm_segmentation
LIMIT 10;

--Installment Interest
SELECT 
    o.order_id,
    SUM(oi.price + oi.freight_value) AS total_product_value,
    SUM(p.payment_value) AS total_payment_value,

    SUM(p.payment_value) - SUM(oi.price + oi.freight_value) 
        AS installment_interest_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN payments p 
    ON o.order_id = p.order_id
GROUP BY o.order_id;

