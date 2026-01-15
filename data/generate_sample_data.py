"""
E-Commerce Sample Data Generator
Generates realistic sample data for analytics testing
"""

import random
import csv
from datetime import datetime, timedelta
from faker import Faker

# Initialize
fake = Faker()
Faker.seed(42)
random.seed(42)

# Configuration
NUM_CUSTOMERS = 10000
NUM_PRODUCTS = 500
NUM_ORDERS = 100000

# Product categories and pricing
CATEGORIES = {
    'Electronics': {
        'subcategories': ['Laptops', 'Phones', 'Tablets', 'Headphones', 'Cameras'],
        'price_range': (50, 2000),
        'brands': ['Apple', 'Samsung', 'Sony', 'Dell', 'HP']
    },
    'Clothing': {
        'subcategories': ['Men', 'Women', 'Kids', 'Accessories'],
        'price_range': (15, 200),
        'brands': ['Nike', 'Adidas', 'Gap', 'Zara', 'H&M']
    },
    'Home & Garden': {
        'subcategories': ['Furniture', 'Kitchen', 'Decor', 'Tools'],
        'price_range': (20, 800),
        'brands': ['IKEA', 'KitchenAid', 'Black+Decker', 'Generic']
    },
    'Sports': {
        'subcategories': ['Fitness', 'Outdoor', 'Team Sports'],
        'price_range': (25, 500),
        'brands': ['Nike', 'Adidas', 'Under Armour', 'Reebok']
    },
    'Books': {
        'subcategories': ['Fiction', 'Non-Fiction', 'Educational'],
        'price_range': (10, 60),
        'brands': ['Penguin', 'HarperCollins', 'Generic']
    }
}

print("=" * 60)
print("E-COMMERCE SAMPLE DATA GENERATOR")
print("=" * 60)

# Generate Customers
print(f"\n[1/4] Generating {NUM_CUSTOMERS:,} customers...")
customers = []
for i in range(NUM_CUSTOMERS):
    registration_date = fake.date_time_between(start_date='-3y', end_date='now')
    customers.append({
        'email': fake.email(),
        'first_name': fake.first_name(),
        'last_name': fake.last_name(),
        'phone': fake.phone_number()[:20],
        'date_of_birth': fake.date_of_birth(minimum_age=18, maximum_age=80),
        'gender': random.choice(['Male', 'Female', 'Other', 'Prefer not to say']),
        'street_address': fake.street_address(),
        'city': fake.city(),
        'state': fake.state(),
        'zip_code': fake.zipcode(),
        'registration_date': registration_date,
        'marketing_opt_in': random.choice([True, False])
    })

with open('customers_data.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=customers[0].keys())
    writer.writeheader()
    writer.writerows(customers)
print(f"✓ Saved {len(customers):,} customers")

# Generate Products
print(f"\n[2/4] Generating {NUM_PRODUCTS:,} products...")
products = []
product_id = 1
for category, details in CATEGORIES.items():
    products_per_category = NUM_PRODUCTS // len(CATEGORIES)
    for _ in range(products_per_category):
        subcategory = random.choice(details['subcategories'])
        brand = random.choice(details['brands'])
        price_min, price_max = details['price_range']
        list_price = round(random.uniform(price_min, price_max), 2)
        cost_price = round(list_price * random.uniform(0.4, 0.7), 2)
        
        products.append({
            'sku': f'SKU-{product_id:06d}',
            'product_name': f'{brand} {fake.word().title()} {subcategory}',
            'description': fake.text(max_nb_chars=200),
            'category': category,
            'subcategory': subcategory,
            'brand': brand,
            'list_price': list_price,
            'cost_price': cost_price,
            'discount_percent': random.choice([0, 0, 0, 5, 10, 15, 20, 25]),
            'stock_quantity': random.randint(0, 500),
            'reorder_level': 10,
            'reorder_quantity': 50,
            'is_active': random.choice([True, True, True, False]),
            'launch_date': fake.date_between(start_date='-2y', end_date='today')
        })
        product_id += 1

with open('products_data.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=products[0].keys())
    writer.writeheader()
    writer.writerows(products)
print(f"✓ Saved {len(products):,} products")

# Generate Orders
print(f"\n[3/4] Generating {NUM_ORDERS:,} orders...")
orders = []
order_items = []
order_id = 1
start_date = datetime.now() - timedelta(days=365*2)

for _ in range(NUM_ORDERS):
    customer = random.choice(customers)
    order_date = fake.date_time_between(
        start_date=max(start_date, customer['registration_date']),
        end_date='now'
    )
    
    num_items = random.choices([1, 2, 3, 4, 5], weights=[40, 30, 15, 10, 5])[0]
    selected_products = random.sample(products, num_items)
    
    subtotal = 0
    order_items_list = []
    
    for product in selected_products:
        quantity = random.randint(1, 3)
        unit_price = product['list_price'] * (1 - product['discount_percent'] / 100)
        line_total = quantity * unit_price
        subtotal += line_total
        
        order_items_list.append({
            'order_id': order_id,
            'product_sku': product['sku'],
            'product_name': product['product_name'],
            'product_category': product['category'],
            'quantity': quantity,
            'unit_price': round(unit_price, 2),
            'discount_amount': round(quantity * product['list_price'] * product['discount_percent'] / 100, 2),
            'line_total': round(line_total, 2),
            'cost_price': product['cost_price']
        })
    
    tax_amount = subtotal * 0.08
    shipping_cost = 0 if subtotal > 50 else round(random.uniform(5, 15), 2)
    total_amount = subtotal + tax_amount + shipping_cost
    
    orders.append({
        'order_id': order_id,
        'customer_email': customer['email'],
        'order_number': f'ORD-{order_id:08d}',
        'order_date': order_date,
        'subtotal': round(subtotal, 2),
        'tax_amount': round(tax_amount, 2),
        'shipping_cost': shipping_cost,
        'total_amount': round(total_amount, 2),
        'order_status': random.choices(
            ['delivered', 'shipped', 'processing', 'cancelled'],
            weights=[85, 8, 5, 2]
        )[0],
        'payment_method': random.choice(['Credit Card', 'Debit Card', 'PayPal']),
        'shipping_method': random.choice(['Standard', 'Express', 'Overnight']),
        'order_source': random.choices(['website', 'mobile_app', 'phone'], weights=[70, 25, 5])[0]
    })
    
    order_items.extend(order_items_list)
    order_id += 1

with open('orders_data.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=orders[0].keys())
    writer.writeheader()
    writer.writerows(orders)
print(f"✓ Saved {len(orders):,} orders")

with open('order_items_data.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=order_items[0].keys())
    writer.writeheader()
    writer.writerows(order_items)
print(f"✓ Saved {len(order_items):,} order items")

print("\n" + "=" * 60)
print("DATA GENERATION COMPLETE!")
print("=" * 60)
print(f"\nFiles created:")
print(f"  - customers_data.csv ({len(customers):,} records)")
print(f"  - products_data.csv ({len(products):,} records)")
print(f"  - orders_data.csv ({len(orders):,} records)")
print(f"  - order_items_data.csv ({len(order_items):,} records)")
print("\nNext: Load data into database using psql COPY commands")
print("=" * 60 + "\n")