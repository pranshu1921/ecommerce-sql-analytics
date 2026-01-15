-- ================================================
-- ADDITIONAL PERFORMANCE INDEXES
-- Beyond the basic indexes in schema creation
-- ================================================

/*
These indexes optimize specific query patterns
identified through EXPLAIN ANALYZE
*/

-- Composite index for date range + status queries
CREATE INDEX IF NOT EXISTS idx_orders_date_status_composite 
ON orders(order_date, order_status) 
WHERE order_status NOT IN ('cancelled', 'returned');

-- Partial index for active products
CREATE INDEX IF NOT EXISTS idx_products_active_category 
ON products(category, list_price) 
WHERE is_active = TRUE;

-- Index for customer purchase frequency queries
CREATE INDEX IF NOT EXISTS idx_orders_customer_orderdate 
ON orders(customer_id, order_date DESC);

-- Index for product SKU lookups in order items
CREATE INDEX IF NOT EXISTS idx_order_items_sku 
ON order_items(product_sku);

-- Composite index for revenue calculations
CREATE INDEX IF NOT EXISTS idx_order_items_order_product 
ON order_items(order_id, product_id, line_total);

-- Index for time-based aggregations
CREATE INDEX IF NOT EXISTS idx_orders_date_trunc_month 
ON orders(DATE_TRUNC('month', order_date));