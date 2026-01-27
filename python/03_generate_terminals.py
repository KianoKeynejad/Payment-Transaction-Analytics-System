import uuid
import numpy as np
import pandas as pd
from sqlalchemy import create_engine
from datetime import timedelta

# -----------------------------
# DB CONFIG
# -----------------------------
DB_USER = "postgres"
DB_PASSWORD = "Home1394753443$"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "payment_project_db"
SCHEMA = "payment_analytics"

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

np.random.seed(42)

# -----------------------------
# Load merchants
# -----------------------------
merchants = pd.read_sql(
    f"SELECT merchant_id, start_date FROM {SCHEMA}.merchants",
    engine
)

# -----------------------------
# Terminals per merchant
# -----------------------------
terminal_counts = np.random.choice(
    [1, 2, 3],
    size=len(merchants),
    p=[0.60, 0.30, 0.10]
)

# -----------------------------
# Generate terminals
# -----------------------------
rows = []

for (_, m), n in zip(merchants.iterrows(), terminal_counts):
    for _ in range(n):
        rows.append({
            "terminal_id": str(uuid.uuid4()),
            "merchant_id": m["merchant_id"],
            "terminal_type": np.random.choice(
                ["Android", "D210e"],
                p=[0.70, 0.30]
            ),
            "activation_date": m["start_date"]
                + timedelta(days=int(np.random.randint(0, 30)))
        })

df = pd.DataFrame(rows)

print("Terminals generated:", len(df))
print(df["terminal_type"].value_counts(normalize=True))

df.to_csv("terminals.csv", index=False)
print("Saved terminals.csv")


print("Merchants loaded from DB:", len(merchants))
print("Sample merchant IDs from Python:")
print(merchants["merchant_id"].head())

