-- Which states drive late deliveries and low reviews?
SELECT customer_state, COUNT(*) AS delivered_orders,
       ROUND(100.0 * AVG(CASE WHEN days_vs_estimate > 0 THEN 1 ELSE 0 END), 1) AS late_pct,
       ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
       ROUND(AVG(review_score), 2)  AS avg_review
FROM order_facts WHERE delivered_at IS NOT NULL
GROUP BY 1 HAVING COUNT(*) >= 300
ORDER BY late_pct DESC;
