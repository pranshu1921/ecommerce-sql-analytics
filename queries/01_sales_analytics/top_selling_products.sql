-- ================================================
-- TOP SELLING PRODUCTS ANALYSIS
-- Business Question: What are our best-selling products?
-- ================================================

/*
Business Context:
- Identify products that drive sales volume
- Optimize inventory for popular items
- Support merchandising and promotion decisions

Techniques Demonstrated:
- RANK() and DENSE_RANK() for different ranking needs
- Complex aggregate calculations
- FILTER clause for conditional aggregation
- Multiple sorting dimensions
*/

WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        p.list_price,
        p.stock_quantity,
        
        -- Sales metrics
        COUNT(DISTINCT oi.order_id) as order_count,
        SUM(oi.quantity) as units_sold,
        SUM(oi.line_total) as total_revenue,
        AVG(oi.unit_price) as avg_selling_price,
        
        -- Profit metrics
        SUM(oi.line_total - (oi.cost_price * oi.quantity)) as total_profit,
        
        -- Customer reach
        COUNT(DISTINCT o.customer_id) as unique_customers,
        
        -- Time-based metrics
        MIN(o.order_date)::DATE as first_sale_date,
        MAX(o.order_date)::DATE as last_sale_date
        
    FROM products p
    LEFT JOIN order_items oi ON p.sku = oi.product_sku
    LEFT JOIN orders o ON oi.order_id = o.order_id
        AND o.order_status NOT IN ('cancelled', 'returned')
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY 
        p.product_id, p.product_name, p.category, p.subcategory, 
        p.brand, p.list_price, p.stock_quantity
)
SELECT 
    RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank,
    RANK() OVER (ORDER BY units_sold DESC) as units_rank,
    product_name,
    category,
    brand,
    
    -- Sales performance
    order_count,
    units_sold,
    ROUND(total_revenue::NUMERIC, 2) as total_revenue,
    ROUND(avg_selling_price::NUMERIC, 2) as avg_selling_price,
    
    -- Profitability
    ROUND(total_profit::NUMERIC, 2) as total_profit,
    ROUND((total_profit / NULLIF(total_revenue, 0) * 100)::NUMERIC, 2) as profit_margin_pct,
    
    -- Customer metrics
    unique_customers,
    ROUND(total_revenue / NULLIF(unique_customers, 0)::NUMERIC, 2) as revenue_per_customer,
    
    -- Inventory
    stock_quantity,
    CASE 
        WHEN stock_quantity = 0 THEN '🔴 Out of Stock'
        WHEN stock_quantity < 20 THEN '⚠️ Low Stock'
        ELSE '✅ In Stock'
    END as stock_status,
    
    -- Performance indicators
    CASE 
        WHEN RANK() OVER (ORDER BY total_revenue DESC) <= 10 THEN '⭐ Top 10'
        WHEN RANK() OVER (ORDER BY total_revenue DESC) <= 50 THEN '🔥 Top 50'
        WHEN RANK() OVER (ORDER BY total_revenue DESC) <= 100 THEN '✅ Top 100'
        ELSE '➡️ Standard'
    END as performance_tier,
    
    -- Dates
    first_sale_date,
    last_sale_date,
    CURRENT_DATE - last_sale_date as days_since_last_sale

FROM product_sales
WHERE total_revenue > 0
ORDER BY total_revenue DESC
LIMIT 50;

-- ================================================
-- INSIGHTS TO LOOK FOR:
-- ================================================
-- 1. Are top revenue products also top sellers by units?
-- 2. Which popular products are running low on stock?
-- 3. What's the profit margin on best-sellers?
-- 4. Are there seasonal patterns in top products?
-- ================================================