-- Cria tabelas de exemplo no banco de origem
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    product_name VARCHAR(200) NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insere dados iniciais
INSERT INTO customers (name, email) VALUES
    ('João Silva', 'joao@example.com'),
    ('Maria Santos', 'maria@example.com'),
    ('Pedro Oliveira', 'pedro@example.com'),
    ('Ana Costa', 'ana@example.com'),
    ('Carlos Souza', 'carlos@example.com');

INSERT INTO orders (customer_id, product_name, quantity, price) VALUES
    (1, 'Notebook Dell', 1, 3500.00),
    (1, 'Mouse Logitech', 2, 150.00),
    (2, 'Teclado Mecânico', 1, 450.00),
    (3, 'Monitor LG 27"', 1, 1200.00),
    (4, 'Webcam HD', 1, 299.99),
    (5, 'Headset Gamer', 1, 350.00);

-- Configura replica identity para CDC (captura valores antigos)
ALTER TABLE customers REPLICA IDENTITY FULL;
ALTER TABLE orders REPLICA IDENTITY FULL;

-- Cria índices para melhor performance
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_customers_email ON customers(email);