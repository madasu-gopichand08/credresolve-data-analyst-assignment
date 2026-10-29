-- CredResolve | 01_monthly_recovery.sql
-- Run after 03_cleaning_layer.sql. Uses one canonical row per payment_id.
-- This is gross successful-payment analysis, not verified net recovery.
USE credresolve;

SELECT DATE_FORMAT(event_at, '%Y-%m') AS month,
       COUNT(DISTINCT payment_id) AS successful_payment_count,
       ROUND(SUM(amount), 2) AS gross_successful_amount,
       ROUND(AVG(amount), 2) AS average_successful_payment,
       MIN(event_at) AS first_payment_at,
       MAX(event_at) AS last_payment_at
FROM payments_clean
WHERE payment_status = 'SUCCESS'
GROUP BY DATE_FORMAT(event_at, '%Y-%m')
ORDER BY month;
