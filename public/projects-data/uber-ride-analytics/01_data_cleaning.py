"""
=======================================================
 Uber Ride Operations & Profitability Analysis
 Step 1: Data Cleaning & Standardization
 Dataset: 150,000 NCR ride bookings
=======================================================
"""

import pandas as pd
import numpy as np
import os

RAW_DIR   = "data/raw"
CLEAN_DIR = "data/cleaned"
os.makedirs(CLEAN_DIR, exist_ok=True)

# ──────────────────────────────────────────────────────
# 1. LOAD
# ──────────────────────────────────────────────────────
print("Loading dataset...")
df = pd.read_csv(f"{RAW_DIR}/ncr_ride_bookings.csv")
print(f"  Raw shape : {df.shape}")

# ──────────────────────────────────────────────────────
# 2. INITIAL PROFILING
# ──────────────────────────────────────────────────────
print("\n── Initial Profile ──")
print(df.info())
print("\nNull counts:")
print(df.isnull().sum())
print("\nValue counts — Booking Status:")
print(df['Booking Status'].value_counts())
print("\nValue counts — Payment Method:")
print(df['Payment Method'].value_counts(dropna=False).head(10))

# ──────────────────────────────────────────────────────
# 3. DATETIME STANDARDIZATION
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Timestamps...")
df['Date']     = pd.to_datetime(df['Date'], errors='coerce')
df['Time']     = pd.to_datetime(df['Time'], format='%H:%M:%S', errors='coerce')
df['hour']     = df['Time'].dt.hour
df['day_name'] = df['Date'].dt.day_name()
df['month']    = df['Date'].dt.to_period('M').astype(str)
df['is_weekend'] = df['Date'].dt.dayofweek >= 5
df['time_bucket'] = pd.cut(
    df['hour'],
    bins=[-1, 5, 9, 12, 16, 20, 23],
    labels=['Late Night', 'Morning Rush', 'Midday', 'Afternoon', 'Evening Rush', 'Night']
)

# ──────────────────────────────────────────────────────
# 4. STANDARDIZE CATEGORICAL LABELS
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Standardizing categories...")

# Booking Status — normalize common variants
status_map = {
    'Cancelled by Driver'   : 'Driver Cancelled',
    'Cancelled by Customer' : 'Customer Cancelled',
    'No Driver Found'       : 'No Driver Found',
    'Incomplete'            : 'Incomplete',
    'Completed'             : 'Completed',
}
df['Booking Status'] = df['Booking Status'].map(status_map).fillna(df['Booking Status'])

# Payment Method — normalize casing/spelling variants
pay_map = {
    'upi'          : 'UPI',   'Upi'        : 'UPI',   'UPI Payment': 'UPI',
    'cash'         : 'Cash',  'CASH'       : 'Cash',
    'uber wallet'  : 'Uber Wallet',
    'credit card'  : 'Credit Card', 'CREDIT CARD': 'Credit Card',
    'debit card'   : 'Debit Card',  'DEBIT CARD' : 'Debit Card',
}
df['Payment Method'] = df['Payment Method'].replace(pay_map).str.strip()

# Vehicle Type — standardize casing
df['Vehicle Type'] = df['Vehicle Type'].str.strip()

# Location fields — strip whitespace
df['Pickup Location'] = df['Pickup Location'].str.strip()
df['Drop Location']   = df['Drop Location'].str.strip()

# ──────────────────────────────────────────────────────
# 5. HANDLE MISSING VALUES
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Missing values...")

# Ratings — fill with median (more robust than mean for skewed distributions)
median_driver = df['Driver Ratings'].median()
median_cust   = df['Customer Rating'].median()
df['Driver Ratings']  = df['Driver Ratings'].fillna(median_driver)
df['Customer Rating'] = df['Customer Rating'].fillna(median_cust)
print(f"  Filled Driver Rating nulls with median: {median_driver}")
print(f"  Filled Customer Rating nulls with median: {median_cust}")

# Booking Value & Ride Distance — fill with vehicle-type median (context-aware imputation)
df['Booking Value']  = df.groupby('Vehicle Type')['Booking Value'].transform(
    lambda x: x.fillna(x.median())
)
df['Ride Distance']  = df.groupby('Vehicle Type')['Ride Distance'].transform(
    lambda x: x.fillna(x.median())
)

# VTAT / CTAT — fill with overall median
df['Avg VTAT'] = df['Avg VTAT'].fillna(df['Avg VTAT'].median())
df['Avg CTAT'] = df['Avg CTAT'].fillna(df['Avg CTAT'].median())

# Cancellation reason columns — fill with 'N/A' for non-cancelled rides
df['Reason for cancelling by Customer'] = df['Reason for cancelling by Customer'].fillna('N/A')
df['Driver Cancellation Reason']        = df['Driver Cancellation Reason'].fillna('N/A')
df['Incomplete Rides Reason']           = df['Incomplete Rides Reason'].fillna('N/A')

# ──────────────────────────────────────────────────────
# 6. REMOVE DUPLICATES
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Duplicates...")
before = len(df)
df = df.drop_duplicates(subset='Booking ID')
print(f"  Removed {before - len(df)} duplicate Booking IDs")

# ──────────────────────────────────────────────────────
# 7. CLIP OUTLIERS
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Outlier clipping...")

# Ride distance: clip at 1km–50km (0km rides and 200km+ are errors)
q_low  = df['Ride Distance'].quantile(0.01)
q_high = df['Ride Distance'].quantile(0.99)
df['Ride Distance'] = df['Ride Distance'].clip(lower=q_low, upper=q_high)
print(f"  Ride Distance clipped to [{q_low:.1f}, {q_high:.1f}] km")

# Booking Value: clip below ₹50 (clearly erroneous)
df['Booking Value'] = df['Booking Value'].clip(lower=50)

# ──────────────────────────────────────────────────────
# 8. COMPUTED COLUMNS
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Adding computed columns...")

df['is_cancelled'] = df['Booking Status'].isin(['Driver Cancelled', 'Customer Cancelled'])
df['cancel_type']  = df['Booking Status'].apply(
    lambda x: 'Driver' if x=='Driver Cancelled'
              else ('Customer' if x=='Customer Cancelled' else 'None')
)
df['revenue_per_km'] = (df['Booking Value'] / df['Ride Distance']).round(2)
df['is_peak_hour']   = df['hour'].isin(range(8, 11)) | df['hour'].isin(range(17, 20))

# ──────────────────────────────────────────────────────
# 9. FINAL VERIFICATION
# ──────────────────────────────────────────────────────
print("\n── Final Profile ──")
print(f"  Cleaned shape  : {df.shape}")
print(f"  Remaining nulls:\n{df.isnull().sum()[df.isnull().sum()>0]}")
print(f"\n  Booking Status distribution:")
print(df['Booking Status'].value_counts())

# ──────────────────────────────────────────────────────
# 10. SAVE
# ──────────────────────────────────────────────────────
df.to_csv(f"{CLEAN_DIR}/uber_rides_clean.csv", index=False)
print(f"\n✅ Saved to {CLEAN_DIR}/uber_rides_clean.csv")
print("   Run 02_sql_analysis.py next.")
