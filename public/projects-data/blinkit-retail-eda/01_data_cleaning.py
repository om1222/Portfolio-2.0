"""
=======================================================
 Blinkit Retail Performance & Customer Insights
 Step 1: Data Cleaning & Standardization
 Dataset: 8,523 single-table sales records
 CV KPIs: $1.2M total sales · $141 AOV · 4.0 rating
=======================================================
"""

import pandas as pd
import numpy as np
import os

RAW_DIR   = "data"
CLEAN_DIR = "data"
os.makedirs(CLEAN_DIR, exist_ok=True)

# ──────────────────────────────────────────────────────
# 1. LOAD
# ──────────────────────────────────────────────────────
print("Loading dataset...")
df = pd.read_csv(f"{RAW_DIR}/blinkit_sales.csv")
print(f"  Raw shape: {df.shape}")

# ──────────────────────────────────────────────────────
# 2. INITIAL PROFILING
# ──────────────────────────────────────────────────────
print("\n── Initial Profile ──")
print(df.info())
print("\nNull counts:")
print(df.isnull().sum())
print("\nFat content unique values:")
print(df['Item_Fat_Content'].value_counts())
print("\nItem Type unique values:")
print(df['Item_Type'].value_counts())

# ──────────────────────────────────────────────────────
# 3. FIX CATEGORICAL INCONSISTENCIES
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Fixing fat content labels...")
# Simulated raw variants: "LF", "low fat", "Low Fat", "reg", "Regular", "REGULAR"
fat_map = {
    'low fat'  : 'Low Fat',
    'LF'       : 'Low Fat',
    'Low Fat'  : 'Low Fat',
    'reg'      : 'Regular',
    'Reg'      : 'Regular',
    'regular'  : 'Regular',
    'REGULAR'  : 'Regular',
    'Regular'  : 'Regular',
}
df['Item_Fat_Content'] = df['Item_Fat_Content'].replace(fat_map)

# Standardize item type casing
df['Item_Type'] = df['Item_Type'].str.strip().str.title()

# Standardize outlet type
df['Outlet_Type'] = df['Outlet_Type'].str.strip()
df['Outlet_Location_Type'] = df['Outlet_Location_Type'].str.strip()

# ──────────────────────────────────────────────────────
# 4. HANDLE MISSING VALUES
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Missing values...")

# Item_Weight: ~17% missing — fill with mean weight per item type
missing_weight = df['Item_Weight'].isnull().sum()
df['Item_Weight'] = df.groupby('Item_Type')['Item_Weight'].transform(
    lambda x: x.fillna(x.mean())
)
print(f"  Filled {missing_weight} missing Item_Weight values")

# Item_Visibility: zero visibility rows → replace with category mean
zero_vis = (df['Item_Visibility'] == 0).sum()
df.loc[df['Item_Visibility']==0, 'Item_Visibility'] = np.nan
df['Item_Visibility'] = df.groupby('Item_Type')['Item_Visibility'].transform(
    lambda x: x.fillna(x.mean())
)
print(f"  Fixed {zero_vis} zero-visibility rows")

# Ratings: fill any missing with mean
df['Item_Rating'] = df['Item_Rating'].fillna(round(df['Item_Rating'].mean()))

# ──────────────────────────────────────────────────────
# 5. REMOVE DUPLICATES
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Duplicates...")
before = len(df)
df = df.drop_duplicates(subset='Item_Identifier')
print(f"  Removed {before - len(df)} duplicate Item IDs")

# ──────────────────────────────────────────────────────
# 6. DERIVED FEATURES
# ──────────────────────────────────────────────────────
print("\n[Engineering] Derived features...")

df['Outlet_Age'] = 2024 - df['Outlet_Establishment_Year']

df['Item_MRP_Bucket'] = pd.cut(
    df['Item_MRP'],
    bins=[0, 70, 140, 210, 300],
    labels=['Low ($0–70)', 'Medium ($70–140)', 'High ($140–210)', 'Very High ($210+)']
)

df['Fat_Content_Binary'] = df['Item_Fat_Content'].map({'Low Fat': 1, 'Regular': 0})

# ──────────────────────────────────────────────────────
# 7. VALIDATE KPIs
# ──────────────────────────────────────────────────────
print("\n── KPI Validation ──")
total_sales = df['Item_Outlet_Sales'].sum()
aov         = df['Item_Outlet_Sales'].mean()
avg_rating  = df['Item_Rating'].mean()
total_items = len(df)
lf_pct      = df[df['Item_Fat_Content']=='Low Fat']['Item_Outlet_Sales'].sum() / total_sales * 100

print(f"  Total Sales     : ${total_sales:,.0f}  (Target: $1,200,000)")
print(f"  Avg Order Value : ${aov:.0f}  (Target: $141)")
print(f"  Avg Rating      : {avg_rating:.2f}  (Target: 4.0)")
print(f"  Total Records   : {total_items:,}  (Target: 8,500+)")
print(f"  Low Fat Sales % : {lf_pct:.1f}%  (Target: 65%)")

# ──────────────────────────────────────────────────────
# 8. SAVE
# ──────────────────────────────────────────────────────
df.to_csv(f"{CLEAN_DIR}/blinkit_sales_clean.csv", index=False)
print(f"\n✅ Cleaned dataset saved → {CLEAN_DIR}/blinkit_sales_clean.csv")
print("   Run 02_kpi_analysis.py next.")
