USE OlistEcommerceDB;
GO

-- =============================================
-- Olist E-commerce Analysis
-- =============================================

-- =============================================
-- 1. Total Orders by Status
-- =============================================

SELECT 
    order_status,
    COUNT(order_id) AS TotalOrders
FROM orders
WHERE order_purchase_timestamp < '2018-09-01'
GROUP BY order_status
ORDER BY TotalOrders DESC;


-- =============================================
-- 2. Orders by State
-- =============================================

SELECT
    c.customer_state,
    COUNT(o.order_id) AS TotalOrders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_purchase_timestamp < '2018-09-01'
GROUP BY c.customer_state
ORDER BY TotalOrders DESC;


-- =============================================
-- 3. Top Product Categories by Sales
-- =============================================

SELECT TOP 10 
    COALESCE(
             t.product_category_name_english,
             p.product_category_name
    ) AS ProductCategory,
  CAST( ROUND(  SUM (oi.price) ,2) AS DECIMAL(10,2))AS TotalSales
FROM order_items oi

JOIN products p
ON oi.product_id=p.product_id

LEFT JOIN product_category_name_translation t
ON p.product_category_name=t.product_category_name

JOIN orders o
ON oi.order_id=o.order_id

WHERE o.order_purchase_timestamp < '2018-09-01'

GROUP BY  
     COALESCE(
              t.product_category_name_english,
              p.product_category_name
     )
ORDER BY TotalSales DESC;


-- =============================================
-- 4. Delivery Performance
-- =============================================

WITH DeliveryClassification AS 
( 
 SELECT 
     order_id,
     CASE 
        WHEN 
           CAST(order_delivered_customer_date AS date)
           <= CAST(order_estimated_delivery_date AS date)
        THEN 'ON-TIME'

         WHEN 
           CAST(order_delivered_customer_date AS date)
           > CAST(order_estimated_delivery_date AS date)
        THEN 'LATE'

        ELSE 'UNKNOWN'
    END AS DeliveryStatus
FROM orders
WHERE order_purchase_timestamp < '2018-09-01'
)
SELECT 
    DeliveryStatus,
    COUNT(*) AS TotalOrders
FROM DeliveryClassification
WHERE DeliveryStatus <> 'UNKNOWN'
GROUP BY DeliveryStatus
ORDER BY TotalOrders DESC;


-- =============================================
-- 5. Repeat Customer Rate
-- =============================================

WITH CustomerOrders AS
(
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS TotalOrders
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp < '2018-09-01'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS TotalCustomers,

    SUM(
        CASE
            WHEN TotalOrders > 1 THEN 1
            ELSE 0
        END
    ) AS RepeatCustomers,

CAST(
    ROUND(
        100.0 *
        SUM(CASE WHEN TotalOrders > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    )
    AS DECIMAL(5,2)
) AS RepeatCustomerRate

FROM CustomerOrders;


-- =============================================
-- 6. Repeat Customer Rate by State+500
-- =============================================

WITH CustomerOrdersByState AS
(
    SELECT
        c.customer_unique_id,
        c.customer_state,
        COUNT(o.order_id) AS TotalOrders
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp < '2018-09-01'
    GROUP BY
        c.customer_unique_id,
        c.customer_state
)

SELECT
    customer_state,

    COUNT(*) AS TotalCustomers,

    SUM(
        CASE
            WHEN TotalOrders > 1 THEN 1
            ELSE 0
        END
    ) AS RepeatCustomers,

    CAST(
        ROUND(
            100.0 *
            SUM(CASE WHEN TotalOrders > 1 THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        )
        AS DECIMAL(5,2)
    ) AS RepeatCustomerRate

FROM CustomerOrdersByState

GROUP BY customer_state

HAVING COUNT(*) >= 500

ORDER BY RepeatCustomerRate DESC;


-- =============================================
-- 7. Product Category Sales Ranking
-- =============================================

WITH CategorySales AS
(
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        ) AS ProductCategory,

        SUM(oi.price) AS TotalSales

    FROM order_items oi

    JOIN products p
        ON oi.product_id = p.product_id

    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_purchase_timestamp < '2018-09-01'

    GROUP BY
        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        )
)

SELECT
    ProductCategory,
    TotalSales,

    RANK() OVER(
        ORDER BY TotalSales DESC
    ) AS SalesRank

FROM CategorySales

ORDER BY SalesRank;


-- =============================================
-- 8. AVG Review Score by Delivery Status
-- =============================================

WITH ReviewDelivery AS 
(  
  SELECT 
      r.review_score,
      CASE
            WHEN CAST(o.order_delivered_customer_date AS date)
                 <= CAST(o.order_estimated_delivery_date AS date)
                 THEN 'ON-TIME'
            WHEN CAST(o.order_delivered_customer_date AS date)
                 > CAST(o.order_estimated_delivery_date AS date)
                 THEN 'LATE'
            ELSE 'UNKNOWN'
      END AS DeliveryStatus
  FROM orders o 
  JOIN reviews r
     ON o.order_id=r.order_id
  WHERE order_purchase_timestamp < '2018-09-01'
)

SELECT 
   DeliveryStatus,
   CAST(AVG(CAST(review_score AS decimal(10,2))) AS DECIMAL(10,2))AS AverageReviewScore
FROM ReviewDelivery
WHERE DeliveryStatus <> 'UNKNOWN'
GROUP BY DeliveryStatus
ORDER BY AverageReviewScore DESC;
       
     

      