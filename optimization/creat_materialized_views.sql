-- ================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- Pre-computed aggregations for faster queries
-- ================================================

/*
Materialized views store query results physically
Refresh periodically for up-to-date data
Significant performance improvement for complex aggregations
*/

-- Daily Sales Summary
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_sales_summary AS
SELECT 
    order_date::DATE as sale_date,
    COUNT(DISTINCT order_id) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders
WHERE order_status NOT IN ('cancelled', 'returned')
GROUP BY order_date::DATE;

CREATE INDEX idx_mv_daily_sales_date ON mv_daily_sales_summary(sale_date);

-- Product Performance Summary
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT oi.order_id) as total_orders,
    SUM(oi.quantity) as units_sold,
    SUM(oi.line_total) as total_revenue,
    RANK() OVER (ORDER BY SUM(oi.line_total) DESC) as revenue_rank
FROM products p
LEFT JOIN order_items oi ON p.sku = oi.product_sku
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('cancelled', 'returned')
GROUP BY p.product_id, p.product_name, p.category;

CREATE INDEX idx_mv_product_perf_revenue ON mv_product_performance(total_revenue);

-- Customer Summary
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_customer_summary AS
SELECT 
    c.customer_id,
    c.email,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent,
    MAX(o.order_date)::DATE as last_order_date,
    NTILE(5) OVER (ORDER BY SUM(o.total_amount)) as value_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status NOT IN ('cancelled', 'returned')
GROUP BY c.customer_id, c.email;

CREATE INDEX idx_mv_customer_summary_tier ON mv_customer_summary(value_tier);

-- Refresh commands (run periodically)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales_summary;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_product_performance;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_summary;