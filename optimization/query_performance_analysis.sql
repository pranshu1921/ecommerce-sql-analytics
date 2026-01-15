-- ================================================
-- QUERY PERFORMANCE ANALYSIS
-- Demonstrates optimization techniques
-- ================================================

/*
This file shows EXPLAIN ANALYZE examples for key queries
Use these to benchmark and optimize performance
*/

-- Example 1: Monthly Revenue Query Performance
EXPLAIN ANALYZE
SELECT 
    DATE_TRUNC('month', order_date)::DATE as month_date,
    COUNT(DISTINCT order_id) as total_orders,
    SUM(total_amount) as total_revenue
FROM orders
WHERE order_status NOT IN ('cancelled', 'returned')
    AND order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month_date DESC;

-- Example 2: Customer Segmentation Performance
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status NOT IN ('cancelled', 'returned')
GROUP BY c.customer_id
LIMIT 1000;

-- Example 3: Product Performance Query
EXPLAIN ANALYZE
SELECT 
    p.product_name,
    p.category,
    SUM(oi.line_total) as total_revenue
FROM products p
JOIN order_items oi ON p.sku = oi.product_sku
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
    AND o.order_status NOT IN ('cancelled', 'returned')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 50;