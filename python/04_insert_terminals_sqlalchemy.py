import pandas as pd
from sqlalchemy import create_engine, text

# -----------------------------
# DATABASE CONNECTION
# -----------------------------
engine = create_engine(
    "postgresql+psycopg2://postgres@localhost:5432/payment_project_db",
    connect_args={"options": "-csearch_path=payment_analytics"}
)

# -----------------------------
# LOAD CSV
# -----------------------------
CSV_PATH = "terminals.csv"
df = pd.read_csv(CSV_PATH)

print(f"Loaded {len(df)} rows from CSV")

# -----------------------------
# INSERT INTO DATABASE
# -----------------------------
with engine.begin() as conn:
    before = conn.execute(
        text("SELECT COUNT(*) FROM terminals")
    ).scalar()

    df.to_sql(
        "terminals",
        conn,
        if_exists="append",
        index=False,
        method="multi",
        chunksize=1000
    )

    after = conn.execute(
        text("SELECT COUNT(*) FROM terminals")
    ).scalar()

print("Rows before insert:", before)
print("Rows after insert:", after)

