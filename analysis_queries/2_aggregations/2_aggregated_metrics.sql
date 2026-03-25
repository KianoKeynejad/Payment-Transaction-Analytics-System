
-- 2 — Aggregated Performance Metrics
-- Aggregated transaction data to produce key operational metrics.
-- Evaluated transaction value and fee revenue by status,
-- calculated average transaction value for approved transactions,
-- and analysed monthly trends in transaction count, transaction value,
-- and total fee revenue to understand performance over time.




-- Total transaction value by transaction status
SELECT
  transaction_status,
  SUM(transaction_amount) AS total_transaction_value
FROM payment_analytics.transactions
GROUP BY transaction_status
ORDER BY transaction_status;


-- Total fee revenue by transaction status
SELECT
  transaction_status,
  SUM(fee_amount) AS total_fee_revenue
FROM payment_analytics.transactions
GROUP BY transaction_status
ORDER BY transaction_status;

-- Average transaction amount for Approved transactions
SELECT
  AVG(transaction_amount) AS avg_transaction_amount
FROM payment_analytics.transactions
WHERE transaction_status = 'Approved';

-- Number of transactions per month
SELECT
  DATE_TRUNC('month', transaction_timestamp) AS month,
  COUNT(*) AS transaction_count
FROM payment_analytics.transactions
GROUP BY month
ORDER BY month;

-- Net transaction value per month 
SELECT
  DATE_TRUNC('month', transaction_timestamp) AS month,
  SUM(transaction_amount) AS net_transaction_value
FROM payment_analytics.transactions
WHERE transaction_status IN ('Approved', 'Refunded')
GROUP BY month
ORDER BY month;



-- Total fee revenue per month
SELECT
  DATE_TRUNC('month', transaction_timestamp) AS month,
  SUM(fee_amount) AS total_fee_revenue
FROM payment_analytics.transactions
GROUP BY month
ORDER BY month;