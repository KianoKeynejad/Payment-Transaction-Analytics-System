-- 7 Advanced Analytics & Business Insights

-- Built a full merchant-level monthly profitability dataset from raw transaction data,
-- transforming granular transaction records into structured reporting metrics.

-- Recreated monthly net transaction volume and fee revenue by pricing model,
-- enabling direct comparison between SmartCharge and SFR performance over time.

-- Developed a consolidated monthly executive dashboard dataset,
-- including key KPIs such as total transaction value, transaction count,
-- average transaction value, fee revenue, approval rate, and refund rate.

-- Identified high-volume, low-fee merchants by analysing fee-to-volume ratios,
-- highlighting potential repricing opportunities and revenue optimisation strategies.



-- 1) populating merchant_monthly_profitability

INSERT INTO payment_analytics.merchant_monthly_profitability (
    merchant_id,
    month,
	number_of_transactions,
	total_transaction_value,
	merchant_service_fee,
	avg_transaction_value,
	pricing_model
)
SELECT
    t.merchant_id,
    DATE_TRUNC('month', t.transaction_timestamp)::date AS month,
    COUNT(*) AS number_of_transactions,
    SUM(t.transaction_amount) AS total_transaction_value,
    SUM(t.fee_amount) AS merchant_service_fee,
    AVG(t.transaction_amount) AS avg_transaction_value,
    pp.pricing_model
FROM payment_analytics.transactions t
JOIN payment_analytics.price_profiles pp
    ON t.merchant_id = pp.merchant_id
WHERE t.transaction_status = 'Approved'
GROUP BY
    t.merchant_id,
    DATE_TRUNC('month', t.transaction_timestamp),
    pricing_model;

-- 2) Monthly net volume & fee revenue by pricing model

SELECT
    DATE_TRUNC('month', t.transaction_timestamp)::date AS month,
    pp.pricing_model,
    SUM(t.transaction_amount) AS total_transaction_value,
    SUM(t.fee_amount) AS merchant_service_fee
FROM payment_analytics.transactions t
JOIN payment_analytics.price_profiles pp
    ON t.merchant_id = pp.merchant_id
WHERE t.transaction_status = 'Approved'
GROUP BY
    DATE_TRUNC('month', t.transaction_timestamp),
    pp.pricing_model
ORDER BY month, pp.pricing_model;



-- 3) Monthly executive dashboard

SELECT
    DATE_TRUNC('month', t.transaction_timestamp)::date AS month,
    COUNT(*) AS number_of_transactions,
    SUM(t.transaction_amount) AS total_transaction_value,
    SUM(t.fee_amount) AS merchant_service_fee,
    AVG(t.transaction_amount) AS avg_transaction_value,
    SUM(CASE WHEN t.transaction_status = 'Approved' THEN 1 ELSE 0 END)::decimal
        / COUNT(*) AS approval_rate,
    SUM(CASE WHEN t.transaction_status = 'Refunded' THEN 1 ELSE 0 END)::decimal
        / COUNT(*) AS refund_rate
FROM payment_analytics.transactions t
GROUP BY DATE_TRUNC('month', t.transaction_timestamp)
ORDER BY month;



-- 4) high-volume, low-fee merchants (potential repricing candidates)

WITH merchant_stats AS (
    SELECT
        t.merchant_id,
        SUM(t.transaction_amount) AS total_transaction_value,
        SUM(t.fee_amount) AS merchant_service_fee,
        SUM(t.fee_amount) / NULLIF(SUM(t.transaction_amount), 0) AS fee_pct
    FROM payment_analytics.transactions t
    WHERE t.transaction_status = 'Approved'
    GROUP BY t.merchant_id
),
benchmarks AS (
    SELECT
        AVG(total_transaction_value) AS avg_volume,
        AVG(fee_pct) AS avg_fee_pct
    FROM merchant_stats
)
SELECT
    ms.merchant_id,
    ms.total_transaction_value,
    ms.merchant_service_fee,
    ms.fee_pct
FROM merchant_stats ms
CROSS JOIN benchmarks b
WHERE ms.total_transaction_value > b.avg_volume
  AND ms.fee_pct < b.avg_fee_pct
ORDER BY ms.total_transaction_value DESC;