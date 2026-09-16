SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;
SELECT
    COUNT(*) AS total_orders,
    COUNT(order_id) AS order_id_filled,
    COUNT(customer_id) AS customer_id_filled,
    COUNT(order_purchase_timestamp) AS purchase_date_filled,
    COUNT(order_delivered_customer_date) AS delivered_date_filled
FROM orders;
SELECT
    COUNT(*) AS total_products,
    COUNT(product_id) AS product_id_filled,
    COUNT(product_category_name) AS category_filled,
    COUNT(product_weight_g) AS weight_filled,
    COUNT(product_length_cm) AS length_filled,
    COUNT(product_height_cm) AS height_filled,
    COUNT(product_width_cm) AS width_filled
FROM products;

SELECT
    COUNT(*) AS total_orders,
    COUNT(order_id) AS order_id_filled,
    COUNT(customer_id) AS customer_id_filled,
    COUNT(order_purchase_timestamp) AS purchase_date_filled,
    COUNT(order_approved_at) AS approved_date_filled,
    COUNT(order_delivered_carrier_date) AS carrier_date_filled,
    COUNT(order_delivered_customer_date) AS delivered_date_filled,
    COUNT(order_estimated_delivery_date) AS estimated_date_filled
FROM orders;

SELECT
    order_status,
    COUNT(*) AS number_of_orders
FROM orders
GROUP BY order_status
ORDER BY number_of_orders DESC;

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders;

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products
FROM products;

SELECT COUNT(*) AS orders_without_customer
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS items_without_product
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS items_without_seller
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT
    ROUND(SUM(price), 2) AS total_product_sales,
    ROUND(SUM(freight_value), 2) AS total_freight,
    ROUND(SUM(price + freight_value), 2) AS total_order_value
FROM order_items;

SELECT
    ROUND(SUM(price + freight_value) / COUNT(DISTINCT order_id), 2)
        AS average_order_value
FROM order_items;

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS product_sales,
    ROUND(SUM(oi.freight_value), 2) AS freight,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS sales,
    ROUND(SUM(oi.freight_value), 2) AS freight,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_value
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category
ORDER BY sales DESC
LIMIT 15;

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS sales,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT oi.order_id),
        2
    ) AS average_order_value
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category
HAVING COUNT(DISTINCT oi.order_id) >= 100
ORDER BY average_order_value DESC
LIMIT 15;


SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;


SELECT
    customer_unique_id,
    COUNT(*) AS orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY customer_unique_id
ORDER BY orders DESC
LIMIT 20;


SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customers
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) customer_orders
GROUP BY customer_type
ORDER BY customers DESC;


SELECT
    CASE
        WHEN customer_orders.order_count = 1
            THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,

    COUNT(DISTINCT customer_orders.customer_unique_id) AS customers,

    ROUND(SUM(oi.price), 2) AS sales,

    ROUND(
        SUM(oi.price) /
        COUNT(DISTINCT customer_orders.customer_unique_id),
        2
    ) AS sales_per_customer

FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) customer_orders

JOIN customers c
    ON customer_orders.customer_unique_id = c.customer_unique_id

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY customer_type
ORDER BY sales DESC;



SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_estimated_delivery_date
                    - order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS avg_estimated_days

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;


  SELECT
    CASE
        WHEN order_delivered_customer_date
             <= order_estimated_delivery_date
        THEN 'On time'
        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL

GROUP BY delivery_status
ORDER BY orders DESC;


SELECT
    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On time'
        ELSE 'Late'
    END AS delivery_status,

    ROUND(AVG(r.review_score), 2) AS average_review_score,

    COUNT(*) AS reviews

FROM orders o

JOIN order_reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL

GROUP BY delivery_status
ORDER BY average_review_score DESC;


SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,

    COUNT(DISTINCT oi.order_id) AS orders,

    ROUND(SUM(oi.price), 2) AS sales,

    ROUND(AVG(r.review_score), 2) AS avg_review_score

FROM order_items oi

JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name

JOIN orders o
    ON oi.order_id = o.order_id

LEFT JOIN order_reviews r
    ON o.order_id = r.order_id

GROUP BY category

HAVING COUNT(DISTINCT oi.order_id) >= 500

ORDER BY avg_review_score ASC;


SELECT
    r.review_score,
    COUNT(*) AS number_of_reviews,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM order_reviews r
GROUP BY r.review_score
ORDER BY r.review_score;



SELECT
    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On time'
        ELSE 'Late'
    END AS delivery_status,

    CASE
        WHEN r.review_score IN (1, 2)
        THEN 'Low rating'
        ELSE '3+ rating'
    END AS rating_group,

    COUNT(*) AS reviews,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (
            PARTITION BY
                CASE
                    WHEN o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date
                    THEN 'On time'
                    ELSE 'Late'
                END
        ),
        2
    ) AS percentage

FROM orders o

JOIN order_reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL

GROUP BY delivery_status, rating_group
ORDER BY delivery_status, rating_group;

CREATE OR REPLACE VIEW v_olist_analysis AS

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value,
        STRING_AGG(DISTINCT payment_type, ', ') AS payment_types
    FROM order_payments
    GROUP BY order_id
),

review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM order_reviews
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    oi.order_item_id,
    oi.product_id,

    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    oi.seller_id,
    s.seller_city,
    s.seller_state,

    oi.price,
    oi.freight_value,
    COALESCE(oi.price, 0) + COALESCE(oi.freight_value, 0)
        AS total_item_value,

    ps.total_payment_value,
    ps.payment_types,

    rs.average_review_score,

    CASE
        WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date IS NOT NULL
        THEN ROUND(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400.0,
            2
        )
    END AS delivery_days,

    CASE
        WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date IS NOT NULL
        THEN
            CASE
                WHEN o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date
                THEN 'On Time'
                ELSE 'Late'
            END
    END AS delivery_status

FROM orders o

LEFT JOIN customers c
    ON o.customer_id = c.customer_id

LEFT JOIN order_items oi
    ON o.order_id = oi.order_id

LEFT JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id

LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name

LEFT JOIN payment_summary ps
    ON o.order_id = ps.order_id

LEFT JOIN review_summary rs
    ON o.order_id = rs.order_id;

	SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM v_olist_analysis;