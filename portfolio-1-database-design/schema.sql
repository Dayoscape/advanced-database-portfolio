-- ShopCave marketplace: relational schema (PostgreSQL 16), target 3NF
-- Runs automatically on first `docker compose up` (mounted as initdb).

CREATE TABLE customers (
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     VARCHAR(120) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    address_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    street        VARCHAR(200) NOT NULL,
    city          VARCHAR(80)  NOT NULL,
    state         VARCHAR(40)  NOT NULL,
    is_default    BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE sellers (
    seller_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_name VARCHAR(150) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    state         VARCHAR(40)  NOT NULL,
    joined_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE categories (
    category_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(80) NOT NULL UNIQUE,
    parent_id     INT REFERENCES categories(category_id)
);

CREATE TABLE products (
    product_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id     BIGINT NOT NULL REFERENCES sellers(seller_id),
    category_id   INT    NOT NULL REFERENCES categories(category_id),
    name          VARCHAR(200) NOT NULL,
    description   TEXT,
    unit_price    NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    stock_qty     INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    order_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   BIGINT NOT NULL REFERENCES customers(customer_id),
    address_id    BIGINT NOT NULL REFERENCES addresses(address_id),
    status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','paid','shipped','delivered','cancelled')),
    placed_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    order_id      BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    BIGINT NOT NULL REFERENCES products(product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),  -- price at time of sale
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    payment_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES orders(order_id),
    method        VARCHAR(20) NOT NULL CHECK (method IN ('card','transfer','cod')),
    amount        NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status        VARCHAR(20) NOT NULL DEFAULT 'initiated'
                  CHECK (status IN ('initiated','successful','failed','refunded')),
    paid_at       TIMESTAMPTZ
);

CREATE TABLE deliveries (
    delivery_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      BIGINT NOT NULL UNIQUE REFERENCES orders(order_id),
    status        VARCHAR(20) NOT NULL DEFAULT 'processing'
                  CHECK (status IN ('processing','in_transit','delivered','failed')),
    dispatched_at TIMESTAMPTZ,
    delivered_at  TIMESTAMPTZ,
    CHECK (delivered_at IS NULL OR dispatched_at IS NULL OR delivered_at >= dispatched_at)
);

CREATE TABLE reviews (
    review_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id    BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    customer_id   BIGINT NOT NULL REFERENCES customers(customer_id),
    rating        SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment       TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (product_id, customer_id)
);
