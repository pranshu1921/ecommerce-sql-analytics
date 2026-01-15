-- ================================================
-- EXECUTIVE KPI DASHBOARD
-- Business Question: What are our key business metrics at a glance?
-- ================================================

/*
Business Context:
- Executive summary of business health
- Key Performance Indicators (KPIs) for decision-making
- Comparison with previous periods
- Red flags and opportunities highlighted

Key Metrics:
- Revenue and growth
- Customer acquisition and retention
- Average order value
- Conversion metrics
- Profitability

Techniques Demonstrated:
- Multiple CTEs for modular logic
- Period-over-period comparisons
- GROUPING SETS for multi-level aggregation
- Complex business calculations
- Performance indicators
*/

WITH current_period AS (
    -- Last 30 days metrics
    SELECT 
        'Last 30 Days' as period,
        COUNT(DISTINCT order_id) as total_orders,
        COUNT(DISTINCT customer_id) as active_customers,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        SUM(total_amount) / NULLIF(COUNT(DISTINCT customer_id), 0) as revenue_per_customer
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
        AND order_status NOT IN ('cancelled', 'returned')
),
previous_period AS (
    -- Previous 30 days for comparison
    SELECT 
        'Previous 30 Days' as period,
        COUNT(DISTINCT order_id) as total_orders,
        COUNT(DISTINCT customer_id) as active_customers,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        SUM(total_amount) / NULLIF(COUNT(DISTINCT customer_id), 0) as revenue_per_customer
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '60 days'
        AND order_date < CURRENT_DATE - INTERVAL '30 days'
        AND order_status NOT IN ('cancelled', 'returned')
),
customer_metrics AS (
    SELECT 
        -- New customers (first order in last 30 days)
        COUNT(DISTINCT CASE 
            WHEN first_purchase_date >= CURRENT_DATE - INTERVAL '30 days' 
            THEN customer_id 
        END) as new_customers,
        
        -- Repeat customers (more than one order)
        COUNT(DISTINCT CASE 
            WHEN total_orders > 1 
            THEN customer_id 
        END) as repeat_customers,
        
        COUNT(DISTINCT customer_id) as total_customers
    FROM customers
),
product_metrics AS (
    SELECT 
        COUNT(DISTINCT p.product_id) as total_products,
        COUNT(DISTINCT CASE WHEN p.is_active = TRUE THEN p.product_id END) as active_products,
        COUNT(DISTINCT CASE WHEN p.stock_quantity = 0 THEN p.product_id END) as out_of_stock_products,
        SUM(p.stock_quantity * p.cost_price) as inventory_value
    FROM products p
)
SELECT 
    -- ========================
    -- REVENUE METRICS
    -- ========================
    ROUND(cp.total_revenue::NUMERIC, 2) as revenue_current_30d,
    ROUND(pp.total_revenue::NUMERIC, 2) as revenue_previous_30d,
    ROUND(((cp.total_revenue - pp.total_revenue) / NULLIF(pp.total_revenue, 0) * 100)::NUMERIC, 2) as revenue_growth_pct,
    
    -- ========================
    -- ORDER METRICS
    -- ========================
    cp.total_orders as orders_current_30d,
    pp.total_orders as orders_previous_30d,
    ROUND(((cp.total_orders - pp.total_orders) / NULLIF(pp.total_orders::NUMERIC, 0) * 100)::NUMERIC, 2) as order_growth_pct,
    
    ROUND(cp.avg_order_value::NUMERIC, 2) as avg_order_value_current,
    ROUND(pp.avg_order_value::NUMERIC, 2) as avg_order_value_previous,
    
    -- ========================
    -- CUSTOMER METRICS
    -- ========================
    cp.active_customers as active_customers_30d,
    cm.new_customers as new_customers_30d,
    cm.repeat_customers as repeat_customers_total,
    ROUND((cm.repeat_customers::NUMERIC / NULLIF(cm.total_customers, 0) * 100), 2) as repeat_customer_rate_pct,
    
    ROUND(cp.revenue_per_customer::NUMERIC, 2) as revenue_per_customer,
    
    -- ========================
    -- PRODUCT METRICS
    -- ========================
    pm.total_products,
    pm.active_products,
    pm.out_of_stock_products,
    ROUND(pm.inventory_value::NUMERIC, 2) as inventory_value,
    
    -- ========================
    -- PERFORMANCE INDICATORS
    -- ========================
    CASE 
        WHEN ((cp.total_revenue - pp.total_revenue) / NULLIF(pp.total_revenue, 0) * 100) > 10 
        THEN '🟢 Strong Growth'
        WHEN ((cp.total_revenue - pp.total_revenue) / NULLIF(pp.total_revenue, 0) * 100) > 0 
        THEN '🟡 Modest Growth'
        WHEN ((cp.total_revenue - pp.total_revenue) / NULLIF(pp.total_revenue, 0) * 100) < -10 
        THEN '🔴 Declining'
        ELSE '⚪ Flat'
    END as revenue_trend,
    
    CASE 
        WHEN (cm.repeat_customers::NUMERIC / NULLIF(cm.total_customers, 0) * 100) > 30 
        THEN '🟢 Healthy'
        WHEN (cm.repeat_customers::NUMERIC / NULLIF(cm.total_customers, 0) * 100) > 15 
        THEN '🟡 Fair'
        ELSE '🔴 Needs Work'
    END as retention_health,
    
    -- ========================
    -- KEY ALERTS
    -- ========================
    CASE 
        WHEN pm.out_of_stock_products > pm.active_products * 0.1 
        THEN '⚠️ High out-of-stock rate'
        ELSE '✅ Inventory healthy'
    END as inventory_alert

FROM current_period cp
CROSS JOIN previous_period pp
CROSS JOIN customer_metrics cm
CROSS JOIN product_metrics pm;