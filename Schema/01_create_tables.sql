SET search_path TO payment_analytics;

DROP TABLE IF EXISTS merchants;

CREATE TABLE merchants (
merchant_id	UUID NOT null PRIMARY KEY,
merchant_name	varchar(150) NOT NULL,
industry	varchar(100),
city	varchar,
state	varchar,
pricing_model	varchar(20) NOT NULL,
merchant_tier	varchar(20) NOT NULL,
start_date	date NOT null, 
status	varchar NOT null DEFAULT 'Active',

-- Business rule enforcement
CONSTRAINT chk_pricing_model
	CHECK (pricing_model IN ('SmartCharge', 'SFR')),

CONSTRAINT chk_merchant_tier
	CHECK (merchant_tier IN ('Silver', 'Gold', 'Platinum'))
);

