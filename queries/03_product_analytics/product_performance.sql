-- ================================================
-- PRODUCT PERFORMANCE ANALYSIS
-- Business Question: Which products are driving revenue and profitability?
-- ================================================

/*
Business Context:
- Identify best and worst performing products
- Calculate profit margins and inventory turnover
- Support pricing and inventory decisions
- Highlight products needing attention

Key Metrics:
- Revenue, Units Sold, Average Price
- Profit Margin %
- Revenue Rank
- Inventory Turnover Ratio

Techniques Demonstrated:
- Complex JOINs across multiple tables
- RANK() and DENSE_RANK() window functions
- Profit calculations
- Aggregate functions with FILTER
- Business metric formulas
*/

WITH product_sales AS (
    SELECT 
        p.product_id,
        p.sku,
        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        p.list_price,
        p.cost_price,
        p.stock_quantity,
        
        -- Sales metrics (last 90 days)
        COUNT(DISTINCT oi.order_id) FILTER (
            WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
        ) as orders_90d,
        
        SUM(oi.quantity) FILTER (
            WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
        ) as units_sold_90d,
        
        SUM(oi.line_total) FILTER (
            WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
        ) as revenue_90d,
        
        SUM(oi.line_total - (oi.cost_price * oi.quantity)) FILTER (
            WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
        ) as profit_90d,
        
        AVG(oi.unit_price) FILTER (
            WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
        ) as avg_selling_price_90d,
        
        -- All-time metrics
        COUNT(DISTINCT oi.order_id) as orders_all_time,
        SUM(oi.quantity) as units_sold_all_time,
        SUM(oi.line_total) as revenue_all_time
        
    FROM products p
    LEFT JOIN order_items oi ON p.sku = oi.product_sku
    LEFT JOIN orders o ON oi.order_id = o.order_id 
        AND o.order_status NOT IN ('cancelled', 'returned')
    GROUP BY 
        p.product_id, p.sku, p.product_name, p.category, 
        p.subcategory, p.brand, p.list_price, p.cost_price, p.stock_quantity
),
product_metrics AS (
    SELECT 
        *,
        -- Profit margin calculation
        CASE 
            WHEN revenue_90d > 0 THEN (profit_90d / revenue_90d * 100)
            ELSE NULL
        END as profit_margin_pct,
        
        -- Inventory turnover (simplified)
        CASE 
            WHEN stock_quantity > 0 THEN (units_sold_90d / stock_quantity)
            ELSE NULL
        END as inventory_turnover_ratio,
        
        -- Performance rankings
        RANK() OVER (ORDER BY revenue_90d DESC NULLS LAST) as revenue_rank,
        RANK() OVER (PARTITION BY category ORDER BY revenue_90d DESC NULLS LAST) as category_rank,
        
        -- Sales velocity (units per day)
        ROUND(units_sold_90d / 90.0, 2) as units_per_day
        
    FROM product_sales
)
SELECT 
    product_name,
    category,
    subcategory,
    brand,
    
    -- Pricing
    ROUND(list_price::NUMERIC, 2) as list_price,
    ROUND(avg_selling_price_90d::NUMERIC, 2) as avg_price_last_90d,
    ROUND(cost_price::NUMERIC, 2) as cost_price,
    
    -- Sales performance
    COALESCE(orders_90d, 0) as orders_last_90d,
    COALESCE(units_sold_90d, 0) as units_sold_last_90d,
    ROUND(COALESCE(revenue_90d, 0)::NUMERIC, 2) as revenue_last_90d,
    ROUND(COALESCE(profit_90d, 0)::NUMERIC, 2) as profit_last_90d,
    
    -- Margins and ratios
    ROUND(COALESCE(profit_margin_pct, 0)::NUMERIC, 2) as profit_margin_pct,
    ROUND(COALESCE(inventory_turnover_ratio, 0)::NUMERIC, 2) as inventory_turnover,
    units_per_day,
    
    -- Inventory
    stock_quantity as current_stock,
    
    -- Rankings
    revenue_rank as overall_rank,
    category_rank,
    
    -- Performance indicator
    CASE 
        WHEN revenue_rank <= 20 THEN '⭐ Top Performer'
        WHEN revenue_rank <= 100 THEN '✅ Good'
        WHEN profit_margin_pct < 10 THEN '⚠️ Low Margin'
        WHEN units_sold_90d = 0 THEN '🔴 No Sales'
        WHEN inventory_turnover_ratio < 0.5 THEN '📦 Slow Moving'
        ELSE '➡️ Average'
    END as performance_status,
    
    -- Recommendation
    CASE 
        WHEN units_sold_90d = 0 AND stock_quantity > 0 THEN 'Discount to clear inventory'
        WHEN inventory_turnover_ratio > 3 THEN 'Increase stock levels'
        WHEN profit_margin_pct < 10 THEN 'Review pricing strategy'
        WHEN revenue_rank <= 20 THEN 'Maintain stock, consider upselling'
        ELSE 'Standard management'
    END as recommendation

FROM product_metrics
WHERE revenue_90d > 0 OR stock_quantity > 0
ORDER BY revenue_90d DESC NULLS LAST
LIMIT 100;