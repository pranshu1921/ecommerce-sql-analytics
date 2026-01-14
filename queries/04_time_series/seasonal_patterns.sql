-- ================================================
-- SEASONAL SALES PATTERN ANALYSIS
-- Business Question: Are there seasonal patterns in our sales?
-- ================================================

/*
Business Context:
- Identify peak and low seasons
- Plan inventory and staffing
- Optimize marketing campaigns by season

Techniques Demonstrated:
- DATE_PART and EXTRACT for time components
- Aggregate functions by time period
- Year-over-year comparisons
- Pattern detection
*/

WITH monthly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) as year,
        EXTRACT(MONTH FROM order_date) as month,
        TO_CHAR(order_date, 'Month') as month_name,
        EXTRACT(QUARTER FROM order_date) as quarter,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value
    FROM orders
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY 
        EXTRACT(YEAR FROM order_date),
        EXTRACT(MONTH FROM order_date),
        TO_CHAR(order_date, 'Month'),
        EXTRACT(QUARTER FROM order_date)
)
SELECT 
    year,
    quarter,
    month,
    month_name,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) as total_revenue,
    ROUND(avg_order_value::NUMERIC, 2) as avg_order_value,
    
    -- Comparison to previous year same month
    LAG(total_revenue, 12) OVER (ORDER BY year, month) as prev_year_same_month,
    ROUND(((total_revenue - LAG(total_revenue, 12) OVER (ORDER BY year, month)) / 
        NULLIF(LAG(total_revenue, 12) OVER (ORDER BY year, month), 0) * 100)::NUMERIC, 2) as yoy_growth_pct,
    
    -- Season indicator
    CASE quarter
        WHEN 1 THEN 'Q1: Winter'
        WHEN 2 THEN 'Q2: Spring'
        WHEN 3 THEN 'Q3: Summer'
        WHEN 4 THEN 'Q4: Fall/Holiday'
    END as season

FROM monthly_sales
ORDER BY year DESC, month DESC;