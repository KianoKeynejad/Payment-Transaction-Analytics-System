import pandas as pd
from sqlalchemy import create_engine
import uuid
from datetime import date

# ----------------------------------
# DATABASE CONNECTION (FORCED SCHEMA)
# ----------------------------------
engine = create_engine(
    "postgresql+psycopg2://postgres@localhost:5432/payment_project_db",
    connect_args={"options": "-csearch_path=payment_analytics"}
)

# ----------------------------------
# LOAD MERCHANTS (SOURCE OF TRUTH)
# ----------------------------------
merchants = pd.read_sql(
    """
    SELECT merchant_id, pricing_model, merchant_tier
    FROM merchants
    """,
    engine
)

# ----------------------------------
# BUSINESS LOGIC
# ----------------------------------
SMARTCHARGE_RATES = {
    "Silver": 0.0150,
    "Gold": 0.0120,
    "Platinum": 0.0090
}

def calculate_base_rate(row):
    if row["pricing_model"] == "SmartCharge":
        return SMARTCHARGE_RATES[row["merchant_tier"]]
    else:
        # SFR merchants have lower margin
        return 0.0065

# ----------------------------------
# BUILD FINAL DATAFRAME (MATCHES TABLE EXACTLY)
# ----------------------------------
df = pd.DataFrame({
    "price_profile_id": [uuid.uuid4() for _ in range(len(merchants))],
    "merchant_id": merchants["merchant_id"],
    "pricing_model": merchants["pricing_model"],
    "merchant_tier": merchants["merchant_tier"],
    "base_rate": merchants.apply(calculate_base_rate, axis=1),
    "created_at": date.today()
})

# ----------------------------------
# INSERT
# ----------------------------------
df.to_sql(
    "price_profiles",
    engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=1000
)

print(f"Inserted {len(df)} rows into price_profiles")
