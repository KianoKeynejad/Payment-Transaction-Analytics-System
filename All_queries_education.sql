-- LEVEL 1

SELECT *
FROM transactions 
LIMIT 10
;


SELECT count (*) 
FROM transactions ;


SELECT TRANSACTION_status,  count (*) 
FROM TRANSACTIOns
GROUP BY transaction_status 
;


SELECT transaction_id, transaction_timestamp
FROM transactions
GROUP BY transaction_id , transaction_timestamp
order BY transaction_timestamp DESC  
LIMIT 10
;


SELECT sum (TRANSACTION_AMOUNT)
FROM transactions
;

SELECT sum (fee_amount)
FROM transactions 
;

SELECT count(*), transaction_channel 
FrOM transactions 
GROUP BY transaction_channel
;

SELECT
    COUNT(*) FILTER (WHERE transaction_status = 'Approved')  AS approved_cnt,
    COUNT(*) FILTER (WHERE transaction_status = 'Declined')  AS declined_cnt,
    COUNT(*) FILTER (WHERE transaction_status = 'Refunded')  AS refunded_cnt
FROM payment_analytics.transactions;


--LEVEL 2

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

-- Level 3

-- 1) Approval rate (Approved / total transactions)
SELECT
  COUNT(*) FILTER (WHERE transaction_status = 'Approved')::NUMERIC
  / COUNT(*) AS approval_rate
FROM payment_analytics.transactions;

-- 2) Percentage of refunded transactions
SELECT
  COUNT(*) FILTER (WHERE transaction_status = 'Refunded')::NUMERIC
  / COUNT(*) AS refund_percentage
FROM payment_analytics.transactions;

--  3)  Refund impact on net transaction value per month
SELECT
  DATE_TRUNC('month', transaction_timestamp) AS month,
  SUM(transaction_amount) FILTER (WHERE transaction_status = 'Refunded') AS refund_impact,
  SUM(transaction_amount) - SUM(transaction_amount) filter(WHERE transaction_status = 'Refunded') AS net_value
FROM payment_analytics.transactions
GROUP BY month
ORDER BY month;

-- 4) Payment method generating the highest transaction value
SELECT
  payment_method,
  SUM(transaction_amount) AS total_transaction_value
FROM payment_analytics.transactions
WHERE transaction_status IN ('Approved', 'Refunded')
GROUP BY payment_method
ORDER BY total_transaction_value DESC;

-- 5) Transaction channel with higher average transaction value
SELECT
  transaction_channel,
  AVG(transaction_amount) AS avg_transaction_value
FROM payment_analytics.transactions
WHERE transaction_status = 'Approved'
GROUP BY transaction_channel
ORDER BY avg_transaction_value DESC;

-- Level 4 

SELECT * 
FROM merchants
LIMIT 10;

SELECT *
FROM transactions
LIMIT 10;

-- 1) How many transactions does each merchant have?
SELECT
  t.merchant_id,
  COUNT(*) AS transaction_count
FROM payment_analytics.transactions t
GROUP BY t.merchant_id
ORDER BY transaction_count DESC;


-- 2) What is the total transaction value per merchant?
-- (Net value: refunds already negative in the data; declined assumed 0 amount in the generator)
SELECT
  t.merchant_id,
  SUM(t.transaction_amount) AS total_transaction_value
FROM payment_analytics.transactions t
GROUP BY t.merchant_id
ORDER BY total_transaction_value DESC;


-- 3) Who are the top 10 merchants by net transaction value?
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


-- 4) What is the average transaction value by merchant tier?
SELECT
  m.merchant_tier,
  AVG(t.transaction_amount) AS avg_transaction_value
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m
  ON m.merchant_id = t.merchant_id
WHERE t.transaction_status = 'Approved'
GROUP BY m.merchant_tier
ORDER BY m.merchant_tier;

-- 5) How does fee revenue differ by pricing model (SmartCharge vs SFR)?
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

-- Level 5

SELECT * 
FROM transactions t
LIMIT 10;

-- 1) 
	SELECT 
		merchant_id, 
		date_trunc ('month', transaction_timestamp) AS month, 
		sum (transaction_amount ) AS monthly_amount
	FROM transactions
	GROUP BY 1, 2;


-- 2)
WITH monthly_totals AS (
    SELECT
        merchant_id,
        DATE_TRUNC('month', transaction_timestamp) AS month,
        SUM(transaction_amount) AS monthly_amount
    FROM transactions
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


-- 3) Refund rate by merchant tier
SELECT
  m.merchant_tier,
  SUM(CASE WHEN t.transaction_status = 'Refunded' THEN 1 ELSE 0 END) AS refunded_count,
  COUNT(*) AS total_count,
  ROUND(1.0 * SUM(CASE WHEN t.transaction_status = 'Refunded' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),4) AS refund_rate
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_tier
ORDER BY refund_rate DESC;



-- 4) Monthly fee revenue by pricing model (SmartCharge vs SFR)
SELECT
  date_trunc('month', t.transaction_timestamp)::date AS month,
  m.pricing_model,
  SUM(t.fee_amount) AS total_fee_revenue,
  COUNT(*) AS transaction_count
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m ON t.merchant_id = m.merchant_id
GROUP BY date_trunc('month', t.transaction_timestamp), m.pricing_model
ORDER BY month, m.pricing_model;



-- 5) Industries generating the highest fee revenue
SELECT
  m.industry,
  SUM(t.fee_amount) AS total_fee_revenue,
  COUNT(*) AS transaction_count,
  ROUND(SUM(t.fee_amount) / NULLIF(SUM(t.transaction_amount),0),6) AS avg_fee_pct_of_volume
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.industry
ORDER BY total_fee_revenue DESC;


-- Level 6

-- 1) Rank merchants by total transaction value (highest to lowest)

SELECT
    m.merchant_id,
    m.merchant_name,
    SUM(t.transaction_amount) AS total_transaction_value,
    RANK() OVER (ORDER BY SUM(t.transaction_amount) DESC) AS merchant_rank
FROM payment_analytics.transactions t
JOIN payment_analytics.merchants m
    ON t.merchant_id = m.merchant_id
WHERE t.transaction_status = 'Approved'
GROUP BY m.merchant_id, m.merchant_name
ORDER BY merchant_rank;


-- 1 (This avoids recalculating SUM() twice.) - A More Professional Version (Common in Data Teams)

SELECT
    m.merchant_id,
    m.merchant_name,
    total_transaction_value,
    RANK() OVER (ORDER BY total_transaction_value DESC) AS merchant_rank
FROM (
    SELECT
        m.merchant_id,
        m.merchant_name,
        SUM(t.transaction_amount) AS total_transaction_value
    FROM payment_analytics.transactions t
    JOIN payment_analytics.merchants m
        ON t.merchant_id = m.merchant_id
    WHERE t.transaction_status = 'Approved'
    GROUP BY m.merchant_id, m.merchant_name
) x
ORDER BY merchant_rank;


-- 2) Month-over-month change in transaction value per merchant
WITH monthly_totals AS (
    SELECT
        merchant_id,
        date_trunc('month', transaction_timestamp)::date AS month,
        SUM(transaction_amount) AS monthly_value
    FROM payment_analytics.transactions
    WHERE transaction_status = 'Approved'
    GROUP BY 1, 2
)
SELECT
    merchant_id,
    month,
    monthly_value,
    LAG(monthly_value) OVER (PARTITION BY merchant_id ORDER BY month) AS prev_month_value,
    monthly_value - LAG(monthly_value) OVER (PARTITION BY merchant_id ORDER BY month) AS change_value,
    ROUND(
        100.0 * (monthly_value - LAG(monthly_value) OVER (PARTITION BY merchant_id ORDER BY month))
        / NULLIF(LAG(monthly_value) OVER (PARTITION BY merchant_id ORDER BY month),0),
        2
    ) AS change_pct
FROM monthly_totals
ORDER BY merchant_id, month;


-- 3) Approach A: Merchants with 3 consecutive months of declining transaction volume
WITH monthly_totals AS (
    SELECT
        merchant_id,
        date_trunc('month', transaction_timestamp)::date AS month,
        SUM(transaction_amount) AS monthly_value
    FROM payment_analytics.transactions
    WHERE transaction_status = 'Approved'
    GROUP BY merchant_id, date_trunc('month', transaction_timestamp)
),
decline_check AS (
    SELECT
        merchant_id,
        month,
        monthly_value,
        LAG(monthly_value,1) OVER (PARTITION BY merchant_id ORDER BY month) AS prev_1,
        LAG(monthly_value,2) OVER (PARTITION BY merchant_id ORDER BY month) AS prev_2
    FROM monthly_totals
)
SELECT
    merchant_id,
    month,
    monthly_value
FROM decline_check
WHERE monthly_value < prev_1
AND prev_1 < prev_2;


-- 3) Approach B: Using rolling window logic to detect 3 consecutive declines
/*
  I transformed the problem into a binary decline flag and used a rolling 3-row window to detect consecutive declines.
  This avoids complex multi-LAG logic and scales better for longer streak detection.
*/


WITH monthly_totals AS (
    SELECT
        merchant_id,
        date_trunc('month', transaction_timestamp)::date AS month,
        SUM(transaction_amount) AS monthly_value
    FROM payment_analytics.transactions
    WHERE transaction_status = 'Approved'
    GROUP BY 1,2
),
with_flags AS (
    SELECT
        merchant_id,
        month,
        monthly_value,
        CASE 
            WHEN monthly_value < LAG(monthly_value) OVER (PARTITION BY merchant_id ORDER BY month)
            THEN 1 ELSE 0 
        END AS is_decline
    FROM monthly_totals
),
rolling_declines AS (
    SELECT
        merchant_id,
        month,
        monthly_value,
        SUM(is_decline) OVER (
            PARTITION BY merchant_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS decline_streak
    FROM with_flags
)
SELECT
    merchant_id,
    month,
    monthly_value
FROM rolling_declines
WHERE decline_streak = 3;




-- 4) Rolling 3-month average transaction value per merchant
WITH monthly_totals AS (
    SELECT
        merchant_id,
        date_trunc('month', transaction_timestamp)::date AS month,
        SUM(transaction_amount) AS monthly_value
    FROM payment_analytics.transactions
    WHERE transaction_status = 'Approved'
    GROUP BY merchant_id, date_trunc('month', transaction_timestamp)
)
SELECT
    merchant_id,
    month,
    monthly_value,
    AVG(monthly_value) OVER (
        PARTITION BY merchant_id
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_avg
FROM monthly_totals
ORDER BY merchant_id, month;


-- 5) Merchants with refund rate above platform average
WITH merchant_refunds AS (
    SELECT
        merchant_id,
        SUM(CASE WHEN transaction_status = 'Refunded' THEN 1 ELSE 0 END) AS refund_count,
        COUNT(*) AS total_transactions
    FROM payment_analytics.transactions
    GROUP BY merchant_id
),
merchant_rates AS (
    SELECT
        merchant_id,
        refund_count,
        total_transactions,
        1.0 * refund_count / NULLIF(total_transactions,0) AS refund_rate
    FROM merchant_refunds
),
platform_rate AS (
    SELECT
        1.0 * SUM(CASE WHEN transaction_status = 'Refunded' THEN 1 ELSE 0 END) / COUNT(*) AS avg_refund_rate
    FROM payment_analytics.transactions
)
SELECT
    m.merchant_id,
    m.merchant_name,
    mr.refund_rate,
    pr.avg_refund_rate
FROM merchant_rates mr
JOIN payment_analytics.merchants m
    ON mr.merchant_id = m.merchant_id
CROSS JOIN platform_rate pr
WHERE mr.refund_rate > pr.avg_refund_rate
ORDER BY mr.refund_rate DESC;



-- Level 7

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
