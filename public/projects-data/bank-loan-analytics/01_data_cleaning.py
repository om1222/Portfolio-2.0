"""
=======================================================
 Bank Loan & Repayment Dashboard | Financial Analysis
 Step 1: Data Cleaning & Validation
 Dataset: 38,600 loan records
 CV KPIs: $435.8M funded · $473.9M repaid · 13.8% bad loans
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
df = pd.read_csv(f"{RAW_DIR}/bank_loans_final.csv")
print(f"  Raw shape: {df.shape}")

# ──────────────────────────────────────────────────────
# 2. INITIAL PROFILING
# ──────────────────────────────────────────────────────
print("\n── Initial Profile ──")
print(df.info())
print("\nNull counts:")
print(df.isnull().sum())
print("\nLoan Status distribution:")
print(df['loan_status'].value_counts())
print("\nGrade distribution:")
print(df['grade'].value_counts())

# ──────────────────────────────────────────────────────
# 3. FIX DATA TYPES & INCONSISTENCIES
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Standardizing columns...")

# Standardize loan_status labels (simulate raw inconsistencies)
status_map = {
    'Fully Paid'           : 'Fully Paid',
    'Current'              : 'Current',
    'Charged Off'          : 'Charged Off',
    'charged_off'          : 'Charged Off',
    'CHARGED OFF'          : 'Charged Off',
    'Late (31-120 days)'   : 'Late (31-120 days)',
    'late'                 : 'Late (31-120 days)',
    'Late (16-30 days)'    : 'Late (16-30 days)',
    'In Grace Period'      : 'In Grace Period',
}
df['loan_status'] = df['loan_status'].map(status_map).fillna(df['loan_status'])

# Standardize grade casing
df['grade'] = df['grade'].str.strip().str.upper()

# Standardize purpose
df['purpose'] = df['purpose'].str.strip().str.lower().str.replace('_',' ')

# Parse dates
df['issue_date'] = pd.to_datetime(df['issue_date'], errors='coerce')
df['last_pymnt_d'] = pd.to_datetime(df['last_pymnt_d'], errors='coerce')

# ──────────────────────────────────────────────────────
# 4. VALIDATE FINANCIAL FIELDS
# ──────────────────────────────────────────────────────
print("\n[Validation] Financial field checks...")

# Check for negative funded amounts
neg_funded = (df['funded_amount'] <= 0).sum()
if neg_funded > 0:
    df = df[df['funded_amount'] > 0]
    print(f"  Removed {neg_funded} rows with non-positive funded amounts")

# Check for negative repayments
neg_pymnt = (df['total_payment'] < 0).sum()
print(f"  Negative total_payment rows: {neg_pymnt}")

# Validate funded_amount ≤ loan_amount (funded should never exceed loan)
over_funded = (df['funded_amount'] > df['loan_amount'] * 1.05).sum()
print(f"  Over-funded anomalies: {over_funded}")

# COALESCE: fill missing last_pymnt_d for current loans
df['last_pymnt_d'] = df['last_pymnt_d'].fillna(
    df['issue_date'] + pd.to_timedelta(30, unit='D')
)

# ──────────────────────────────────────────────────────
# 5. REMOVE DUPLICATES
# ──────────────────────────────────────────────────────
print("\n[Cleaning] Duplicates...")
before = len(df)
df = df.drop_duplicates(subset='loan_id')
print(f"  Removed {before - len(df)} duplicate loan IDs")

# ──────────────────────────────────────────────────────
# 6. DERIVED COLUMNS
# ──────────────────────────────────────────────────────
print("\n[Engineering] Computed columns...")

# Bad loan flag: Charged Off + Late = bad
df['is_bad_loan'] = df['loan_status'].isin(
    ['Charged Off', 'Late (31-120 days)', 'Late (16-30 days)']
).astype(int)

# Month / Year from issue_date
df['issue_month'] = df['issue_date'].dt.to_period('M').astype(str)
df['issue_year']  = df['issue_date'].dt.year

# Loan duration (term numeric)
df['term_months'] = df['term'].str.extract(r'(\d+)').astype(int)

# Interest rate bucket
df['rate_bucket'] = pd.cut(
    df['int_rate'],
    bins=[0, 8, 12, 18, 26],
    labels=['Low (<8%)', 'Medium (8–12%)', 'High (12–18%)', 'Very High (18%+)']
)

# DTI bucket
df['dti_bucket'] = pd.cut(
    df['dti'],
    bins=[0, 10, 20, 30, 40],
    labels=['Low (<10)', 'Medium (10–20)', 'High (20–30)', 'Very High (30+)']
)

# ──────────────────────────────────────────────────────
# 7. VALIDATE ALL CV KPIs
# ──────────────────────────────────────────────────────
print("\n── CV KPI Validation ──")
total_funded    = df['funded_amount'].sum()
total_received  = df['total_payment'].sum()
bad_ratio       = df['is_bad_loan'].mean() * 100
bad_amount      = df[df['is_bad_loan']==1]['funded_amount'].sum()
total_active    = (df['loan_status']=='Current').sum()
total_closed    = (df['loan_status']=='Fully Paid').sum()
avg_loan_size   = df['funded_amount'].mean()
avg_repayment   = df['total_payment'].mean()

# MoM calculations
monthly = df.groupby('issue_month').agg(
    funded=('funded_amount','sum'),
    received=('total_payment','sum')
).reset_index().sort_values('issue_month')
mom_loan  = (monthly['funded'].iloc[-1] - monthly['funded'].iloc[-2]) / monthly['funded'].iloc[-2] * 100
mom_recv  = (monthly['received'].iloc[-1] - monthly['received'].iloc[-2]) / monthly['received'].iloc[-2] * 100

print(f"  Total Records       : {len(df):,}  (CV: 38,600+)")
print(f"  Total Funded        : ${total_funded/1e6:.1f}M  (CV: $435.8M)")
print(f"  Total Received      : ${total_received/1e6:.1f}M  (CV: $473.9M)")
print(f"  Bad Loan Ratio      : {bad_ratio:.1f}%  (CV: 13.8%)")
print(f"  Bad Loan Exposure   : ${bad_amount/1e6:.1f}M  (CV: $65.5M)")
print(f"  MoM Loan Growth     : {mom_loan:.1f}%  (CV: 13.3%)")
print(f"  MoM Repayment Growth: {mom_recv:.1f}%  (CV: 15.8%)")
print(f"  Active Loans        : {total_active:,}")
print(f"  Fully Paid Loans    : {total_closed:,}")
print(f"  Avg Loan Size       : ${avg_loan_size:,.0f}")
print(f"  Avg Repayment       : ${avg_repayment:,.0f}")

# ──────────────────────────────────────────────────────
# 8. SAVE
# ──────────────────────────────────────────────────────
df.to_csv(f"{CLEAN_DIR}/bank_loans_clean.csv", index=False)
print(f"\n✅ Cleaned dataset saved → {CLEAN_DIR}/bank_loans_clean.csv")
print("   Run 02_sql_kpis.sql, then 03_eda_visualizations.py")
