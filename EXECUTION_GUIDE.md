# Execution Guide - Get Running in 30 Minutes

## Prerequisites
- PostgreSQL 13+
- Python 3.8+
- Git

## Step 1: Setup Database (5 min)
```bash
createdb ecommerce_analytics
psql -d ecommerce_analytics -f schema/01_create_tables.sql
```

## Step 2: Generate Data (5 min)
```bash
cd data
pip install faker pandas
python generate_sample_data.py
```

## Step 3: Run Queries (10 min)
```bash
psql -d ecommerce_analytics -f queries/01_sales_analytics/monthly_revenue_yoy.sql
psql -d ecommerce_analytics -f queries/02_customer_analytics/customer_segmentation_rfm.sql
```

## Step 4: Take Screenshots (5 min)
- Database: `\dt`
- Query results
- Save to docs/screenshots/

## Step 5: Upload to GitHub (5 min)
Follow COMMIT_STRATEGY.md for 8 commits

**Total Time:** 30 minutes to portfolio-ready!

See README.md for complete documentation.