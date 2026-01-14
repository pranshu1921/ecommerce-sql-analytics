-- =====================================================
-- DAILY SALES TRENDS WITH MOVING AVERAGES
-- Business Question: What are our day-to-day sales patterns?
-- =====================================================

/*
Techniques Demonstrated:
- Window functions with frames
- Moving averages for trend smoothing
- LAG() for day-over-day comparison
- Generate_series for complete date ranges
*/

WITH daily_sales AS (
    SELECT 
        order_date::DATE as sale_date,
        COUNT(DISTINCT order_id) as orders,
        SUM(total_amount) as revenue,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM orders
    WHERE order_status NOT IN ('cancelled', 'returned')
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY order_date::DATE
)
SELECT 
    sale_date,
    orders,
    ROUND(revenue::NUMERIC, 2) as revenue,
    ROUND(avg_order_value::NUMERIC, 2) as avg_order_value,
    unique_customers,
    
    -- 7-day moving average
    ROUND(AVG(revenue) OVER (
        ORDER BY sale_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )::NUMERIC, 2) as ma_7day_revenue,
    
    -- Day-over-day change
    LAG(revenue) OVER (ORDER BY sale_date) as prev_day_revenue,
    ROUND(((revenue - LAG(revenue) OVER (ORDER BY sale_date)) / 
        NULLIF(LAG(revenue) OVER (ORDER BY sale_date), 0) * 100)::NUMERIC, 2) as dod_change_pct,
    
    -- Day of week
    TO_CHAR(sale_date, 'Day') as day_of_week,
    EXTRACT(DOW FROM sale_date) as day_num
    
FROM daily_sales
ORDER BY sale_date DESC
LIMIT 90;