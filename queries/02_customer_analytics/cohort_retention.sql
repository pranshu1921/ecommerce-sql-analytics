-- ================================================
-- COHORT RETENTION ANALYSIS
-- Business Question: What is our customer retention rate by cohort?
-- ================================================

/*
Business Context:
- Cohort analysis tracks groups of customers over time
- Shows how many customers return to make repeat purchases
- Critical for understanding customer lifetime value
- Helps evaluate marketing and product effectiveness

Techniques Demonstrated:
- Multiple CTEs for complex logic
- DATE_TRUNC for cohort grouping
- Self-joins for cohort analysis
- Percentage calculations
- CASE statements for time periods
*/

WITH customer_cohorts AS (
    -- Identify each customer's first purchase month (their cohort)
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::DATE as cohort_month
    FROM orders
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY customer_id
),
customer_orders AS (
    -- Get all orders with cohort information
    SELECT 
        o.customer_id,
        c.cohort_month,
        DATE_TRUNC('month', o.order_date)::DATE as order_month,
        EXTRACT(MONTH FROM AGE(o.order_date, c.cohort_month)) as months_since_cohort
    FROM orders o
    JOIN customer_cohorts c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('cancelled', 'returned')
),
cohort_size AS (
    -- Count customers in each cohort
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_customers
    FROM customer_cohorts
    GROUP BY cohort_month
),
retention_data AS (
    -- Calculate retention for each cohort/month combination
    SELECT 
        co.cohort_month,
        co.months_since_cohort,
        cs.cohort_customers,
        COUNT(DISTINCT co.customer_id) as retained_customers
    FROM customer_orders co
    JOIN cohort_size cs ON co.cohort_month = cs.cohort_month
    GROUP BY co.cohort_month, co.months_since_cohort, cs.cohort_customers
)
SELECT 
    TO_CHAR(cohort_month, 'YYYY-MM') as cohort,
    cohort_customers as cohort_size,
    
    -- Retention by month
    MAX(CASE WHEN months_since_cohort = 0 THEN retained_customers END) as month_0,
    MAX(CASE WHEN months_since_cohort = 1 THEN retained_customers END) as month_1,
    MAX(CASE WHEN months_since_cohort = 2 THEN retained_customers END) as month_2,
    MAX(CASE WHEN months_since_cohort = 3 THEN retained_customers END) as month_3,
    MAX(CASE WHEN months_since_cohort = 6 THEN retained_customers END) as month_6,
    MAX(CASE WHEN months_since_cohort = 12 THEN retained_customers END) as month_12,
    
    -- Retention percentages
    ROUND(100.0 * MAX(CASE WHEN months_since_cohort = 1 THEN retained_customers END) / cohort_customers, 1) as month_1_retention_pct,
    ROUND(100.0 * MAX(CASE WHEN months_since_cohort = 3 THEN retained_customers END) / cohort_customers, 1) as month_3_retention_pct,
    ROUND(100.0 * MAX(CASE WHEN months_since_cohort = 6 THEN retained_customers END) / cohort_customers, 1) as month_6_retention_pct,
    ROUND(100.0 * MAX(CASE WHEN months_since_cohort = 12 THEN retained_customers END) / cohort_customers, 1) as month_12_retention_pct

FROM retention_data
WHERE cohort_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '18 months')
GROUP BY cohort_month, cohort_customers
ORDER BY cohort_month DESC;