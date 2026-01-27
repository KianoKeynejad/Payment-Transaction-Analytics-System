import pandas as pd
from sqlalchemy import create_engine

# ----------------------------------
# DB CONNECTION (forced schema)
# ----------------------------------
engine = create_engine(
    "postgresql+psycopg2://postgres@localhost:5432/payment_project_db",
    connect_args={"options": "-csearch_path=payment_analytics"}
)

# ----------------------------------
# Load merchants
# ----------------------------------
merchants = pd.read_sql(
    """
    SELECT merchant_id, pricing_model, merchant_tier
    FROM merchants
    """,
    engine
)

# ----------------------------------
# Pricing logic by tier
# ----------------------------------
SMARTCHARGE_RATES = {
    "Silver": 0.015,
    "Gold": 0.012,
    "Platinum": 0.009
}

EFTPOS_FEES = {
    "Silver": 0.30,
    "Gold": 0.25,
    "Platinum": 0.20
}

profiles = merchants.copy()

profiles["smartcharge_rate"] = profiles.apply(
    lambda r: SMARTCHARGE_RATES[r["merchant_tier"]]
    if r["pricing_model"] == "SmartCharge" else None,
    axis=1
)

profiles["eftpos_fee"] = profiles["merchant_tier"].map(EFTPOS_FEES)

profiles.to_csv("price_profiles.csv", index=False)

print("Generated price_profiles.csv")
print("Rows:", len(profiles))
