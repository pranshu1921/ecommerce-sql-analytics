-- ================================================
-- CUSTOMER LIFETIME VALUE (CLV) ANALYSIS
-- Business Question: What is the long-term value of our customers?
-- ================================================

/*
Business Context:
- Calculate predicted customer value over their lifetime
- Identify high-value customers for VIP programs
- Optimize customer acquisition cost (CAC) decisions
- Guide retention strategy investments

CLV Components:
- Historical purchase value
- Purchase frequency
- Customer tenure
- Predicted future value

Techniques Demonstrated:
- Date arithmetic for customer age
- Running totals with window functions
- Percentile calculations with NTILE
- Complex business metric formulas
*/

WITH customer_purchase_history AS (
    SELECT 
        c.customer_id,
        c.email,
        c.first_name || ' ' || c.last_name as customer_name,
        c.city,
        c.state,
        c.registration_date::DATE as registration_date,
        
        -- Purchase metrics
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(o.total_amount) as total_spent,
        AVG(o.total_amount) as avg_order_value,
        MIN(o.order_date)::DATE as first_purchase_date,
        MAX(o.order_date)::DATE as last_purchase_date,
        
        -- Time-based metrics
        CURRENT_DATE - MIN(o.order_date)::DATE as customer_age_days,
        CURRENT_DATE - MAX(o.order_date)::DATE as days_since_last_purchase,
        
        -- Purchase frequency (orders per month)
        COUNT(DISTINCT o.order_id)::NUMERIC / 
            GREATEST(EXTRACT(MONTH FROM AGE(CURRENT_DATE, MIN(o.order_date)::DATE)), 1) as orders_per_month
        
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
        AND o.order_status NOT IN ('cancelled', 'returned')
    GROUP BY c.customer_id, c.email, c.first_name, c.last_name, 
             c.city, c.state, c.registration_date
),
clv_calculations AS (
    SELECT 
        *,
        -- Simple CLV calculation: AOV * Purchase Frequency * Customer Lifespan (in years)
        -- Assuming 3-year customer lifespan
        ROUND((avg_order_value * orders_per_month * 36)::NUMERIC, 2) as predicted_clv_3yr,
        
        -- Historical CLV (actual to date)
        total_spent as historical_clv,
        
        -- Value tier based on historical spending
        NTILE(5) OVER (ORDER BY total_spent) as value_tier,
        
        -- Engagement score (0-100)
        LEAST(100, ROUND((total_orders * 10 + 
                         CASE WHEN days_since_last_purchase < 30 THEN 20 
                              WHEN days_since_last_purchase < 90 THEN 10 
                              ELSE 0 END)::NUMERIC, 0)) as engagement_score
        
    FROM customer_purchase_history
    WHERE total_orders > 0
)
SELECT 
    customer_id,
    customer_name,
    email,
    city,
    state,
    
    -- Purchase behavior
    total_orders,
    ROUND(total_spent::NUMERIC, 2) as historical_clv,
    ROUND(avg_order_value::NUMERIC, 2) as avg_order_value,
    ROUND(orders_per_month::NUMERIC, 2) as orders_per_month,
    
    -- Customer timeline
    registration_date,
    first_purchase_date,
    last_purchase_date,
    customer_age_days,
    days_since_last_purchase,
    
    -- Value metrics
    predicted_clv_3yr,
    value_tier,
    engagement_score,
    
    -- Value classification
    CASE value_tier
        WHEN 5 THEN '💎 VIP (Top 20%)'
        WHEN 4 THEN '🥇 High Value'
        WHEN 3 THEN '🥈 Medium Value'
        WHEN 2 THEN '🥉 Low Value'
        ELSE '👤 New/Occasional'
    END as customer_tier,
    
    -- Engagement status
    CASE 
        WHEN days_since_last_purchase <= 30 THEN '🟢 Active'
        WHEN days_since_last_purchase <= 90 THEN '🟡 Warming'
        WHEN days_since_last_purchase <= 180 THEN '🟠 Cooling'
        ELSE '🔴 At Risk'
    END as engagement_status,
    
    -- Recommended actions
    CASE 
        WHEN value_tier = 5 AND days_since_last_purchase > 90 
            THEN 'URGENT: Re-engage VIP customer'
        WHEN value_tier >= 4 AND days_since_last_purchase <= 30 
            THEN 'Offer loyalty rewards'
        WHEN value_tier = 5 
            THEN 'Maintain VIP perks'
        WHEN orders_per_month > 2 
            THEN 'Upsell opportunity'
        WHEN days_since_last_purchase > 180 
            THEN 'Win-back campaign'
        ELSE 'Standard nurturing'
    END as recommended_action

FROM clv_calculations
ORDER BY predicted_clv_3yr DESC, total_spent DESC
LIMIT 100;