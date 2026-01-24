CREATE DATABASE ecommerce_olist
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE ecommerce_olist;
	
CREATE TABLE customers (
    customer_id              VARCHAR(50) PRIMARY KEY,
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(10)
);

CREATE TABLE products (
    product_id                    VARCHAR(50) PRIMARY KEY,
    product_category_name         VARCHAR(100),
    product_name_lenght           INT,
    product_description_lenght    INT,
    product_photos_qty            INT,
    product_weight_g              INT,
    product_length_cm             INT,
    product_height_cm             INT,
    product_width_cm              INT
);

CREATE TABLE orders (
    order_id                       VARCHAR(50) PRIMARY KEY,
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)order_items
);


CREATE TABLE order_items (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE order_payments (
    order_id                VARCHAR(50),
    payment_sequential      INT,
    payment_type            VARCHAR(20),
    payment_installments    INT,
    payment_value           DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA/olist_orders_dataset.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  order_id,
  customer_id,
  order_status,
  @order_purchase_timestamp,
  @order_approved_at,
  @order_delivered_carrier_date,
  @order_delivered_customer_date,
  @order_estimated_delivery_date
)
SET
  order_purchase_timestamp = STR_TO_DATE(@order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
  order_approved_at =
    CASE WHEN @order_approved_at = '' THEN NULL
         ELSE STR_TO_DATE(@order_approved_at, '%Y-%m-%d %H:%i:%s') END,
  order_delivered_carrier_date =
    CASE WHEN @order_delivered_carrier_date = '' THEN NULL
         ELSE STR_TO_DATE(@order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s') END,
  order_delivered_customer_date =
    CASE WHEN @order_delivered_customer_date = '' THEN NULL
         ELSE STR_TO_DATE(@order_delivered_customer_date, '%Y-%m-%d %H:%i:%s') END,
  order_estimated_delivery_date =
    STR_TO_DATE(@order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s');
    
LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA/olist_products_dataset.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  product_id,
  product_category_name,
  @product_name_lenght,
  @product_description_lenght,
  @product_photos_qty,
  @product_weight_g,
  @product_length_cm,
  @product_height_cm,
  @product_width_cm
)
SET
  product_name_lenght        = NULLIF(@product_name_lenght, ''),
  product_description_lenght = NULLIF(@product_description_lenght, ''),
  product_photos_qty         = NULLIF(@product_photos_qty, ''),
  product_weight_g           = NULLIF(@product_weight_g, ''),
  product_length_cm          = NULLIF(@product_length_cm, ''),
  product_height_cm          = NULLIF(@product_height_cm, ''),
  product_width_cm           = NULLIF(@product_width_cm, '');

LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA/olist_order_items_dataset.csv'
INTO TABLE order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES

(
order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value
)

SET
	seller_id= NULLIF(seller_id,''),
    shipping_limit_date = NULLIF(shipping_limit_date,''),
    price = NULLIF(price,''),
    freight_value = NULLIF(freight_value,'');



CREATE TABLE order_items_stg (
    order_id             VARCHAR(50),
    order_item_id        VARCHAR(10),
    product_id           VARCHAR(50),
    seller_id            VARCHAR(50),
    shipping_limit_date  VARCHAR(50),
    price                VARCHAR(20),
    freight_value        VARCHAR(20)
) CHARACTER SET utf8mb4;


LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA//olist_order_items_dataset.csv'
INTO TABLE order_items_stg
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value
);


INSERT INTO order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)


SELECT
    NULLIF(order_id, ''),
    CAST(NULLIF(order_item_id, '') AS UNSIGNED),
    NULLIF(product_id, ''),
    NULLIF(seller_id, ''),
    STR_TO_DATE(NULLIF(shipping_limit_date, ''), '%Y-%m-%d %H:%i:%s'),
    CAST(NULLIF(price, '') AS DECIMAL(10,2)),
    CAST(NULLIF(freight_value, '') AS DECIMAL(10,2))
FROM order_items_stg;

#ORDER PAYMENTS
DROP TABLE IF EXISTS order_items_stg;

CREATE TABLE order_payments_stg (
    order_id             VARCHAR(50),
    payment_sequential   VARCHAR(10),
    payment_type         VARCHAR(50),
    payment_installments VARCHAR(10),
    payment_value        VARCHAR(50)
);



LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA//olist_order_payments_dataset.csv'
INTO TABLE order_payments_stg
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


INSERT INTO order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    order_id,
    CAST(NULLIF(payment_sequential,   '') AS UNSIGNED)          AS payment_sequential,
    NULLIF(payment_type,              '')                  AS payment_type,
    CAST(NULLIF(payment_installments, '') AS UNSIGNED)          AS payment_installments,
    CAST(NULLIF(payment_value,        '') AS DECIMAL(10,2)) AS payment_value
FROM order_payments_stg;



#ORDER REVIEWS
CREATE TABLE order_reviews_raw (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            VARCHAR(5),
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    VARCHAR(50),
    review_answer_timestamp VARCHAR(50)
);

LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA//olist_order_reviews_dataset.csv'
INTO TABLE order_reviews_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
);


DROP TABLE IF EXISTS order_reviews;

CREATE TABLE order_reviews (
    review_id               VARCHAR(50)  NOT NULL,
    order_id                VARCHAR(50)  NOT NULL,
    review_score            TINYINT UNSIGNED,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id)
);



INSERT IGNORE INTO order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    review_id,
    order_id,
    CAST(NULLIF(review_score, '') AS UNSIGNED)      AS review_score,
    NULLIF(review_comment_title,   '')              AS review_comment_title,
    NULLIF(review_comment_message, '')              AS review_comment_message,
    NULLIF(review_creation_date,    '')             AS review_creation_date,
    NULLIF(review_answer_timestamp, '')             AS review_answer_timestamp
FROM order_reviews_raw;


#todas tienen un espacio \r al final que esta 'deprecated'. Lo limpio
SET SQL_SAFE_UPDATES = 0;

UPDATE order_reviews_raw
SET
    review_creation_date    = TRIM(REPLACE(review_creation_date, '\r', '')),
    review_answer_timestamp = TRIM(REPLACE(review_answer_timestamp, '\r', ''));
    
SET SQL_SAFE_UPDATES = 1;
    



#Ver anotación notas: Borro las filas con error (es solo 1)
SET SQL_SAFE_UPDATES = 0;
DELETE FROM order_reviews_raw
WHERE review_id = '636b237e87574ba29654deaba9eb9797';
DELETE FROM order_reviews
WHERE review_id = '636b237e87574ba29654deaba9eb9797';

SET SQL_SAFE_UPDATES = 1;

UPDATE order_reviews r
JOIN order_reviews_raw rr
  ON r.review_id = rr.review_id
SET r.review_creation_date = STR_TO_DATE(NULLIF(rr.review_creation_date, ''), '%Y-%m-%d %H:%i:%s'),
    r.review_answer_timestamp = STR_TO_DATE(NULLIF(rr.review_answer_timestamp, ''), '%Y-%m-%d %H:%i:%s');

SET SQL_SAFE_UPDATES = 1;



#Agrego algunas FK

ALTER TABLE order_reviews
    ADD CONSTRAINT fk_reviews_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id);


#Vamos a crear unas nuevas tablas, estas seran usadas para predeciur un review_score dado un producto

-- sellers
CREATE TABLE IF NOT EXISTS olist_sellers (
  seller_id             VARCHAR(50) PRIMARY KEY,
  seller_zip_code_prefix CHAR(5),
  seller_city           VARCHAR(100),
  seller_state          CHAR(2)
);

--  geolocation
DROP TABLE IF EXISTS olist_geolocation;
CREATE TABLE IF NOT EXISTS olist_geolocation (
  geolocation_zip_code_prefix CHAR(5),
  geolocation_lat             DECIMAL(9,6),
  geolocation_lng             DECIMAL(9,6),
  geolocation_city            VARCHAR(100),
  geolocation_state           CHAR(2)
);

--  traducción de categorías
CREATE TABLE IF NOT EXISTS product_category_name_translation (
  product_category_name         VARCHAR(100) PRIMARY KEY,
  product_category_name_english VARCHAR(100)
);


USE ecommerce_olist;

DROP TABLE IF EXISTS olist_sellers_stg;

CREATE TABLE olist_sellers_stg (
  seller_id              VARCHAR(50),
  seller_zip_code_prefix VARCHAR(20),
  seller_city            VARCHAR(100),
  seller_state           VARCHAR(10)
) CHARACTER SET utf8mb4;

LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA//olist_sellers_dataset.csv'
INTO TABLE olist_sellers_stg
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Pasamos a la tabla final tipada
TRUNCATE TABLE olist_sellers;

INSERT INTO olist_sellers (
  seller_id,
  seller_zip_code_prefix,
  seller_city,
  seller_state
)
SELECT
  NULLIF(seller_id, ''),
  NULLIF(seller_zip_code_prefix, ''),
  NULLIF(seller_city, ''),
  NULLIF(seller_state, '')
FROM olist_sellers_stg;

-- ---------------------------------
DROP TABLE IF EXISTS olist_geolocation_stg;

CREATE TABLE olist_geolocation_stg (
  geolocation_zip_code_prefix VARCHAR(20),
  geolocation_lat             VARCHAR(50),
  geolocation_lng             VARCHAR(50),
  geolocation_city            VARCHAR(100),
  geolocation_state           VARCHAR(10)
) CHARACTER SET utf8mb4;

LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA//olist_geolocation_dataset.csv'
INTO TABLE olist_geolocation_stg
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

TRUNCATE TABLE olist_geolocation;

INSERT INTO olist_geolocation (
  geolocation_zip_code_prefix,
  geolocation_lat,
  geolocation_lng,
  geolocation_city,
  geolocation_state
)
SELECT
  NULLIF(geolocation_zip_code_prefix, ''),
  CAST(NULLIF(geolocation_lat, '') AS DECIMAL(9,6)),
  CAST(NULLIF(geolocation_lng, '') AS DECIMAL(9,6)),
  NULLIF(geolocation_city, ''),
  NULLIF(geolocation_state, '')
FROM olist_geolocation_stg;

-- -----------------------------------

DROP TABLE IF EXISTS product_category_name_translation_stg;

CREATE TABLE product_category_name_translation_stg (
  product_category_name         VARCHAR(100),
  product_category_name_english VARCHAR(100)
) CHARACTER SET utf8mb4;

LOAD DATA LOCAL INFILE '/RUTA/A/TU/DATA//product_category_name_translation.csv'
INTO TABLE product_category_name_translation_stg
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

TRUNCATE TABLE product_category_name_translation;

INSERT INTO product_category_name_translation (
  product_category_name,
  product_category_name_english
)
SELECT
  NULLIF(product_category_name, ''),
  NULLIF(product_category_name_english, '')
FROM product_category_name_translation_stg;

