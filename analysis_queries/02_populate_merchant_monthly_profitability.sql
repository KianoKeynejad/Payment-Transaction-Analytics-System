INSERT INTO payment_analytics.merchant_monthly_profitability (
    merchant_id,
    month,
    transaction_count,
    total_transaction_value,
    total_fee_amount,
    avg_transaction_value,
    pricing_model
)
SELECT
    t.merchant_id,
    DATE_TRUNC('month', t.transaction_timestamp)::date AS month,

    COUNT(*) AS transaction_count,
    SUM(t.transaction_amount) AS total_transaction_value,
    SUM(t.fee_amount) AS total_fee_amount,
    AVG(t.transaction_amount) AS avg_transaction_value,

    pp.pricing_model
FROM payment_analytics.transactions t
JOIN payment_analytics.price_profiles pp
    ON t.merchant_id = pp.merchant_id
WHERE t.transaction_status = 'Approved'
GROUP BY
    t.merchant_id,
    DATE_TRUNC('month', t.transaction_timestamp),
    pp.pricing_model;
