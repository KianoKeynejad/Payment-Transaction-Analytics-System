
-- 4. Merchant-Level Analysis

-- Combined transaction and merchant data to evaluate merchant-level performance.
-- Analysed transaction count and total transaction value per merchant,
-- identified top-performing merchants,
-- evaluated average transaction value across merchant tiers,
-- and compared fee revenue across pricing models (SmartCharge vs SFR).


-- How many transactions does each merchant have?
SELECT
  t.merchant_id,
  COUNT(*) AS transaction_count
FROM payment_analytics.transactions t
GROUP BY t.merchant_id
ORDER BY transaction_count DESC;


-- What is the total transaction value per merchant?
-- (Net value: refunds already negative in the data; declined assumed 0 amount in the generator)
SELECT
  t.merchant_id,
  SUM(t.transaction_amount) AS total_transaction_value
FROM payment_analytics.transactions t
GROUP BY t.merchant_id
ORDER BY total_transaction_value DESC;


-- Who are the top 10 merchants by net transaction value?
SELECT
  m.merchant_id,
  m.merchant_name,
  SUM(t.transaction_amount) AS net_transaction_value
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m
  ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_id, m.merchant_name
ORDER BY net_transaction_value DESC
LIMIT 10;


-- What is the average transaction value by merchant tier?
SELECT
  m.merchant_tier,
  AVG(t.transaction_amount) AS avg_transaction_value
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m
  ON m.merchant_id = t.merchant_id
WHERE t.transaction_status = 'Approved'
GROUP BY m.merchant_tier
ORDER BY m.merchant_tier;

-- How does fee revenue differ by pricing model (SmartCharge vs SFR)?
SELECT
  m.pricing_model,
  SUM(t.fee_amount) AS total_fee_revenue,
  AVG(t.fee_amount) AS avg_fee_per_txn,
  COUNT(*) AS txn_count
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m
  ON m.merchant_id = t.merchant_id
WHERE t.transaction_status IN ('Approved', 'Refunded')
GROUP BY m.pricing_model
ORDER BY total_fee_revenue DESC;