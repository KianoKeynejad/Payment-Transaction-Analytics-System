import pandas as pd
import random
import string

# ================================
# 1. LOAD DATA
# ================================
df = pd.read_csv("/Users/kiano/Desktop/Main/IT/SQL/Payment_Transaction_Analytics_System/Merchant_monthly_profitability/merchant_monthly_profitability_2025.csv")

# ================================
# 2. GET UNIQUE MERCHANTS
# ================================
unique_merchants = df[['MID', 'Trading name']].drop_duplicates().reset_index(drop=True)

# ================================
# 3. GENERATE FAKE MID
# ================================
def generate_fake_mid():
    return "MI" + ''.join(random.choices(string.digits, k=10))

# ================================
# 4. GENERATE FAKE BUSINESS NAMES
# ================================
adjectives = [
    "Blue", "Urban", "Coastal", "Prime", "Summit", "Dynamic",
    "Elite", "NextGen", "Global", "Apex", "Bright", "Vertex"
]

nouns = [
    "Retail", "Supplies", "Trading", "Group", "Solutions",
    "Services", "Enterprises", "Holdings", "Store", "Market"
]

def generate_business_name():
    return random.choice(adjectives) + " " + random.choice(nouns)

# ================================
# 5. CREATE MAPPING TABLE
# ================================
mapping = unique_merchants.copy()

# Generate unique fake MIDs
fake_mids = set()
new_mid_list = []

for _ in range(len(mapping)):
    mid = generate_fake_mid()
    while mid in fake_mids:
        mid = generate_fake_mid()
    fake_mids.add(mid)
    new_mid_list.append(mid)

mapping['new_mid'] = new_mid_list

# Generate business names
mapping['new_name'] = [
    f"{generate_business_name()} Pty Ltd {i:04d}"
    for i in range(len(mapping))
]
# ================================
# 6. MERGE BACK TO ORIGINAL DATA
# ================================
df_final = df.merge(mapping, on=['MID', 'Trading name'], how='left')

# Replace original columns
df_final['MID'] = df_final['new_mid']
df_final['Trading name'] = df_final['new_name']

# Drop helper columns
df_final = df_final.drop(columns=['new_mid', 'new_name'])


# change string data to numeric
numeric_cols = [
    'Value of Transactions',
    'MSF Margin',
    'Merchant service fee',
    'Average Transaction'
]

for col in numeric_cols:
    df_final[col] = (
        df_final[col]
        .astype(str)
        .str.replace(r'[\$,]', '', regex=True)          # remove $ and commas
        .str.replace(r'\((.*?)\)', r'-\1', regex=True)  # (123) → -123
        .replace('-', None)                             # replace "-" with null
    )

    df_final[col] = pd.to_numeric(df_final[col], errors='coerce')
# ================================
# 7. SAVE FINAL FILE
# ================================
df_final.to_csv("merchant_monthly_profitability_2025_anonymised.csv", index=False)

# Optional: Save mapping table (for internal reference)
mapping.to_csv("merchant_mapping_reference.csv", index=False)

print("✅ Anonymisation complete. Files saved.")