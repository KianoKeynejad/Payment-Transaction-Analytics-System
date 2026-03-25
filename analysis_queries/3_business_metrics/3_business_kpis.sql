

-- 3 — Core Business Metrics & KPIs

-- Developed core business metrics to assess platform performance.
-- Calculated approval rate, refund rate, and refund impact on transaction value,
-- identified top-performing payment methods by transaction value,
-- and compared average transaction value across transaction channels (In-Person vs MOTO).


-- Approval rate (Approved / total transactions)
SELECT
  COUNT(*) FILTER (WHERE transaction_status = 'Approved')::NUMERIC
  / COUNT(*) AS approval_rate
FROM payment_analytics.transactions;

-- Percentage of refunded transactions
SELECT
  COUNT(*) FILTER (WHERE transaction_status = 'Refunded')::NUMERIC
  / COUNT(*) AS refund_percentage
FROM payment_analytics.transactions;

--  Refund impact on net transaction value per month
SELECT
  DATE_TRUNC('month', transaction_timestamp) AS month,
  SUM(transaction_amount) FILTER (WHERE transaction_status = 'Refunded') AS refund_impact,
  SUM(transaction_amount) - SUM(transaction_amount) filter(WHERE transaction_status = 'Refunded') AS net_value
FROM payment_analytics.transactions
GROUP BY month
ORDER BY month;

-- Payment method generating the highest transaction value
SELECT
  payment_method,
  SUM(transaction_amount) AS total_transaction_value
FROM payment_analytics.transactions
WHERE transaction_status IN ('Approved', 'Refunded')
GROUP BY payment_method
ORDER BY total_transaction_value DESC;

-- Transaction channel with higher average transaction value
SELECT
  transaction_channel,
  AVG(transaction_amount) AS avg_transaction_value
FROM payment_analytics.transactions
WHERE transaction_status = 'Approved'
GROUP BY transaction_channel
ORDER BY avg_transaction_value DESC;