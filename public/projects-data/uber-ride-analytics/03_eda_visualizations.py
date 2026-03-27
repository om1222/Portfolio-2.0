"""
=======================================================
 Uber Ride Operations & Profitability Analysis
 Step 3: EDA Visualizations (matplotlib + seaborn)
 Run AFTER: 01_data_cleaning.py
=======================================================
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import os

CLEAN_DIR  = "data/cleaned"
PLOT_DIR   = "outputs/plots"
os.makedirs(PLOT_DIR, exist_ok=True)

# ── Uber brand palette ────────────────────────────────
BLACK   = "#000000"
WHITE   = "#FFFFFF"
BLUE    = "#276EF1"      # Uber blue
GREY    = "#1A1A1A"
LGREY   = "#2A2A2A"
GOLD    = "#F0B429"
GREEN   = "#05A357"
RED     = "#E11900"
SLATE   = "#3D3D3D"

plt.rcParams.update({
    'figure.facecolor' : GREY,
    'axes.facecolor'   : LGREY,
    'axes.edgecolor'   : 'none',
    'text.color'       : WHITE,
    'axes.labelcolor'  : WHITE,
    'xtick.color'      : '#999999',
    'ytick.color'      : '#999999',
    'font.family'      : 'DejaVu Sans',
    'axes.titlesize'   : 13,
    'axes.titleweight' : 'bold',
    'grid.alpha'       : 0.1,
    'grid.color'       : WHITE,
})

# ── LOAD ─────────────────────────────────────────────
df = pd.read_csv(f"{CLEAN_DIR}/uber_rides_clean.csv")
df['Date'] = pd.to_datetime(df['Date'])
print(f"Loaded {len(df):,} rides")


# ──────────────────────────────────────────────────────
# PLOT 1 — Monthly Revenue Trend (Line + Area)
# ──────────────────────────────────────────────────────
monthly = df.set_index('Date').resample('ME')['Booking Value'].sum()

fig, ax = plt.subplots(figsize=(14, 5))
ax.fill_between(monthly.index, monthly.values, alpha=0.15, color=BLUE)
ax.plot(monthly.index, monthly.values, color=BLUE, linewidth=2.5, marker='o', markersize=5)
ax.set_title("Monthly Revenue Trend — 2024", color=WHITE, pad=14)
ax.set_ylabel("Revenue (₹)"); ax.set_xlabel("")
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"₹{x/1e6:.1f}M"))
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/01_monthly_revenue.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 01_monthly_revenue.png")


# ──────────────────────────────────────────────────────
# PLOT 2 — Booking Status Distribution (Donut)
# ──────────────────────────────────────────────────────
status = df['Booking Status'].value_counts()
colors = [GREEN, RED, BLUE, GOLD, '#666666']

fig, ax = plt.subplots(figsize=(8, 7))
wedges, texts, autotexts = ax.pie(
    status.values, labels=status.index,
    autopct='%1.1f%%', startangle=90,
    colors=colors[:len(status)],
    wedgeprops=dict(width=0.5, edgecolor=GREY, linewidth=2),
    pctdistance=0.75
)
for t in texts:   t.set_color(WHITE); t.set_fontsize(10)
for at in autotexts: at.set_color(BLACK); at.set_fontweight('bold'); at.set_fontsize(9)
ax.set_title("Ride Status Breakdown", color=WHITE, pad=16)
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/02_booking_status.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 02_booking_status.png")


# ──────────────────────────────────────────────────────
# PLOT 3 — Hourly Demand Heatmap (Bar)
# ──────────────────────────────────────────────────────
hourly = df.groupby('hour').size()
peak   = [7, 8, 9, 10, 17, 18, 19]
colors_h = [RED if h in peak else BLUE for h in hourly.index]

fig, ax = plt.subplots(figsize=(13, 5))
ax.bar(hourly.index, hourly.values, color=colors_h, width=0.7)
ax.set_title("Ride Demand by Hour of Day", color=WHITE, pad=12)
ax.set_xlabel("Hour"); ax.set_ylabel("Number of Rides")
ax.set_xticks(range(24))
legend_patches = [mpatches.Patch(color=RED, label='Peak Hours'),
                  mpatches.Patch(color=BLUE, label='Off-Peak')]
ax.legend(handles=legend_patches, framealpha=0.3)
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/03_hourly_demand.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 03_hourly_demand.png")


# ──────────────────────────────────────────────────────
# PLOT 4 — Payment Mode Revenue Mix (Stacked Bar)
# ──────────────────────────────────────────────────────
pay_data = df.groupby('Payment Method')['Booking Value'].sum().sort_values(ascending=False)
pay_colors = [BLUE, GOLD, GREEN, RED, '#888']

fig, ax = plt.subplots(figsize=(9, 6))
bars = ax.bar(pay_data.index, pay_data.values, color=pay_colors[:len(pay_data)], width=0.55)
ax.set_title("Revenue by Payment Mode (UPI = 45%)", color=WHITE, pad=12)
ax.set_ylabel("Revenue (₹)")
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"₹{x/1e6:.1f}M"))
total_rev = pay_data.sum()
for bar, val in zip(bars, pay_data.values):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 100000,
            f"{val/total_rev*100:.1f}%", ha='center', fontsize=10,
            color=WHITE, fontweight='bold')
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/04_payment_revenue.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 04_payment_revenue.png")


# ──────────────────────────────────────────────────────
# PLOT 5 — Cancellation Root Causes (Horizontal Bar)
# ──────────────────────────────────────────────────────
driver_reasons   = df[df['cancel_type']=='Driver']['Driver Cancellation Reason'].value_counts().head(5)
customer_reasons = df[df['cancel_type']=='Customer']['Reason for cancelling by Customer'].value_counts().head(5)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

ax1.barh(driver_reasons.index, driver_reasons.values, color=RED, height=0.55)
ax1.set_title("Driver Cancellation Reasons", color=WHITE, pad=10)
ax1.set_xlabel("Cancellations")
ax1.invert_yaxis()

ax2.barh(customer_reasons.index, customer_reasons.values, color=GOLD, height=0.55)
ax2.set_title("Customer Cancellation Reasons", color=WHITE, pad=10)
ax2.set_xlabel("Cancellations")
ax2.invert_yaxis()

plt.suptitle("Cancellation Root Cause Analysis", color=WHITE, fontsize=14, fontweight='bold', y=1.02)
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/05_cancellation_reasons.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 05_cancellation_reasons.png")


# ──────────────────────────────────────────────────────
# PLOT 6 — Revenue by Vehicle Type (Bar)
# ──────────────────────────────────────────────────────
completed = df[df['Booking Status']=='Completed']
veh_rev   = completed.groupby('Vehicle Type')['Booking Value'].sum().sort_values(ascending=False)
veh_colors= [BLUE if i==0 else '#3A3A5A' for i in range(len(veh_rev))]

fig, ax = plt.subplots(figsize=(10, 5))
bars = ax.bar(veh_rev.index, veh_rev.values, color=veh_colors, width=0.6)
ax.set_title("Total Revenue by Vehicle Type (Completed Rides)", color=WHITE, pad=12)
ax.set_ylabel("Revenue (₹)")
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"₹{x/1e6:.1f}M"))
for bar in bars:
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 50000,
            f"₹{bar.get_height()/1e6:.2f}M", ha='center', fontsize=9, color=WHITE)
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/06_vehicle_revenue.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 06_vehicle_revenue.png")


# ──────────────────────────────────────────────────────
# PLOT 7 — Ratings Distribution (Side-by-side)
# ──────────────────────────────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

for ax, col, color, label in zip(
    axes,
    ['Driver Ratings', 'Customer Rating'],
    [BLUE, GREEN],
    ['Driver Ratings', 'Customer Ratings']
):
    data = completed[col].dropna()
    ax.hist(data, bins=20, color=color, edgecolor=GREY, alpha=0.85)
    ax.axvline(data.mean(), color=GOLD, linestyle='--', linewidth=2,
               label=f"Mean: {data.mean():.2f}")
    ax.set_title(label, color=WHITE, pad=10)
    ax.set_xlabel("Rating"); ax.set_ylabel("Count")
    ax.legend(framealpha=0.3)

plt.suptitle("Rating Distributions — Drivers vs Customers", color=WHITE,
             fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/07_ratings_distribution.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 07_ratings_distribution.png")


# ──────────────────────────────────────────────────────
# PLOT 8 — Cancellation Rate by Vehicle Type
# ──────────────────────────────────────────────────────
veh_cancel = df.groupby('Vehicle Type').apply(
    lambda x: pd.Series({
        'cancel_rate': x['is_cancelled'].mean() * 100,
        'rides': len(x)
    })
).reset_index()

fig, ax = plt.subplots(figsize=(10, 5))
colors_v = [RED if v > 25 else GOLD if v > 20 else BLUE for v in veh_cancel['cancel_rate']]
bars = ax.bar(veh_cancel['Vehicle Type'], veh_cancel['cancel_rate'],
              color=colors_v, width=0.6)
ax.axhline(25, color=WHITE, linestyle='--', linewidth=1.5, alpha=0.4, label='Avg 25%')
ax.set_title("Cancellation Rate by Vehicle Type", color=WHITE, pad=12)
ax.set_ylabel("Cancellation Rate (%)")
for bar, val in zip(bars, veh_cancel['cancel_rate']):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.3,
            f"{val:.1f}%", ha='center', fontsize=9, color=WHITE)
ax.legend(framealpha=0.3)
plt.tight_layout()
plt.savefig(f"{PLOT_DIR}/08_vehicle_cancel_rate.png", dpi=150, bbox_inches='tight')
plt.close(); print("Saved: 08_vehicle_cancel_rate.png")

print("\n✅ All 8 plots saved to outputs/plots/")
