-- Monthly orders, GMV, AOV and month-over-month growth (delivered/non-cancelled orders only).
WITH m AS (
  SELECT purchase_month,
         COUNT(*)                         AS orders,
         COUNT(DISTINCT customer_unique_id) AS customers,
         ROUND(SUM(item_value), 0)        AS gmv,
         ROUND(SUM(item_value) / COUNT(*), 2) AS aov
  FROM order_facts
  WHERE order_status NOT IN ('canceled', 'unavailable')
  GROUP BY 1
)
SELECT *, ROUND(100.0 * (orders - LAG(orders) OVER (ORDER BY purchase_month))
                / LAG(orders) OVER (ORDER BY purchase_month), 1) AS orders_mom_pct
FROM m ORDER BY purchase_month;
