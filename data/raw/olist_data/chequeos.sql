#Chequeos

USE ecommerce_olist;


SELECT review_score, COUNT(*) AS cantidad
FROM order_reviews_raw
GROUP BY review_score
ORDER BY review_score;

SELECT review_id, COUNT(*) AS cnt
FROM order_reviews_raw
GROUP BY review_id
HAVING cnt > 1
LIMIT 20;


SELECT review_id, review_creation_date, review_answer_timestamp
FROM order_reviews_raw
WHERE review_creation_date = 'f63f9a7699e3674c80a4ba92e56dfbb8'
   OR review_answer_timestamp = 'f63f9a7699e3674c80a4ba92e56dfbb8';

SELECT COUNT(*) AS cant_invalidas
FROM order_reviews_raw
WHERE
    (review_creation_date <> ''
     AND STR_TO_DATE(review_creation_date, '%Y-%m-%d %H:%i:%s') IS NULL)
    OR
    (review_answer_timestamp <> ''
     AND STR_TO_DATE(review_answer_timestamp, '%Y-%m-%d %H:%i:%s') IS NULL);
     
#es solo 1 con este problema, la elimino en el server_making


SELECT COUNT(*) AS orphan_reviews
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
#esto devuelve un null en o.order_id si no matchea con nada
#como da 0, uso FK

SELECT COUNT(*) AS invalid_reviews
FROM order_reviews r
WHERE r.review_score is NULL;
#0

SELECT order_status
FROM orders
WHERE order_status != 'delivered'
LIMIT 10;

SELECT order_status, review_score
FROM orders as o
LEFT JOIN order_reviews as ore ON o.order_id = ore.order_id
WHERE order_status != 'delivered'
LIMIT 10;
#Hay reviews de items que todavia no fueron entregados... 
#cuando es canceled se entiende. si no, no tengo idea

SELECT COUNT(*)
FROM orders
WHERE order_status != 'delivered';
#son 2963. that's roughly 3%. ignorable.


#veamos si algun cliente hizo más de un review de la misma orden
SELECT COUNT(*) AS cant_pedidos_con_multiples_reviews
FROM (
    SELECT order_id
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS t;

#243. bajisimo el numero. usamos el avg de cada orden entonces para armar el feature.






SELECT 
    (SELECT COUNT(*) FROM orders) AS total_compras,
    COUNT(r.review_id) AS compras_con_rating,
    (SELECT COUNT(*) FROM orders) - COUNT(r.review_id) AS compras_SIN_rating,
    ROUND((COUNT(r.review_id) / (SELECT COUNT(*) FROM orders)) * 100, 2) AS porcentaje_cobertura
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id;

SELECT 
    compras_por_usuario,
    COUNT(*) AS cantidad_de_usuarios
FROM (
    SELECT 
        o.customer_id, 
        COUNT(o.order_id) AS compras_por_usuario,
        COUNT(r.review_id) AS ratings_por_usuario
    FROM orders o
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    GROUP BY o.customer_id
) AS perfil_usuario
GROUP BY compras_por_usuario
ORDER BY compras_por_usuario DESC;

-- ¿Qué productos se compran juntos en la misma orden?
SELECT 
    a.product_id AS prod_A, 
    b.product_id AS prod_B, 
    COUNT(*) AS veces_juntos
FROM order_items a
JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
GROUP BY prod_A, prod_B
ORDER BY veces_juntos DESC
LIMIT 10;



-- -----------------segundi intento----------
SELECT COUNT(DISTINCT product_id) AS total_productos_vendidos
FROM order_items;







