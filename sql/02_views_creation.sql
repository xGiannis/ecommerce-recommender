#Tablas utiles:
USE ecommerce_olist;

DROP VIEW IF EXISTS user_product_rating;

CREATE VIEW user_product_rating AS
SELECT
	c.customer_unique_id as user_id,
    oi.product_id as product_id,
    AVG(ore.review_score) as rating
    
FROM orders as o
JOIN customers as c ON c.customer_id = o.customer_id
JOIN order_items as oi ON oi.order_id = o.order_id
JOIN order_reviews as ore ON ore.order_id = o.order_id
WHERE o.order_status = 'delivered' AND ore.review_score IS NOT NULL
GROUP BY user_id, product_id;

SELECT *
FROM user_product_rating
LIMIT 10;


-- Pagos agregados por pedido
CREATE OR REPLACE VIEW order_payments_agg AS
SELECT
  order_id,
  MAX(payment_type) AS main_payment_type,
  MAX(payment_installments) AS max_installments,
  SUM(payment_value) AS total_payment_value
FROM order_payments
GROUP BY order_id;

-- Reviews agregadas por pedido (normalmente hay una sola)
CREATE OR REPLACE VIEW order_reviews_agg AS
SELECT
  order_id,
  MAX(review_score) AS review_score,
  MAX(review_creation_date) AS review_creation_date,
  MAX(review_answer_timestamp) AS review_answer_timestamp
FROM order_reviews
GROUP BY order_id;



CREATE OR REPLACE VIEW order_item_review_ml AS
SELECT
  oi.order_id,
  oi.order_item_id,
  oi.product_id,
  oi.seller_id,
  oi.price,
  oi.freight_value,

  p.product_category_name,
  t.product_category_name_english,
  p.product_weight_g,
  p.product_length_cm,
  p.product_height_cm,
  p.product_width_cm,

  o.order_status,
  o.order_purchase_timestamp,
  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,

  -- features de tiempo
  DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)
    AS delivery_time_days,
  DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date)
    AS delay_vs_estimated_days,

  c.customer_city,
  c.customer_state,

  pay.main_payment_type,
  pay.max_installments,
  pay.total_payment_value,

  r.review_score,
  r.review_creation_date,
  r.review_answer_timestamp,
  DATEDIFF(r.review_creation_date, o.order_delivered_customer_date)
    AS review_delay_days

FROM order_items AS oi
JOIN orders AS o
  ON oi.order_id = o.order_id
JOIN order_reviews_agg AS r
  ON o.order_id = r.order_id
LEFT JOIN order_payments_agg AS pay
  ON o.order_id = pay.order_id
LEFT JOIN products AS p
  ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation AS t
  ON p.product_category_name = t.product_category_name
LEFT JOIN customers AS c
  ON o.customer_id = c.customer_id
WHERE
  r.review_score IS NOT NULL
  AND o.order_status = 'delivered';


SELECT COUNT(*) AS cnt
FROM order_item_review_ml;