-- ================================================
-- BUSINESS HEALTH METRICS
-- Business Question: Is our business healthy overall?
-- ================================================

/*
Comprehensive health check across multiple dimensions
*/

SELECT 
    '📊 REVENUE HEALTH' as metric_category,
    ROUND(SUM(total_amount)::NUMERIC, 2) as last_30d_revenue,
    COUNT(DISTINCT order_id) as last_30d_orders
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
    AND order_status NOT IN ('cancelled', 'returned')

UNION ALL

SELECT 
    '👥 CUSTOMER HEALTH' as metric_category,
    COUNT(DISTINCT customer_id)::NUMERIC as active_customers_30d,
    COUNT(DISTINCT CASE WHEN total_orders > 1 THEN customer_id END)::NUMERIC as repeat_customers
FROM customers

UNION ALL

SELECT 
    '📦 INVENTORY HEALTH' as metric_category,
    COUNT(DISTINCT product_id)::NUMERIC as total_products,
    SUM(CASE WHEN stock_quantity > 0 THEN 1 ELSE 0 END)::NUMERIC as products_in_stock
FROM products
WHERE is_active = TRUE;