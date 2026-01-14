-- ================================================
-- TREND FORECASTING PREPARATION
-- Business Question: What data do we need for forecasting?
-- ================================================

/*
Prepares clean time-series data for forecasting models
Includes: dates, revenue, moving averages, trends
*/

WITH daily_metrics AS (
    SELECT 
        order_date::DATE as date,
        COUNT(DISTINCT order_id) as orders,
        SUM(total_amount) as revenue,
        AVG(total_amount) as avg_order_value
    FROM orders
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY order_date::DATE
)
SELECT 
    date,
    orders,
    ROUND(revenue::NUMERIC, 2) as revenue,
    ROUND(avg_order_value::NUMERIC, 2) as avg_order_value,
    
    -- 7-day moving average
    ROUND(AVG(revenue) OVER (
        ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )::NUMERIC, 2) as ma_7day,
    
    -- 30-day moving average
    ROUND(AVG(revenue) OVER (
        ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    )::NUMERIC, 2) as ma_30day,
    
    -- Week number and month for seasonality
    EXTRACT(WEEK FROM date) as week_of_year,
    EXTRACT(MONTH FROM date) as month,
    EXTRACT(DOW FROM date) as day_of_week

FROM daily_metrics
ORDER BY date DESC;