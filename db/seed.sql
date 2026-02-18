USE orders_db;

-- Insert sample customers
INSERT INTO customer (name, email) VALUES
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com'),
('Diana Prince', 'diana@example.com'),
('Edward Norton', 'edward@example.com');

-- Insert sample orders
INSERT INTO orders (customer_id, total_amount, status) VALUES
(1, 150.00, 'completed'),
(2, 200.50, 'completed'),
(1, 75.25, 'processing'),
(3, 320.00, 'completed'),
(4, 99.99, 'shipped'),
(5, 450.75, 'completed'),
(2, 180.00, 'processing'),
(3, 220.50, 'completed');

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 101, 2, 50.00),
(1, 102, 1, 50.00),
(2, 103, 3, 66.83),
(3, 104, 1, 75.25),
(4, 101, 4, 80.00),
(5, 105, 2, 49.99),
(6, 106, 5, 90.15),
(7, 107, 3, 60.00),
(8, 108, 2, 110.25);
