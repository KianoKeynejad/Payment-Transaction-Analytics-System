import pandas as pd
from sqlalchemy import create_engine, text

# ----------------------------------
# DB CONNECTION (FORCED SCHEMA)
# ----------------------------------
engine = create_engine(
    "postgresql+psycopg2://postgres@localhost:5432/payment_project_db",
    connect_args={"options": "-csearch_path=payment_analytics"}
)

# ----------------------------------
# LOAD CSV
# ----------------------------------
df = pd.read_csv("transactions_1M.csv")

print(f"Loaded {len(df)} rows from CSV")

# ----------------------------------
# INSERT
# ----------------------------------
with engine.begin() as conn:
    before = conn.execute(
        text("SELECT COUNT(*) FROM transactions")
    ).scalar()

    df.to_sql(
        "transactions",
        conn,
        if_exists="append",
        index=False,
        method="multi",
        chunksize=5000
    )

    after = conn.execute(
        text("SELECT COUNT(*) FROM transactions")
    ).scalar()

print("Rows before insert:", before)
print("Rows after insert:", after)
