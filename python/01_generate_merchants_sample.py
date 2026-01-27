import uuid
import numpy as np
import pandas as pd
from faker import Faker
from datetime import date

fake = Faker("en_AU")
np.random.seed(42)

# -----------------------------
# Config
# -----------------------------
N = 20000  # test batch first (we scale later)

# Tier ratios based on your 20k plan:
# Platinum 3000 (15%), Gold 5000 (25%), Silver 12000 (60%)
tier_counts = {
    "Platinum": int(N * 0.15),
    "Gold": int(N * 0.25),
    "Silver": N - int(N * 0.15) - int(N * 0.25),
}

# Top-20 industries (MCC) and weights based on your approved counts
industries = [
    "5812 - Eating Places, Restaurants",
    "7230 - Salons (Hair, Nails, Beauty)",
    "7538 - Automotive Service & Repair Shops",
    "5814 - Fast Food Restaurants",
    "7298 - Beauty Spas",
    "5462 - Bakeries",
    "8011 - Medical Practitioners (Doctors, Physicians)",
    "5422 - Butchers, Frozen Meats, Seafood",
    "5993 - Tobacco Shops",
    "5499 - Convenience & Specialty Food Stores",
    "5532 - Automotive Tyre Stores",
    "5999 - Retail Stores (Miscellaneous)",
    "5411 - Grocery Stores & Supermarkets",
    "7997 - Membership Clubs (Sports / Recreation)",
    "7297 - Massage Parlours",
    "7299 - Miscellaneous Personal Services",
    "5813 - Bars, Taverns & Nightclubs",
    "8099 - Medical Services (Other Health Practitioners)",
    "7531 - Automotive Body Repair Shops",
    "0742 - Veterinary Services",
]

industry_weights = np.array([
    2672, 2615, 1698, 1180, 583, 468, 430, 412, 280, 280,
    239, 224, 202, 201, 189, 175, 158, 155, 118, 113
], dtype=float)
industry_weights = industry_weights / industry_weights.sum()

# State weights (simple realistic distribution)
states = ["NSW", "VIC", "QLD", "WA", "SA", "ACT", "TAS", "NT"]
state_weights = np.array([0.32, 0.26, 0.20, 0.10, 0.07, 0.02, 0.02, 0.01])
state_weights = state_weights / state_weights.sum()

# Major cities per state (used for realism)
state_to_cities = {
    "NSW": ["Sydney", "Newcastle", "Wollongong"],
    "VIC": ["Melbourne", "Geelong", "Ballarat"],
    "QLD": ["Brisbane", "Gold Coast", "Sunshine Coast"],
    "WA":  ["Perth", "Fremantle", "Mandurah"],
    "SA":  ["Adelaide"],
    "ACT": ["Canberra"],
    "TAS": ["Hobart", "Launceston"],
    "NT":  ["Darwin"],
}

# Pricing model logic by tier (supports your “SFR lower margin” story later)
pricing_probs = {
    "Platinum": {"SmartCharge": 0.80, "SFR": 0.20},
    "Gold":     {"SmartCharge": 0.65, "SFR": 0.35},
    "Silver":   {"SmartCharge": 0.40, "SFR": 0.60},
}

# Status distribution (some imperfect data realism)
status_values = ["Active", "Inactive", "Suspended"]
status_probs = [0.92, 0.06, 0.02]

# City null rate (dirty data)
CITY_NULL_RATE = 0.08

# Start dates (merchant onboarding window)
START_MIN = date(2020, 1, 1)
START_MAX = date(2024, 12, 31)

# -----------------------------
# Helper functions
# -----------------------------
def random_start_date(n: int) -> pd.Series:
    start = pd.to_datetime(START_MIN)
    end = pd.to_datetime(START_MAX)
    days = (end - start).days
    offsets = np.random.randint(0, days + 1, size=n)
    dates = start + pd.to_timedelta(offsets, unit="D")
    return pd.Series(dates).dt.date


def pick_pricing_model(tier: str, n: int) -> list[str]:
    probs = pricing_probs[tier]
    return list(np.random.choice(
        ["SmartCharge", "SFR"],
        size=n,
        p=[probs["SmartCharge"], probs["SFR"]]
    ))

# -----------------------------
# Build tiers explicitly (exact counts)
# -----------------------------
tiers = (
    ["Platinum"] * tier_counts["Platinum"] +
    ["Gold"] * tier_counts["Gold"] +
    ["Silver"] * tier_counts["Silver"]
)
np.random.shuffle(tiers)

# -----------------------------
# Generate columns
# -----------------------------
merchant_ids = [str(uuid.uuid4()) for _ in range(N)]
merchant_names = [fake.company() for _ in range(N)]

industry_col = list(np.random.choice(industries, size=N, p=industry_weights))
state_col = list(np.random.choice(states, size=N, p=state_weights))

city_col = []
for st in state_col:
    # choose city or null
    if np.random.rand() < CITY_NULL_RATE:
        city_col.append(None)
    else:
        city_col.append(np.random.choice(state_to_cities[st]))

status_col = list(np.random.choice(status_values, size=N, p=status_probs))

start_dates = random_start_date(N)

# pricing model depends on tier
pricing_model_col = []
for t in tiers:
    pricing_model_col.extend(pick_pricing_model(t, 1))

df = pd.DataFrame({
    "merchant_id": merchant_ids,
    "merchant_name": merchant_names,
    "industry": industry_col,
    "city": city_col,
    "state": state_col,
    "pricing_model": pricing_model_col,
    "merchant_tier": tiers,
    "start_date": start_dates,
    "status": status_col,
})

# -----------------------------
# Quick sanity checks (prints)
# -----------------------------
print("Rows:", len(df))
print("Tier counts:\n", df["merchant_tier"].value_counts())
print("Pricing model by tier:\n", pd.crosstab(df["merchant_tier"], df["pricing_model"], normalize="index"))

# Save for inspection (and later loading)
df.to_csv("merchants_sample_20000.csv", index=False)
print("Saved merchants_sample_20000.csv")
