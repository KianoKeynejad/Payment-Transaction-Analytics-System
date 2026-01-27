import pandas as pd
import numpy as np
import uuid
from sqlalchemy import create_engine

N_TRANSACTIONS = 1_000_000

# ----------------------------------
# DB CONNECTION
# ----------------------------------
engine = create_engine(
    "postgresql+psycopg2://postgres@localhost:5432/payment_project_db",
    connect_args={"options": "-csearch_path=payment_analytics"}
)

# ----------------------------------
# LOAD DIMENSIONS
# ----------------------------------
merchants = pd.read_sql(
    "SELECT merchant_id, pricing_model FROM merchants",
    engine
)

terminals = pd.read_sql(
    "SELECT terminal_id, merchant_id FROM terminals",
    engine
)

# ----------------------------------
# RANDOM SEED
# ----------------------------------
np.random.seed(42)

# ----------------------------------
# GENERATE BASE TRANSACTIONS
# ----------------------------------
tx = pd.DataFrame({
    "transaction_id": [uuid.uuid4() for _ in range(N_TRANSACTIONS)],
    "terminal_id": np.random.choice(terminals["terminal_id"], N_TRANSACTIONS),
    "transaction_timestamp": pd.to_datetime(
        np.random.choice(
            pd.date_range("2025-01-01", "2025-12-31", freq="T"),
            N_TRANSACTIONS
        )
    ),
    "transaction_amount": np.round(
        np.random.gamma(shape=2.0, scale=40.0, size=N_TRANSACTIONS),
        2
    ),
})

# ----------------------------------
# MAP MERCHANTS
# ----------------------------------
tx = tx.merge(terminals, on="terminal_id", how="left")
tx = tx.merge(merchants, on="merchant_id", how="left")

# ----------------------------------
# PAYMENT METHOD
# ----------------------------------
tx["payment_method"] = np.random.choice(
    ["Visa", "Mastercard", "Amex", "EFTPOS"],
    size=N_TRANSACTIONS,
    p=[0.45, 0.35, 0.10, 0.10]
)

# ----------------------------------
# CHANNEL
# ----------------------------------
tx["transaction_channel"] = np.where(
    np.random.rand(N_TRANSACTIONS) < 0.9,
    "InPerson",
    "MOTO"
)

# ----------------------------------
# STATUS
# ----------------------------------
decline_prob = (
    (tx["payment_method"] == "Amex") * 0.05 +
    (tx["transaction_channel"] == "MOTO") * 0.04
)

tx["transaction_status"] = np.where(
    np.random.rand(N_TRANSACTIONS) < decline_prob,
    "Declined",
    "Approved"
)

# ----------------------------------
# FEES
# ----------------------------------
tx["fee_amount"] = np.where(
    tx["pricing_model"] == "SmartCharge",
    tx["transaction_amount"] * 0.015,
    tx["transaction_amount"] * 0.007
).round(2)

# ----------------------------------
# FINAL COLUMNS (MATCH SQL TABLE)
# ----------------------------------
tx = tx[[
    "transaction_id",
    "merchant_id",
    "terminal_id",
    "payment_method",
    "transaction_channel",
    "transaction_timestamp",
    "transaction_amount",
    "pricing_model",
    "fee_amount",
    "transaction_status"
]]

# ----------------------------------
# SAVE
# ----------------------------------
tx.to_csv("transactions_1M.csv", index=False)

print("✅ Generated transactions_1M.csv")
print("Rows:", len(tx))
