CREATE TABLE IF NOT EXISTS payment_analytics.merchant_monthly_profitability (
    merchant_id UUID NOT NULL
        REFERENCES payment_analytics.merchants (merchant_id),

    month DATE NOT NULL,

    transaction_count INTEGER NOT NULL,
    total_transaction_value NUMERIC(14,2) NOT NULL,
    total_fee_amount NUMERIC(14,2) NOT NULL,
    avg_transaction_value NUMERIC(10,2) NOT NULL,

    pricing_model VARCHAR(20) NOT NULL
        CHECK (pricing_model IN ('SmartCharge', 'SFR')),

    PRIMARY KEY (merchant_id, month)
);
