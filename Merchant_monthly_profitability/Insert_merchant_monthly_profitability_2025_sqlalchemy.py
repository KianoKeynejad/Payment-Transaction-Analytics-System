import pandas as pd
from sqlalchemy import create_engine

# -----------------------------
# CONFIG — UPDATE IF NEEDED
# -----------------------------
DB_USER = "postgres"
DB_PASSWORD = "Home1394753443$"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "payment_project_db"
SCHEMA = "payment_analytics"
TABLE = "merchant_monthly_profitability_external"
# ================================
# 1. LOAD CLEANED CSV
# ================================
file_path = "/Users/kiano/Desktop/Main/IT/SQL/Payment_Transaction_Analytics_System/Merchant_monthly_profitability/merchant_monthly_profitability_2025_anonymised.csv"
df = pd.read_csv(file_path)

# ================================
# 2. CREATE DB CONNECTION
# ================================
# format: postgresql://username:password@localhost:5432/dbname

engine = create_engine(
    f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)
# ================================
# 3. RENAME COLUMNS (MATCH DB TABLE)
# ================================
df = df.rename(columns={
    'MID': 'mid',
    'Trading name': 'trading_name',
    'Value of Transactions': 'value_of_transactions',
    'MSF Margin': 'msf_margin',
    'Merchant service fee': 'merchant_service_fee',
    'Number of Transactions': 'number_of_transactions',
    'Average Transaction': 'average_transaction',
    'Mcc': 'mcc',
    'Industry': 'industry',
    'Month': 'month'
})

# ================================
# 4. CONVERT DATE COLUMN
# ================================
df['month'] = pd.to_datetime(df['month'])

# ================================
# 5. INSERT INTO POSTGRES
# ================================
df.to_sql(
    name='merchant_monthly_profitability_external',
    con=engine,
    schema='payment_analytics',
    if_exists='append',
    index=False,
    chunksize=1000,   # faster batch insert
    method='multi'
)

print("✅ Data inserted successfully!")