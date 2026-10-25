-- Indexes added AFTER recording the "before" plans. Run once, then re-run the queries for the "after" plans.

-- Q1: find one customer's orders and read them in date order without sorting
CREATE INDEX idx_orders_customer_placed ON orders (customer_id, placed_at DESC);

-- Q2: narrow orders by date range first
CREATE INDEX idx_orders_placed_at ON orders (placed_at);

-- Q2 / Q4: look up order lines by product
CREATE INDEX idx_order_items_product ON order_items (product_id);

-- Q3: partial index, only the pending rows (about 5% of the table)
CREATE INDEX idx_orders_pending ON orders (placed_at) WHERE status = 'pending';

-- Q5: covering index so the aggregate can be answered from the index alone
CREATE INDEX idx_reviews_product_rating ON reviews (product_id) INCLUDE (rating);

ANALYZE;
