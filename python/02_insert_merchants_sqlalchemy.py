import pandas as pd
from sqlalchemy import create_engine, text

# -----------------------------
# CONFIG — UPDATE IF NEEDED
# -----------------------------
DB_USER = "postgres"
DB_PASSWORD = "Home1394753443$"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "payment_project_db"
SCHEMA = "payment_analytics"
TABLE = "merchants"

CSV_PATH = "merchants_sample_20000.csv"

# -----------------------------
# Create DB Engine
# -----------------------------
engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# -----------------------------
# Load CSV
# -----------------------------
df = pd.read_csv(CSV_PATH)

print(f"Loaded {len(df)} rows from CSV")

# -----------------------------
# Insert Data (transaction-safe)
# -----------------------------
with engine.begin() as conn:
    # optional safety check
    result = conn.execute(
        text(f"SELECT COUNT(*) FROM {SCHEMA}.{TABLE}")
    ).scalar()
    print(f"Rows in merchants BEFORE insert: {result}")

    df.to_sql(
        TABLE,
        conn,
        schema=SCHEMA,
        if_exists="append",
        index=False,
        method="multi",      # faster batch insert
        chunksize=1000
    )

    result_after = conn.execute(
        text(f"SELECT COUNT(*) FROM {SCHEMA}.{TABLE}")
    ).scalar()
    print(f"Rows in merchants AFTER insert: {result_after}")
