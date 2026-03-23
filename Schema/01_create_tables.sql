-- =========================================================
-- PAYMENT TRANSACTION ANALYTICS SYSTEM
-- MASTER SCHEMA FILE
-- =========================================================

CREATE SCHEMA IF NOT EXISTS payment_analytics;
SET search_path TO payment_analytics;

-- =========================================================
-- DROP TABLES (FACT → DIMENSION ORDER)
-- =========================================================

DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS merchant_monthly_profitability CASCADE;
DROP TABLE IF EXISTS price_profiles CASCADE;
DROP TABLE IF EXISTS terminals CASCADE;
DROP TABLE IF EXISTS merchants CASCADE;

-- =========================================================
-- MERCHANTS (DIMENSION)
-- =========================================================

CREATE TABLE merchants (
    merchant_id     UUID PRIMARY KEY,
    merchant_name   VARCHAR(150) NOT NULL,
    industry        VARCHAR(100),
    city            VARCHAR(100),
    state           VARCHAR(10),
    pricing_model   VARCHAR(20) NOT NULL
        CHECK (pricing_model IN ('SmartCharge', 'SFR')),
    merchant_tier   VARCHAR(20) NOT NULL
        CHECK (merchant_tier IN ('Silver', 'Gold', 'Platinum')),
    start_date      DATE NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'Active'
);

-- =========================================================
-- TERMINALS (DIMENSION)
-- =========================================================

CREATE TABLE terminals (
    terminal_id     UUID PRIMARY KEY,
    merchant_id     UUID NOT NULL
        REFERENCES merchants (merchant_id),
    terminal_type   VARCHAR(20) NOT NULL
        CHECK (terminal_type IN ('Android', 'D210e')),
    activation_date DATE NOT NULL
);

-- =========================================================
-- PRICE PROFILES (DIMENSION)
-- =========================================================

CREATE TABLE price_profiles (
    price_profile_id UUID PRIMARY KEY,
    merchant_id      UUID NOT NULL
        REFERENCES merchants (merchant_id),
    pricing_model    VARCHAR(20) NOT NULL
        CHECK (pricing_model IN ('SmartCharge', 'SFR')),
    merchant_tier    VARCHAR(20) NOT NULL,
    base_rate        NUMERIC(6,4) NOT NULL,
    created_at       DATE NOT NULL
);

-- =========================================================
-- TRANSACTIONS (FACT TABLE)
-- =========================================================

CREATE TABLE transactions (
    transaction_id        UUID PRIMARY KEY,
    merchant_id           UUID NOT NULL
        REFERENCES merchants (merchant_id),
    terminal_id           UUID NOT NULL
        REFERENCES terminals (terminal_id),
    payment_method        VARCHAR(20) NOT NULL
        CHECK (payment_method IN ('Visa', 'Mastercard', 'Amex', 'EFTPOS')),
    transaction_channel   VARCHAR(10) NOT NULL
        CHECK (transaction_channel IN ('InPerson', 'MOTO')),
    transaction_timestamp TIMESTAMP NOT NULL,
    transaction_amount    NUMERIC(10,2) NOT NULL,
    fee_amount            NUMERIC(10,2) NOT NULL,
    transaction_status    VARCHAR(20) NOT NULL
        CHECK (transaction_status IN ('Approved', 'Declined', 'Refunded'))
);

-- =========================================================
-- MERCHANT MONTHLY PROFITABILITY (DERIVED FACT)
-- =========================================================

CREATE TABLE merchant_monthly_profitability (
    merchant_id            UUID NOT NULL
        REFERENCES merchants (merchant_id),
    month                  DATE NOT NULL,
    transaction_count      INTEGER NOT NULL,
    total_transaction_value NUMERIC(14,2) NOT NULL,
    total_fee_amount       NUMERIC(14,2) NOT NULL,
    avg_transaction_value  NUMERIC(10,2) NOT NULL,
    pricing_model          VARCHAR(20) NOT NULL,
    PRIMARY KEY (merchant_id, month)
);

-- =========================================================
-- END OF SCHEMA
-- =========================================================
