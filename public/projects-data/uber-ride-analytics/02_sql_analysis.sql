-- =============================================================
--  Uber Ride Operations & Profitability Analysis
--  File: 02_sql_analysis.sql
--  Purpose: 15 analytical SQL queries on cleaned ride data
--  Load cleaned CSV into SQLite / DuckDB / MySQL first
-- =============================================================

-- ── SETUP (SQLite / DuckDB) ───────────────────────────────────
-- CREATE TABLE uber_rides AS SELECT * FROM 'data/cleaned/uber_rides_clean.csv';
-- OR in MySQL:
-- LOAD DATA INFILE 'uber_rides_clean.csv' INTO TABLE uber_rides ...;

-- ==============================================================
-- QUERY 01 — CORE KPI SUMMARY
-- Total rides, revenue, cancellations, completion rate
-- ==============================================================
SELECT
    COUNT(*)                                              AS total_rides,
    SUM(CASE WHEN booking_status = 'Completed'    THEN 1 ELSE 0 END) AS completed_rides,
    SUM(CASE WHEN is_cancelled = 1                THEN 1 ELSE 0 END) AS cancelled_rides,
    ROUND(SUM(CASE WHEN is_cancelled = 1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                         AS cancellation_rate_pct,
    ROUND(SUM(booking_value), 0)                         AS total_revenue,
    ROUND(AVG(booking_value), 2)                         AS avg_revenue_per_ride,
    ROUND(AVG(ride_distance), 2)                         AS avg_ride_distance_km,
    ROUND(AVG(driver_ratings), 2)                        AS avg_driver_rating,
    ROUND(AVG(customer_rating), 2)                       AS avg_customer_rating
FROM uber_rides;

-- ==============================================================
-- QUERY 02 — CANCELLATION RATE BY BOOKING STATUS
-- Core cancellation breakdown
-- ==============================================================
SELECT
    booking_status,
    COUNT(*)                                    AS ride_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM uber_rides
GROUP BY booking_status
ORDER BY ride_count DESC;

-- ==============================================================
-- QUERY 03 — DRIVER CANCELLATION ROOT CAUSES (ranked)
-- ==============================================================
SELECT
    driver_cancellation_reason   AS reason,
    COUNT(*)                     AS cancellations,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 1) AS pct
FROM uber_rides
WHERE cancel_type = 'Driver'
  AND driver_cancellation_reason <> 'N/A'
GROUP BY driver_cancellation_reason
ORDER BY cancellations DESC;

-- ==============================================================
-- QUERY 04 — CUSTOMER CANCELLATION ROOT CAUSES (ranked)
-- ==============================================================
SELECT
    reason_for_cancelling_by_customer AS reason,
    COUNT(*)                           AS cancellations,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 1)       AS pct
FROM uber_rides
WHERE cancel_type = 'Customer'
  AND reason_for_cancelling_by_customer <> 'N/A'
GROUP BY reason_for_cancelling_by_customer
ORDER BY cancellations DESC;

-- ==============================================================
-- QUERY 05 — REVENUE BY VEHICLE TYPE (with avg & total)
-- ==============================================================
SELECT
    vehicle_type,
    COUNT(*)                           AS rides,
    ROUND(SUM(booking_value), 0)       AS total_revenue,
    ROUND(AVG(booking_value), 2)       AS avg_revenue_per_ride,
    ROUND(AVG(ride_distance), 2)       AS avg_distance_km,
    ROUND(SUM(booking_value) * 100.0 /
          SUM(SUM(booking_value)) OVER(), 1) AS revenue_share_pct
FROM uber_rides
WHERE booking_status = 'Completed'
GROUP BY vehicle_type
ORDER BY total_revenue DESC;

-- ==============================================================
-- QUERY 06 — PAYMENT MODE REVENUE MIX
-- UPI dominance analysis (key resume insight)
-- ==============================================================
SELECT
    payment_method,
    COUNT(*)                             AS transactions,
    ROUND(SUM(booking_value), 0)         AS total_revenue,
    ROUND(AVG(booking_value), 2)         AS avg_ride_value,
    ROUND(SUM(booking_value) * 100.0 /
          SUM(SUM(booking_value)) OVER(), 1) AS revenue_share_pct,
    -- Cancellation rate per payment method
    ROUND(SUM(CASE WHEN is_cancelled = 1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)         AS cancel_rate_pct
FROM uber_rides
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- ==============================================================
-- QUERY 07 — HOURLY DEMAND HEATMAP
-- Peak hour identification
-- ==============================================================
SELECT
    hour,
    COUNT(*)                              AS total_rides,
    SUM(CASE WHEN is_cancelled = 1 THEN 1 ELSE 0 END) AS cancellations,
    ROUND(SUM(CASE WHEN is_cancelled = 1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)          AS cancel_rate_pct,
    ROUND(AVG(booking_value), 2)          AS avg_revenue,
    ROUND(SUM(booking_value), 0)          AS total_revenue,
    CASE
        WHEN hour BETWEEN 7  AND 10 THEN 'Morning Peak'
        WHEN hour BETWEEN 17 AND 19 THEN 'Evening Peak'
        WHEN hour BETWEEN 11 AND 16 THEN 'Midday'
        WHEN hour BETWEEN 20 AND 23 THEN 'Night'
        ELSE 'Late Night / Early Morning'
    END AS time_segment
FROM uber_rides
GROUP BY hour
ORDER BY hour;

-- ==============================================================
-- QUERY 08 — MONTHLY REVENUE TREND (with MoM growth)
-- Window function: LAG for month-over-month
-- ==============================================================
WITH monthly AS (
    SELECT
        month,
        COUNT(*)                          AS rides,
        ROUND(SUM(booking_value), 0)      AS revenue,
        ROUND(AVG(booking_value), 2)      AS avg_rev_per_ride,
        SUM(CASE WHEN is_cancelled=1 THEN 1 ELSE 0 END) AS cancellations
    FROM uber_rides
    GROUP BY month
)
SELECT
    month,
    rides,
    revenue,
    avg_rev_per_ride,
    cancellations,
    revenue - LAG(revenue) OVER (ORDER BY month)         AS mom_rev_change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
          * 100.0 / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- ==============================================================
-- QUERY 09 — RIDE DISTANCE BUCKETS
-- Revenue & volume by trip length segment
-- ==============================================================
SELECT
    CASE
        WHEN ride_distance <= 5        THEN '0–5 km (Short)'
        WHEN ride_distance <= 15       THEN '5–15 km (Medium)'
        WHEN ride_distance <= 30       THEN '15–30 km (Long)'
        ELSE '30+ km (Very Long)'
    END AS distance_bucket,
    COUNT(*)                           AS rides,
    ROUND(SUM(booking_value), 0)       AS total_revenue,
    ROUND(AVG(booking_value), 2)       AS avg_revenue,
    ROUND(AVG(driver_ratings), 2)      AS avg_driver_rating,
    ROUND(SUM(CASE WHEN is_cancelled=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)       AS cancel_rate_pct
FROM uber_rides
GROUP BY distance_bucket
ORDER BY MIN(ride_distance);

-- ==============================================================
-- QUERY 10 — TOP 10 HIGH-CANCELLATION PICKUP ZONES
-- HAVING filter to surface hotspots (resume: pinpointed root causes)
-- ==============================================================
SELECT
    pickup_location,
    COUNT(*)                           AS total_rides,
    SUM(CASE WHEN is_cancelled=1 THEN 1 ELSE 0 END) AS cancellations,
    ROUND(SUM(CASE WHEN is_cancelled=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)       AS cancel_rate_pct
FROM uber_rides
GROUP BY pickup_location
HAVING total_rides >= 100
ORDER BY cancel_rate_pct DESC
LIMIT 10;

-- ==============================================================
-- QUERY 11 — WEEKDAY vs WEEKEND PERFORMANCE
-- Demand & revenue split
-- ==============================================================
SELECT
    CASE WHEN is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*)                                AS rides,
    ROUND(SUM(booking_value), 0)            AS total_revenue,
    ROUND(AVG(booking_value), 2)            AS avg_revenue,
    ROUND(SUM(CASE WHEN is_cancelled=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)            AS cancel_rate_pct,
    ROUND(AVG(driver_ratings), 2)           AS avg_driver_rating
FROM uber_rides
GROUP BY is_weekend
ORDER BY day_type;

-- ==============================================================
-- QUERY 12 — DRIVER RATING BUCKETS vs CANCELLATION RATE
-- (low-rated drivers cancel more — key hypothesis test)
-- ==============================================================
SELECT
    CASE
        WHEN driver_ratings >= 4.5 THEN '4.5–5.0 (Excellent)'
        WHEN driver_ratings >= 4.0 THEN '4.0–4.5 (Good)'
        WHEN driver_ratings >= 3.5 THEN '3.5–4.0 (Average)'
        ELSE 'Below 3.5 (Poor)'
    END AS rating_bucket,
    COUNT(*)                           AS rides,
    ROUND(SUM(CASE WHEN cancel_type='Driver' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)       AS driver_cancel_rate_pct,
    ROUND(AVG(booking_value), 2)       AS avg_ride_value
FROM uber_rides
GROUP BY rating_bucket
ORDER BY MIN(driver_ratings) DESC;

-- ==============================================================
-- QUERY 13 — VEHICLE TYPE CANCELLATION PROFILE
-- Which vehicle types are cancelled most by drivers vs customers
-- ==============================================================
SELECT
    vehicle_type,
    COUNT(*)                                 AS total_rides,
    SUM(CASE WHEN cancel_type='Driver'   THEN 1 ELSE 0 END) AS driver_cancels,
    SUM(CASE WHEN cancel_type='Customer' THEN 1 ELSE 0 END) AS customer_cancels,
    ROUND(SUM(CASE WHEN is_cancelled=1   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)             AS total_cancel_pct,
    ROUND(AVG(booking_value), 2)             AS avg_booking_value
FROM uber_rides
GROUP BY vehicle_type
ORDER BY total_cancel_pct DESC;

-- ==============================================================
-- QUERY 14 — PEAK vs OFF-PEAK REVENUE COMPARISON
-- ==============================================================
SELECT
    CASE WHEN is_peak_hour = 1 THEN 'Peak Hours' ELSE 'Off-Peak Hours' END AS period,
    COUNT(*)                               AS rides,
    ROUND(SUM(booking_value), 0)           AS total_revenue,
    ROUND(AVG(booking_value), 2)           AS avg_revenue,
    ROUND(AVG(avg_vtat), 2)                AS avg_driver_arrival_min,
    ROUND(SUM(CASE WHEN is_cancelled=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)           AS cancel_rate_pct
FROM uber_rides
GROUP BY is_peak_hour
ORDER BY period;

-- ==============================================================
-- QUERY 15 — INCOMPLETE RIDES ROOT CAUSE ANALYSIS
-- ==============================================================
SELECT
    incomplete_rides_reason                AS reason,
    COUNT(*)                               AS count,
    ROUND(COUNT(*) * 100.0 /
          SUM(COUNT(*)) OVER(), 1)         AS pct,
    ROUND(AVG(booking_value), 2)           AS avg_booking_value_lost,
    ROUND(SUM(booking_value), 0)           AS total_revenue_lost
FROM uber_rides
WHERE booking_status = 'Incomplete'
  AND incomplete_rides_reason <> 'N/A'
GROUP BY incomplete_rides_reason
ORDER BY count DESC;
