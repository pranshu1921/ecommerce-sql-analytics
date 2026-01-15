# Setup Guide - SQL Analytics Portfolio

## Quick Start

### 1. Create Database
```bash
createdb ecommerce_analytics
```

### 2. Create Schema
```bash
psql -d ecommerce_analytics -f schema/01_create_tables.sql
```

### 3. Generate Data
```bash
cd data
pip install faker pandas
python generate_sample_data.py
```

### 4. Load Data
```bash
psql -d ecommerce_analytics
\COPY customers(...) FROM 'customers_data.csv' CSV HEADER;
\COPY products(...) FROM 'products_data.csv' CSV HEADER;
```

### 5. Run Queries
```bash
psql -d ecommerce_analytics -f queries/01_sales_analytics/monthly_revenue_yoy.sql
```

## Taking Screenshots

1. Database tables: `\dt`
2. Query results: Run each query file
3. Performance: Use EXPLAIN ANALYZE
4. Save in docs/screenshots/

## Troubleshooting

**"Permission denied":**
```bash
chmod +x scripts/run_all_queries.sh
```

**"Faker not found":**
```bash
pip install faker pandas --break-system-packages
```

See README.md for full documentation.