-- ================================================
-- WEEKLY PERFORMANCE REPORT
-- Business Question: How did we perform this week vs last week?
-- ================================================

/*
Week-over-week performance comparison
*/

WITH this_week AS (
    SELECT 
        COUNT(DISTINCT order_id) as orders,
        SUM(total_amount) as revenue,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as customers
    FROM orders
    WHERE order_date >= DATE_TRUNC('week', CURRENT_DATE)
        AND order_status NOT IN ('cancelled', 'returned')
),
last_week AS (
    SELECT 
        COUNT(DISTINCT order_id) as orders,
        SUM(total_amount) as revenue,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as customers
    FROM orders
    WHERE order_date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days'
        AND order_date < DATE_TRUNC('week', CURRENT_DATE)
        AND order_status NOT IN ('cancelled', 'returned')
)
SELECT 
    'This Week' as period,
    tw.orders,
    ROUND(tw.revenue::NUMERIC, 2) as revenue,
    ROUND(tw.avg_order_value::NUMERIC, 2) as avg_order_value,
    tw.customers,
    ROUND(((tw.revenue - lw.revenue) / NULLIF(lw.revenue, 0) * 100)::NUMERIC, 2) as wow_revenue_growth_pct
FROM this_week tw
CROSS JOIN last_week lw

UNION ALL

SELECT 
    'Last Week' as period,
    lw.orders,
    ROUND(lw.revenue::NUMERIC, 2) as revenue,
    ROUND(lw.avg_order_value::NUMERIC, 2) as avg_order_value,
    lw.customers,
    NULL as wow_revenue_growth_pct
FROM last_week lw;