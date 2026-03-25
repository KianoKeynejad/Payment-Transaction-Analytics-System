
-- 6 — Advanced Analytics & Behavioural Insights

-- Applied advanced SQL techniques to uncover deeper behavioural insights.
-- Ranked merchants by total transaction value,
-- calculated month-over-month changes in merchant performance,
-- identified merchants with sustained declines in activity,
-- calculated rolling 3-month averages,
-- and benchmarked merchant refund rates against the platform average.


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

