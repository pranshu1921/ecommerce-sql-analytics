-- ================================================
-- DAY OF WEEK SALES ANALYSIS
-- Business Question: Which days drive the most sales?
-- ================================================

/*
Techniques Demonstrated:
- EXTRACT(DOW) for day of week
- TO_CHAR for day names
- Pattern recognition
- Operational insights
*/

SELECT 
    EXTRACT(DOW FROM order_date) as day_num,
    TO_CHAR(order_date, 'Day') as day_name,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(total_amount)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(total_amount)::NUMERIC, 2) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers,
    
    -- Percentage of weekly revenue
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 2) as pct_of_weekly_revenue,
    
    -- Performance indicator
    CASE 
        WHEN EXTRACT(DOW FROM order_date) IN (0, 6) THEN '🌟 Weekend'
        ELSE '📅 Weekday'
    END as day_type

FROM orders
WHERE order_status NOT IN ('cancelled', 'returned')
    AND order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY 
    EXTRACT(DOW FROM order_date),
    TO_CHAR(order_date, 'Day')
ORDER BY day_num;