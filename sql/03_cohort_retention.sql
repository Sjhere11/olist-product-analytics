-- Monthly acquisition cohorts: share of each cohort that places another order N months later.
WITH first_order AS (
  SELECT customer_unique_id, MIN(purchase_month) AS cohort_month
  FROM order_facts WHERE order_status NOT IN ('canceled', 'unavailable') GROUP BY 1
), activity AS (
  SELECT DISTINCT o.customer_unique_id, f.cohort_month,
         DATE_DIFF('month', f.cohort_month, o.purchase_month) AS month_n
  FROM order_facts o JOIN first_order f USING (customer_unique_id)
  WHERE o.order_status NOT IN ('canceled', 'unavailable')
), sizes AS (
  SELECT cohort_month, COUNT(*) AS cohort_size FROM first_order GROUP BY 1
)
SELECT a.cohort_month, s.cohort_size, a.month_n,
       COUNT(DISTINCT a.customer_unique_id) AS active_customers,
       ROUND(100.0 * COUNT(DISTINCT a.customer_unique_id) / s.cohort_size, 2) AS retention_pct
FROM activity a JOIN sizes s USING (cohort_month)
WHERE a.month_n BETWEEN 0 AND 6
GROUP BY 1, 2, 3 ORDER BY 1, 3;
