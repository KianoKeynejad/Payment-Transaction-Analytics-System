-- 1 — Transaction Overview & Data Exploration

-- Explored the transactions dataset to understand overall platform activity.
-- Analysed total transaction count, distribution by status (Approved, Declined, Refunded),
-- most recent transactions, total transaction value, total fee revenue,
-- and transaction volume split between MOTO and In-Person channels.


SELECT *
FROM payment_analytics.transactions
LIMIT 10;

SELECT COUNT(*) 
FROM payment_analytics.transactions;

SELECT transaction_status, COUNT(*) 
FROM payment_analytics.transactions
GROUP BY transaction_status;

SELECT transaction_id, transaction_timestamp
FROM payment_analytics.transactions
GROUP BY transaction_id, transaction_timestamp
ORDER BY transaction_timestamp DESC  
LIMIT 10;

SELECT SUM(transaction_amount)
FROM payment_analytics.transactions;

SELECT SUM(fee_amount)
FROM payment_analytics.transactions;

SELECT COUNT(*), transaction_channel 
FROM payment_analytics.transactions
GROUP BY transaction_channel;

SELECT
    COUNT(*) FILTER (WHERE transaction_status = 'Approved') AS approved_cnt,
    COUNT(*) FILTER (WHERE transaction_status = 'Declined') AS declined_cnt,
    COUNT(*) FILTER (WHERE transaction_status = 'Refunded') AS refunded_cnt
FROM payment_analytics.transactions;