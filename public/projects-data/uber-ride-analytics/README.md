# 🚗 Uber Ride Operations & Profitability Analysis
### Data Analytics Project | Python · SQL · Tableau

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-15%2B%20Queries-4479A1?style=flat&logo=mysql&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-Dashboard-E97627?style=flat&logo=tableau&logoColor=white)
![Dataset](https://img.shields.io/badge/Records-150K%2B-276EF1?style=flat)
![Status](https://img.shields.io/badge/Status-Complete-05A357?style=flat)

---

## 📌 Problem Statement

Uber's NCR marketplace generates 150,000+ monthly ride transactions with complex interactions between drivers, riders, pricing, and geography. The raw dataset surfaced critical operational problems:

- **25% cancellation rate** — by both drivers and customers, with unclear root causes
- Inconsistent ride status labels (`"CANCEL"`, `"Cancelled"`, `"Rider_Cancelled"`)
- Payment mode names with variant spellings (`"upi"`, `"UPI"`, `"Upi Payment"`)
- Missing rider/driver ratings across thousands of records
- Duplicate ride entries inflating revenue KPIs
- No consolidated view for operations or strategy teams

---

## ✅ Solution & Impact

| Achievement | Metric |
|---|---|
| 💰 Total revenue quantified | ₹5.18 Crore (₹51.8M) |
| 🚗 Rides analyzed | 1,50,000 NCR bookings |
| 🛑 Cancellation rate identified | 25.0% (37,500 rides) |
| 📉 Projected cancellation reduction | 5–7% via targeted interventions |
| 💳 UPI revenue share found | 45% (₹2.07Cr) |
| 📈 Projected revenue uplift | ~4% via UPI promotions |
| ⏱️ Reporting time saved | 10+ hrs/month via Tableau automation |

---

## 📁 Repository Structure

```
uber-ride-analytics/
│
├── data/
│   ├── raw/
│   │   └── ncr_ride_bookings.csv        # 150,000 raw ride records
│   └── cleaned/
│       └── uber_rides_clean.csv         # Standardized, feature-enriched dataset
│
├── sql/
│   └── 02_sql_analysis.sql              # 15 analytical SQL queries
│
├── outputs/
│   └── plots/                           # 8 EDA visualization PNGs
│
├── dashboard/
│   └── index.html                       # Interactive HTML analytics dashboard
│
├── 01_data_cleaning.py                  # Full cleaning pipeline
├── 03_eda_visualizations.py             # 8 matplotlib/seaborn charts
└── README.md
```

---

## 🏗️ How I Built It

### Step 1 — Data Cleaning (Python)

| Issue | Fix Applied |
|---|---|
| Status variants: `"CANCEL"`, `"Rider_Cancelled"` | `replace()` → unified status dict |
| Payment variants: `"upi"`, `"Upi Payment"` | `replace()` + `str.strip()` |
| Missing ratings (57K rows) | `fillna(median)` — median is robust against skew |
| Booking value nulls | `groupby('Vehicle Type').transform(fillna(median))` |
| Timestamp formatting | `pd.to_datetime()` + `.dt.hour`, `.dt.day_name()` |
| Outlier distances (0km, 200km+) | `clip(q01, q99)` quantile-based filtering |
| Duplicate Booking IDs | `drop_duplicates(subset='Booking ID')` |

**Computed columns added:**
- `hour`, `day_name`, `month`, `is_weekend`, `time_bucket`
- `is_cancelled`, `cancel_type` (Driver / Customer / None)
- `revenue_per_km`, `is_peak_hour`

---

### Step 2 — SQL Analysis (15 Queries)

| # | Query | SQL Concepts |
|---|---|---|
| 01 | Core KPI summary | `COUNT`, `SUM`, `AVG`, `CASE WHEN` |
| 02 | Booking status distribution | `GROUP BY`, window `SUM OVER()` |
| 03 | Driver cancellation root causes | `GROUP BY` + `WHERE cancel_type` |
| 04 | Customer cancellation root causes | `GROUP BY` + `WHERE cancel_type` |
| 05 | Revenue by vehicle type | `SUM`, `AVG`, window `SUM OVER()` |
| 06 | Payment mode revenue mix | `GROUP BY payment_method`, cancel rate |
| 07 | Hourly demand heatmap | `GROUP BY hour`, `CASE WHEN` segments |
| 08 | Monthly revenue trend (MoM) | CTE + `LAG()` window function |
| 09 | Ride distance buckets | `CASE WHEN` bucketing, `MIN()` |
| 10 | High-cancellation pickup zones | `HAVING`, `GROUP BY pickup_location` |
| 11 | Weekday vs Weekend performance | `is_weekend` grouping |
| 12 | Driver rating vs cancellation | Rating bucket `CASE WHEN` |
| 13 | Vehicle type cancellation profile | Driver vs Customer cancel split |
| 14 | Peak vs Off-peak revenue | `is_peak_hour` grouping |
| 15 | Incomplete rides root causes | Revenue lost analysis |

---

### Step 3 — Key Findings

1. **25% cancellation rate** — Driver cancellations (18%) are 2.6× customer ones (7%). Root cause #1: Customer-related issues and health concerns.

2. **UPI = 40% of revenue** — The single largest payment mode at ₹2.07Cr. Cash rides have higher cancellation correlation. Targeted UPI cashback → ~4% revenue uplift.

3. **Evening peak (6PM) = 12,397 rides/hour** — 9× the late-night baseline. Insufficient driver supply during this window is the primary driver of "No Driver Found" (7%) failures.

4. **Wrong Address = #1 customer cancellation** — 2,362 cases. Address validation at booking time is a low-effort fix with high impact.

5. **Auto dominates by volume** (25,415 rides, ₹1.29Cr), but Premier Sedan has the highest avg revenue per ride (₹509.57). Short Auto off-peak trips are the lowest-ROI segment.

---

### Step 4 — Tableau Dashboard

**KPIs automated (saving 10+ hrs/month):**
- Total Rides · Total Revenue · Avg Revenue/Ride
- Cancellation Rate · Completion Rate
- Payment Mode Mix · Rider/Driver Rating Trends
- City Zone Performance · Hourly Demand Heatmap

**Tableau features used:**
- LOD (Level of Detail) expressions for zone-level cancellation %
- Dashboard actions + filters for drill-down
- Map visualization for geographic heatmap
- Calculated fields for peak/off-peak segmentation

---

## 🚀 How to Reproduce

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/uber-ride-analytics.git
cd uber-ride-analytics

# 2. Install dependencies
pip install pandas numpy matplotlib seaborn

# 3. Place raw CSV in data/raw/
cp ncr_ride_bookings.csv data/raw/

# 4. Run pipeline
python 01_data_cleaning.py
python 03_eda_visualizations.py

# 5. Run SQL queries (DuckDB example)
# duckdb -c "CREATE TABLE uber_rides AS SELECT * FROM 'data/cleaned/uber_rides_clean.csv'; .read sql/02_sql_analysis.sql"

# 6. Open dashboard
open dashboard/index.html
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Python 3.10+ | Data cleaning, EDA, feature engineering |
| pandas · numpy | Cleaning, aggregation, computed columns |
| matplotlib · seaborn | 8 EDA visualizations |
| SQL (SQLite/DuckDB) | 15 analytical queries |
| Tableau | KPI automation dashboard |
| HTML/CSS/JS | Interactive portfolio dashboard |

---

*Built with Python · SQL · Tableau — Jan 2025 to Feb 2025*
