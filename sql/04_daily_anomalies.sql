-- Flag days where order volume sits >3 standard deviations from its trailing 28-day mean.
WITH daily AS (
  SELECT CAST(purchased_at AS DATE) AS day, COUNT(*) AS orders
  FROM order_facts GROUP BY 1
), scored AS (
  SELECT day, orders,
         AVG(orders)         OVER w AS mean_28d,
         STDDEV_SAMP(orders) OVER w AS sd_28d
  FROM daily
  WINDOW w AS (ORDER BY day ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING)
)
SELECT day, orders, ROUND(mean_28d, 1) AS mean_28d,
       ROUND((orders - mean_28d) / NULLIF(sd_28d, 0), 2) AS z_score
FROM scored
WHERE sd_28d IS NOT NULL AND ABS((orders - mean_28d) / NULLIF(sd_28d, 0)) > 3
ORDER BY ABS((orders - mean_28d) / NULLIF(sd_28d, 0)) DESC;
