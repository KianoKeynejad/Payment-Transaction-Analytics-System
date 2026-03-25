
-- 5 — Time-Series & Segment Analysis

-- Analysed transaction trends over time and across business segments.
-- Evaluated monthly transaction value per merchant,
-- identified merchants with declining activity,
-- analysed refund rate across merchant tiers,
-- compared monthly fee revenue between pricing models,
-- and identified industries generating the highest fee revenue.


-- Monthly transaction value per merchant
	SELECT 
		merchant_id, 
		date_trunc ('month', transaction_timestamp) AS month, 
		sum (transaction_amount ) AS monthly_amount
    FROM payment_analytics.transactions 
	GROUP BY 1, 2;


-- Merchants show a decline in transaction value over time
WITH monthly_totals AS (
    SELECT
        merchant_id,
        DATE_TRUNC('month', transaction_timestamp) AS month,
        SUM(transaction_amount) AS monthly_amount
    FROM payment_analytics.transactions 
    GROUP BY 1, 2
)

SELECT DISTINCT merchant_id
FROM (
    SELECT
        merchant_id,
        monthly_amount,
        LAG(monthly_amount) OVER (
            PARTITION BY merchant_id
            ORDER BY month
        ) AS previous_value
    FROM monthly_totals
) t
WHERE monthly_amount < previous_value;



-- 2) Merchants showing a decline in transaction value over time (rows where month total < previous month)
WITH monthly AS (
    SELECT
        t.merchant_id,
        m.merchant_name,
        DATE_TRUNC('month', t.transaction_timestamp)::date AS month,
        SUM(t.transaction_amount) AS monthly_amount
    FROM payment_analytics.transactions t
    JOIN payment_analytics.merchants m 
        ON t.merchant_id = m.merchant_id
    WHERE 
    	t.transaction_status <> 'Declined'
    GROUP BY 
    	1, 2, 3
),


monthly_with_lag AS (
    SELECT
        merchant_id,
        merchant_name,
        month,
        monthly_amount,
        LAG (monthly_amount) 
            OVER (PARTITION BY merchant_id ORDER BY month) AS prev_month_value
    FROM 
    	monthly
)

SELECT
    merchant_id,
    merchant_name,
    month,
    monthly_amount,
    prev_month_value,
    monthly_amount - prev_month_value AS change_absolute,
    ROUND(
        100.0 * (monthly_amount - prev_month_value) / NULLIF(prev_month_value, 0), 2
    ) AS change_pct
FROM monthly_with_lag
WHERE monthly_amount < prev_month_value
ORDER BY merchant_id, month;


-- Refund rate by merchant tier
SELECT
  m.merchant_tier,
  SUM(CASE WHEN t.transaction_status = 'Refunded' THEN 1 ELSE 0 END) AS refunded_count,
  COUNT(*) AS total_count,
  ROUND(1.0 * SUM(CASE WHEN t.transaction_status = 'Refunded' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),4) AS refund_rate
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_tier
ORDER BY refund_rate DESC;



-- Monthly fee revenue by pricing model (SmartCharge vs SFR)
SELECT
  date_trunc('month', t.transaction_timestamp)::date AS month,
  m.pricing_model,
  SUM(t.fee_amount) AS total_fee_revenue,
  COUNT(*) AS transaction_count
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m ON t.merchant_id = m.merchant_id
GROUP BY date_trunc('month', t.transaction_timestamp), m.pricing_model
ORDER BY month, m.pricing_model;



-- Industries generating the highest fee revenue
SELECT
  m.industry,
  SUM(t.fee_amount) AS total_fee_revenue,
  COUNT(*) AS transaction_count,
  ROUND(SUM(t.fee_amount) / NULLIF(SUM(t.transaction_amount),0),6) AS avg_fee_pct_of_volume
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.industry
ORDER BY total_fee_revenue DESC;