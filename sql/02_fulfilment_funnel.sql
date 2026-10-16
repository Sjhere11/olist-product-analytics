-- Order lifecycle funnel: placed -> approved -> shipped -> delivered -> reviewed.
WITH f AS (
  SELECT of.*, (r.order_id IS NOT NULL) AS reviewed
  FROM order_facts of LEFT JOIN (SELECT DISTINCT order_id FROM reviews) r USING (order_id)
), steps AS (
  SELECT 1 AS step, 'Placed'    AS stage, COUNT(*) AS orders FROM f
  UNION ALL SELECT 2, 'Approved',  COUNT(*) FROM f WHERE approved_at  IS NOT NULL
  UNION ALL SELECT 3, 'Shipped',   COUNT(*) FROM f WHERE shipped_at   IS NOT NULL
  UNION ALL SELECT 4, 'Delivered', COUNT(*) FROM f WHERE delivered_at IS NOT NULL
  UNION ALL SELECT 5, 'Reviewed',  COUNT(*) FROM f WHERE delivered_at IS NOT NULL AND reviewed
)
SELECT step, stage, orders,
       ROUND(100.0 * orders / FIRST_VALUE(orders) OVER (ORDER BY step), 1) AS pct_of_placed,
       ROUND(100.0 * orders / LAG(orders) OVER (ORDER BY step), 1)         AS pct_of_prev_step
FROM steps ORDER BY step;
