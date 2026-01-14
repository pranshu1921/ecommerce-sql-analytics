-- ================================================
-- RFM CUSTOMER SEGMENTATION ANALYSIS
-- Business Question: How should we segment customers for targeted marketing?
-- ================================================

/*
Business Context:
- RFM (Recency, Frequency, Monetary) is a proven customer segmentation method
- Helps identify Champions, Loyal Customers, At-Risk, and Lost customers
- Enables targeted marketing campaigns and retention strategies

RFM Scoring:
- Recency: How recently did the customer purchase?
- Frequency: How often do they purchase?
- Monetary: How much do they spend?

Each dimension is scored 1-5, with 5 being best

Techniques Demonstrated:
- NTILE() for percentile-based scoring
- Multiple CTEs for complex logic
- CASE statements for segmentation rules
- Date arithmetic for recency calculations
*/

WITH customer_rfm_metrics AS (
    SELECT 
        c.customer_id,
        c.email,
        c.first_name || ' ' || c.last_name as customer_name,
        c.city,
        c.state,
        
        -- Recency: Days since last purchase
        CURRENT_DATE - MAX(o.order_date)::DATE as days_since_last_order,
        
        -- Frequency: Number of orders
        COUNT(DISTINCT o.order_id) as total_orders,
        
        -- Monetary: Total amount spent
        SUM(o.total_amount) as total_spent,
        
        -- Additional metrics
        AVG(o.total_amount) as avg_order_value,
        MIN(o.order_date)::DATE as first_order_date,
        MAX(o.order_date)::DATE as last_order_date
        
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('cancelled', 'returned')
    GROUP BY c.customer_id, c.email, c.first_name, c.last_name, c.city, c.state
),
rfm_scores AS (
    SELECT 
        *,
        -- RFM Scores (1-5, where 5 is best)
        -- Recency: Lower days = higher score
        5 - NTILE(5) OVER (ORDER BY days_since_last_order) + 1 as r_score,
        
        -- Frequency: More orders = higher score
        NTILE(5) OVER (ORDER BY total_orders) as f_score,
        
        -- Monetary: More spent = higher score
        NTILE(5) OVER (ORDER BY total_spent) as m_score
        
    FROM customer_rfm_metrics
),
customer_segments AS (
    SELECT 
        *,
        -- Combined RFM Score
        (r_score + f_score + m_score) as rfm_total,
        
        -- Segment Assignment
        CASE 
            -- Champions: Bought recently, buy often, and spend the most
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            
            -- Loyal Customers: Buy regularly
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
            
            -- Big Spenders: High monetary value but not frequent
            WHEN m_score >= 4 AND f_score <= 2 THEN 'Big Spenders'
            
            -- Promising: Recent shoppers but low frequency/monetary
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Promising'
            
            -- Needs Attention: Above average recency, frequency, monetary
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 2 THEN 'Needs Attention'
            
            -- At Risk: Once good customers but haven't purchased recently
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            
            -- Hibernating: Low engagement, haven't purchased recently
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
            
            -- Lost: Lowest recency, frequency, and monetary scores
            WHEN r_score = 1 AND f_score = 1 THEN 'Lost'
            
            ELSE 'Others'
        END as segment,
        
        -- Segment Priority for marketing campaigns
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 1 -- Champions
            WHEN r_score >= 3 AND f_score >= 3 THEN 2 -- Loyal
            WHEN r_score <= 2 AND f_score >= 3 THEN 3 -- At Risk (high priority!)
            WHEN r_score >= 4 AND f_score <= 2 THEN 4 -- Promising
            WHEN m_score >= 4 AND f_score <= 2 THEN 5 -- Big Spenders
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 2 THEN 6 -- Needs Attention
            WHEN r_score <= 2 AND f_score <= 2 THEN 7 -- Hibernating
            WHEN r_score = 1 AND f_score = 1 THEN 8 -- Lost
            ELSE 9
        END as priority
        
    FROM rfm_scores
)
SELECT 
    customer_id,
    customer_name,
    email,
    city,
    state,
    segment,
    priority,
    
    -- RFM Scores
    r_score as recency_score,
    f_score as frequency_score,
    m_score as monetary_score,
    rfm_total as combined_score,
    
    -- Actual Metrics
    days_since_last_order,
    total_orders,
    ROUND(total_spent::NUMERIC, 2) as total_spent,
    ROUND(avg_order_value::NUMERIC, 2) as avg_order_value,
    first_order_date,
    last_order_date,
    
    -- Customer Tenure
    CURRENT_DATE - first_order_date as customer_tenure_days,
    
    -- Recommended Actions
    CASE segment
        WHEN 'Champions' THEN 'Reward loyalty, ask for referrals, upsell premium products'
        WHEN 'Loyal Customers' THEN 'Increase engagement, offer loyalty program benefits'
        WHEN 'Big Spenders' THEN 'Market new products, increase purchase frequency'
        WHEN 'Promising' THEN 'Offer onboarding incentives, increase frequency'
        WHEN 'Needs Attention' THEN 'Re-engage with limited-time offers'
        WHEN 'At Risk' THEN 'URGENT: Win-back campaigns, surveys, special offers'
        WHEN 'Hibernating' THEN 'Aggressive win-back campaigns, steep discounts'
        WHEN 'Lost' THEN 'Last-chance offers or remove from active marketing'
        ELSE 'Standard marketing approach'
    END as recommended_action

FROM customer_segments
ORDER BY priority, rfm_total DESC, total_spent DESC;