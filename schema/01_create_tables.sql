-- ================================================
-- E-COMMERCE ANALYTICS DATABASE SCHEMA
-- PostgreSQL 13+
-- ================================================

-- Drop existing tables (if recreating)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- ================================================
-- CUSTOMERS TABLE
-- Core customer demographic and behavioral data
-- ================================================

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20),
    
    -- Address information
    street_address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50) DEFAULT 'USA',
    zip_code VARCHAR(20),
    
    -- Customer behavior
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    first_purchase_date TIMESTAMP,
    last_purchase_date TIMESTAMP,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12, 2) DEFAULT 0.00,
    
    -- Segmentation
    customer_segment VARCHAR(50),
    marketing_opt_in BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- PRODUCTS TABLE
-- Product catalog with pricing and inventory
-- ================================================

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Categorization
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    
    -- Pricing
    list_price DECIMAL(10, 2) NOT NULL CHECK (list_price >= 0),
    cost_price DECIMAL(10, 2) CHECK (cost_price >= 0),
    discount_percent DECIMAL(5, 2) DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 100),
    
    -- Inventory
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level INTEGER DEFAULT 10,
    reorder_quantity INTEGER DEFAULT 50,
    
    -- Product attributes
    weight_kg DECIMAL(8, 2),
    dimensions_cm VARCHAR(50),
    color VARCHAR(50),
    size VARCHAR(20),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    launch_date DATE,
    discontinued_date DATE,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- ORDERS TABLE
-- Order header information
-- ================================================

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- Order timing
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP,
    
    -- Financial
    subtotal DECIMAL(12, 2) NOT NULL CHECK (subtotal >= 0),
    tax_amount DECIMAL(12, 2) DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_cost DECIMAL(10, 2) DEFAULT 0 CHECK (shipping_cost >= 0),
    discount_amount DECIMAL(10, 2) DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount DECIMAL(12, 2) NOT NULL CHECK (total_amount >= 0),
    
    -- Order details
    order_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50),
    shipping_method VARCHAR(50),
    
    -- Customer interaction
    order_source VARCHAR(50) DEFAULT 'website',
    device_type VARCHAR(50),
    
    -- Shipping address (denormalized for historical accuracy)
    shipping_street VARCHAR(255),
    shipping_city VARCHAR(100),
    shipping_state VARCHAR(50),
    shipping_zip VARCHAR(20),
    shipping_country VARCHAR(50) DEFAULT 'USA',
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_status CHECK (order_status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned'))
);

-- ================================================
-- ORDER_ITEMS TABLE
-- Individual line items within orders
-- ================================================

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    
    -- Pricing (captured at time of order)
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    discount_amount DECIMAL(10, 2) DEFAULT 0 CHECK (discount_amount >= 0),
    tax_amount DECIMAL(10, 2) DEFAULT 0 CHECK (tax_amount >= 0),
    line_total DECIMAL(12, 2) NOT NULL CHECK (line_total >= 0),
    
    -- Product details (denormalized for historical accuracy)
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100) NOT NULL,
    product_category VARCHAR(100),
    
    -- Cost (for profit calculations)
    cost_price DECIMAL(10, 2),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================

-- Customer indexes
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_registration_date ON customers(registration_date);
CREATE INDEX idx_customers_segment ON customers(customer_segment);
CREATE INDEX idx_customers_city_state ON customers(city, state);

-- Product indexes
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_subcategory ON products(subcategory);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_active ON products(is_active);

-- Order indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_order_number ON orders(order_number);

-- Order items indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_category ON order_items(product_category);

-- Composite indexes for common query patterns
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_orders_date_status ON orders(order_date, order_status);

-- ================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to customers table
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to products table
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to orders table
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- VIEWS FOR COMMON QUERIES
-- ================================================

-- Complete order view with customer and product details
CREATE OR REPLACE VIEW vw_complete_orders AS
SELECT 
    o.order_id,
    o.order_number,
    o.order_date,
    o.order_status,
    -- Customer information
    c.customer_id,
    c.email as customer_email,
    c.first_name || ' ' || c.last_name as customer_name,
    c.city as customer_city,
    c.state as customer_state,
    -- Order financials
    o.subtotal,
    o.tax_amount,
    o.shipping_cost,
    o.discount_amount,
    o.total_amount,
    -- Order items summary
    COUNT(oi.order_item_id) as total_items,
    SUM(oi.quantity) as total_units,
    -- Profit calculation
    SUM(oi.line_total - (oi.cost_price * oi.quantity)) as gross_profit
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 
    o.order_id, o.order_number, o.order_date, o.order_status,
    c.customer_id, c.email, c.first_name, c.last_name, 
    c.city, c.state,
    o.subtotal, o.tax_amount, o.shipping_cost, o.discount_amount, o.total_amount;

-- ================================================
-- COMMENTS FOR DOCUMENTATION
-- ================================================

COMMENT ON TABLE customers IS 'Core customer demographic and transactional data';
COMMENT ON TABLE products IS 'Product catalog with pricing and inventory management';
COMMENT ON TABLE orders IS 'Order header information with shipping and payment details';
COMMENT ON TABLE order_items IS 'Individual line items within each order';

COMMENT ON COLUMN customers.customer_segment IS 'Customer segmentation: Champions, Loyal, At Risk, etc.';
COMMENT ON COLUMN products.discount_percent IS 'Current discount percentage (0-100)';
COMMENT ON COLUMN orders.order_status IS 'Current order status: pending, processing, shipped, delivered, cancelled, returned';

-- ================================================
-- SAMPLE VERIFICATION QUERIES
-- ================================================

-- Verify table creation
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

COMMENT ON SCHEMA public IS 'E-commerce analytics database - Production schema';