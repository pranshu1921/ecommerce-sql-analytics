-- ================================================
-- HOUR OF DAY SALES PATTERNS
-- Business Question: When do customers shop most?
-- ================================================

/*
Techniques Demonstrated:
- EXTRACT(HOUR) for time of day
- Hourly aggregations
- Operational optimization insights
*/

SELECT 
    EXTRACT(HOUR FROM order_date) as hour,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(total_amount)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(total_amount)::NUMERIC, 2) as avg_order_value,
    
    -- Time of day classification
    CASE 
        WHEN EXTRACT(HOUR FROM order_date) BETWEEN 6 AND 11 THEN '🌅 Morning (6am-12pm)'
        WHEN EXTRACT(HOUR FROM order_date) BETWEEN 12 AND 17 THEN '☀️ Afternoon (12pm-6pm)'
        WHEN EXTRACT(HOUR FROM order_date) BETWEEN 18 AND 23 THEN '🌙 Evening (6pm-12am)'
        ELSE '🌃 Night (12am-6am)'
    END as time_period

FROM orders
WHERE order_status NOT IN ('cancelled', 'returned')
    AND order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY EXTRACT(HOUR FROM order_date)
ORDER BY hour;