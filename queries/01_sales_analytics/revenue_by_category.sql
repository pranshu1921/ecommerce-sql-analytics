-- ================================================
-- REVENUE BY CATEGORY WITH RANKINGS
-- Business Question: Which product categories generate the most revenue?
-- ================================================

/*
Business Context:
- Identify high-performing and underperforming categories
- Support inventory and marketing budget allocation
- Track category trends over time

Techniques Demonstrated:
- Aggregate functions with GROUP BY
- RANK() window function
- Percentage calculations
- Multi-level sorting
*/

WITH category_metrics AS (
    SELECT 
        p.category,
        COUNT(DISTINCT oi.order_id) as total_orders,
        SUM(oi.quantity) as total_units_sold,
        SUM(oi.line_total) as total_revenue,
        SUM(oi.line_total - (oi.cost_price * oi.quantity)) as total_profit,
        AVG(oi.unit_price) as avg_unit_price,
        COUNT(DISTINCT p.product_id) as product_count,
        COUNT(DISTINCT o.customer_id) as unique_customers
    FROM products p
    JOIN order_items oi ON p.sku = oi.product_sku
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('cancelled', 'returned')
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY p.category
),
category_rankings AS (
    SELECT 
        *,
        -- Rankings
        RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank,
        RANK() OVER (ORDER BY total_profit DESC) as profit_rank,
        
        -- Percentages
        ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2) as revenue_pct,
        ROUND(100.0 * total_profit / NULLIF(total_revenue, 0), 2) as profit_margin_pct,
        
        -- Per-product metrics
        ROUND(total_revenue / NULLIF(product_count, 0), 2) as revenue_per_product,
        ROUND(total_units_sold::NUMERIC / NULLIF(product_count, 0), 2) as units_per_product
        
    FROM category_metrics
)
SELECT 
    category,
    revenue_rank,
    ROUND(total_revenue::NUMERIC, 2) as total_revenue,
    revenue_pct as pct_of_total_revenue,
    total_orders,
    total_units_sold,
    unique_customers,
    product_count,
    ROUND(profit_margin_pct::NUMERIC, 2) as profit_margin_pct,
    ROUND(revenue_per_product::NUMERIC, 2) as revenue_per_product,
    
    -- Performance indicator
    CASE 
        WHEN revenue_rank <= 2 THEN '🥇 Top Performer'
        WHEN revenue_rank <= 5 THEN '✅ Strong'
        WHEN profit_margin_pct < 15 THEN '⚠️ Low Margin'
        ELSE '➡️ Average'
    END as performance_status

FROM category_rankings
ORDER BY total_revenue DESC;

-- ================================================
-- INSIGHTS TO LOOK FOR:
-- ================================================
-- 1. Which categories drive 80% of revenue (Pareto principle)?
-- 2. Are high-revenue categories also profitable?
-- 3. Which categories have the most products but low revenue?
-- 4. What's the average profit margin by category?
-- ================================================