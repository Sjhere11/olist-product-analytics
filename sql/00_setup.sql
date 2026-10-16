-- Views over the raw CSVs. Run from the repo root.
CREATE OR REPLACE VIEW orders AS
SELECT order_id, customer_id, order_status,
       TRY_CAST(order_purchase_timestamp      AS TIMESTAMP) AS purchased_at,
       TRY_CAST(order_approved_at             AS TIMESTAMP) AS approved_at,
       TRY_CAST(order_delivered_carrier_date  AS TIMESTAMP) AS shipped_at,
       TRY_CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
       TRY_CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_at
FROM read_csv_auto('data/olist_orders_dataset.csv');

CREATE OR REPLACE VIEW customers AS SELECT * FROM read_csv_auto('data/olist_customers_dataset.csv');
CREATE OR REPLACE VIEW items     AS SELECT * FROM read_csv_auto('data/olist_order_items_dataset.csv');
CREATE OR REPLACE VIEW payments  AS SELECT * FROM read_csv_auto('data/olist_order_payments_dataset.csv');
CREATE OR REPLACE VIEW reviews   AS SELECT * FROM read_csv_auto('data/olist_order_reviews_dataset.csv');

-- One row per order with revenue, review and delivery fields. Window: Jan 2017 - Aug 2018 (full months).
CREATE OR REPLACE VIEW order_facts AS
WITH rev AS (
  SELECT order_id, AVG(review_score) AS review_score FROM reviews GROUP BY order_id
), val AS (
  SELECT order_id, SUM(price) AS item_value, SUM(freight_value) AS freight FROM items GROUP BY order_id
)
SELECT o.order_id, c.customer_unique_id, c.customer_state, o.order_status,
       o.purchased_at, DATE_TRUNC('month', o.purchased_at) AS purchase_month,
       o.approved_at, o.shipped_at, o.delivered_at, o.estimated_at,
       v.item_value, v.freight, r.review_score,
       DATE_DIFF('day', o.estimated_at, o.delivered_at) AS days_vs_estimate,
       DATE_DIFF('day', o.purchased_at, o.delivered_at) AS delivery_days
FROM orders o
JOIN customers c USING (customer_id)
LEFT JOIN val v USING (order_id)
LEFT JOIN rev r USING (order_id)
WHERE o.purchased_at >= TIMESTAMP '2017-01-01' AND o.purchased_at < TIMESTAMP '2018-09-01';
