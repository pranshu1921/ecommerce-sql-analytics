#!/bin/bash

# ==============================================
# Run All Analytics Queries
# Executes all SQL queries and saves results
# ==============================================

DB_NAME="ecommerce_analytics"
OUTPUT_DIR="query_results"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================================"
echo "SQL ANALYTICS PORTFOLIO - QUERY EXECUTION"
echo "======================================================"

mkdir -p $OUTPUT_DIR

# Check database
echo -e "\n${BLUE}Testing database connection...${NC}"
psql -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${YELLOW}✗ Cannot connect to database: $DB_NAME${NC}"
    exit 1
fi

# Function to run query
run_query() {
    local query_file=$1
    local query_name=$(basename "$query_file" .sql)
    local category=$(basename $(dirname "$query_file"))
    
    echo -e "\n${BLUE}Running: ${category}/${query_name}${NC}"
    psql -d $DB_NAME -f "$query_file" > "${OUTPUT_DIR}/${category}_${query_name}.txt" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Complete${NC}"
    else
        echo -e "${YELLOW}✗ Error${NC}"
    fi
}

# Sales Analytics
echo -e "\n${BLUE}=========================================="
echo "CATEGORY: Sales Analytics"
echo -e "==========================================${NC}"
run_query "queries/01_sales_analytics/monthly_revenue_yoy.sql"
run_query "queries/01_sales_analytics/daily_sales_trends.sql"
run_query "queries/01_sales_analytics/revenue_by_category.sql"
run_query "queries/01_sales_analytics/top_selling_products.sql"

# Customer Analytics
echo -e "\n${BLUE}=========================================="
echo "CATEGORY: Customer Analytics"
echo -e "==========================================${NC}"
run_query "queries/02_customer_analytics/customer_segmentation_rfm.sql"
run_query "queries/02_customer_analytics/customer_lifetime_value.sql"
run_query "queries/02_customer_analytics/cohort_retention.sql"

# Product Analytics
echo -e "\n${BLUE}=========================================="
echo "CATEGORY: Product Analytics"
echo -e "==========================================${NC}"
run_query "queries/03_product_analytics/product_performance.sql"

# Executive Dashboard
echo -e "\n${BLUE}=========================================="
echo "CATEGORY: Executive Dashboard"
echo -e "==========================================${NC}"
run_query "queries/05_executive_dashboard/kpi_summary.sql"

# Summary
echo -e "\n======================================================"
echo "EXECUTION COMPLETE"
echo "======================================================"
echo -e "\nResults saved to: ${OUTPUT_DIR}/"
SUCCESS_COUNT=$(ls -1 ${OUTPUT_DIR}/*.txt 2>/dev/null | wc -l)
echo -e "${GREEN}✓ Executed $SUCCESS_COUNT queries${NC}\n"