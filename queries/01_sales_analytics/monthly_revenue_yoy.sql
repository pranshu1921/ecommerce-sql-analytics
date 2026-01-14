-- ================================================
-- MONTHLY REVENUE WITH YEAR-OVER-YEAR COMPARISON
-- Business Question: How is our monthly revenue trending compared to last year?
-- ================================================

/*
Business Context:
- Executives need to understand revenue growth patterns
- Identifies seasonal trends and growth opportunities
- Helps with forecasting and budgeting

Key Metrics:
- Monthly revenue
- Year-over-year growth percentage
- Month-over-month growth
- Cumulative revenue for the year

Techniques Demonstrated:
- DATE_TRUNC for time-series grouping
- LAG() window function for period comparisons
- CASE statements for conditional logic
- CTEs for query organization
*/

WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', order_date)::DATE as month_date,
        EXTRACT(YEAR FROM order_date) as year,
        EXTRACT(MONTH FROM order_date) as month,
        TO_CHAR(order_date, 'Month') as month_name,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM orders
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY 
        DATE_TRUNC('month', order_date),
        EXTRACT(YEAR FROM order_date),
        EXTRACT(MONTH FROM order_date),
        TO_CHAR(order_date, 'Month')
),
revenue_with_comparisons AS (
    SELECT 
        month_date,
        year,
        month,
        month_name,
        total_orders,
        total_revenue,
        avg_order_value,
        unique_customers,
        -- Previous month comparison
        LAG(total_revenue, 1) OVER (ORDER BY month_date) as prev_month_revenue,
        -- Same month last year comparison
        LAG(total_revenue, 12) OVER (ORDER BY month_date) as prev_year_revenue,
        -- Running total for year
        SUM(total_revenue) OVER (
            PARTITION BY year 
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as ytd_revenue
    FROM monthly_revenue
)
SELECT 
    month_date,
    year,
    month_name,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) as total_revenue,
    ROUND(avg_order_value::NUMERIC, 2) as avg_order_value,
    unique_customers,
    
    -- Month-over-Month Growth
    CASE 
        WHEN prev_month_revenue IS NOT NULL AND prev_month_revenue > 0 THEN
            ROUND(((total_revenue - prev_month_revenue) / prev_month_revenue * 100)::NUMERIC, 2)
        ELSE NULL
    END as mom_growth_pct,
    
    -- Year-over-Year Growth
    CASE 
        WHEN prev_year_revenue IS NOT NULL AND prev_year_revenue > 0 THEN
            ROUND(((total_revenue - prev_year_revenue) / prev_year_revenue * 100)::NUMERIC, 2)
        ELSE NULL
    END as yoy_growth_pct,
    
    -- Year-to-Date Revenue
    ROUND(ytd_revenue::NUMERIC, 2) as ytd_revenue,
    
    -- Performance indicators
    CASE 
        WHEN prev_year_revenue IS NOT NULL AND total_revenue > prev_year_revenue THEN '📈 Growing'
        WHEN prev_year_revenue IS NOT NULL AND total_revenue < prev_year_revenue THEN '📉 Declining'
        WHEN prev_year_revenue IS NOT NULL THEN '➡️ Flat'
        ELSE '🆕 New Period'
    END as performance_indicator

FROM revenue_with_comparisons
ORDER BY month_date DESC
LIMIT 24; -- Last 24 months

-- ================================================
-- INSIGHTS TO LOOK FOR:
-- ================================================
-- 1. Seasonal patterns (Q4 typically higher for retail)
-- 2. Consistent YoY growth (healthy business)
-- 3. Declining trends (needs investigation)
-- 4. Average order value trends (pricing strategy impact)
-- ================================================