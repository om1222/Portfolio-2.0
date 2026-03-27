-- =============================================================
--  Bank Loan & Repayment Dashboard | Financial Analysis
--  File: 02_sql_kpis.sql
--  Dataset: 38,600 loan records
--  CV KPIs: $435.8M funded · $473.9M repaid · 13.8% bad loans
-- =============================================================

-- ==============================================================
-- QUERY 01 — CORE PORTFOLIO KPI SUMMARY
-- CV: $435.8M funded, $473.9M repaid, 13.8% bad loan ratio
-- ==============================================================
SELECT
    COUNT(*)                                                    AS total_loans,
    ROUND(SUM(funded_amount) / 1e6, 1)                         AS total_funded_M,
    ROUND(SUM(total_payment) / 1e6, 1)                         AS total_received_M,
    ROUND(AVG(funded_amount), 0)                               AS avg_loan_size,
    ROUND(AVG(total_payment), 0)                               AS avg_repayment,
    SUM(CASE WHEN loan_status = 'Current'     THEN 1 ELSE 0 END) AS active_loans,
    SUM(CASE WHEN loan_status = 'Fully Paid'  THEN 1 ELSE 0 END) AS fully_paid,
    SUM(CASE WHEN loan_status IN ('Charged Off',
             'Late (31-120 days)','Late (16-30 days)')
             THEN 1 ELSE 0 END)                                AS bad_loans,
    ROUND(SUM(CASE WHEN loan_status IN ('Charged Off',
             'Late (31-120 days)','Late (16-30 days)')
             THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)        AS bad_loan_ratio_pct,
    ROUND(SUM(CASE WHEN loan_status IN ('Charged Off',
             'Late (31-120 days)','Late (16-30 days)')
             THEN funded_amount ELSE 0 END) / 1e6, 1)         AS bad_loan_exposure_M
FROM bank_loans;

-- ==============================================================
-- QUERY 02 — MONTHLY TREND WITH MoM GROWTH (Window Function)
-- CV: 13.3% MoM loan growth, 15.8% MoM repayment growth
-- ==============================================================
WITH monthly AS (
    SELECT
        issue_month,
        ROUND(SUM(funded_amount), 0)     AS monthly_funded,
        ROUND(SUM(total_payment), 0)     AS monthly_received,
        COUNT(*)                          AS loan_count
    FROM bank_loans
    GROUP BY issue_month
)
SELECT
    issue_month,
    monthly_funded,
    monthly_received,
    loan_count,
    -- MoM funded growth
    ROUND((monthly_funded - LAG(monthly_funded) OVER (ORDER BY issue_month))
          * 100.0 / NULLIF(LAG(monthly_funded) OVER (ORDER BY issue_month), 0), 1)
          AS mom_funded_growth_pct,
    -- MoM received growth
    ROUND((monthly_received - LAG(monthly_received) OVER (ORDER BY issue_month))
          * 100.0 / NULLIF(LAG(monthly_received) OVER (ORDER BY issue_month), 0), 1)
          AS mom_received_growth_pct
FROM monthly
ORDER BY issue_month;

-- ==============================================================
-- QUERY 03 — MTD FUNDING (Month-to-Date)
-- Automated real-time tracking as per CV
-- ==============================================================
SELECT
    ROUND(SUM(funded_amount), 0)   AS mtd_funded,
    ROUND(SUM(total_payment), 0)   AS mtd_received,
    COUNT(*)                        AS mtd_loan_count,
    ROUND(SUM(CASE WHEN is_bad_loan = 1
              THEN funded_amount ELSE 0 END), 0)  AS mtd_bad_loan_amount
FROM bank_loans
WHERE MONTH(issue_date) = MONTH(CURDATE())
  AND YEAR(issue_date)  = YEAR(CURDATE());

-- ==============================================================
-- QUERY 04 — BAD LOAN DEEP DIVE
-- CV: 13.8% ratio = $65.5M exposure
-- ==============================================================
SELECT
    loan_status,
    COUNT(*)                                    AS loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total,
    ROUND(SUM(funded_amount), 0)                AS funded_exposure,
    ROUND(SUM(total_payment), 0)                AS amount_recovered,
    ROUND(AVG(int_rate), 2)                     AS avg_interest_rate,
    ROUND(AVG(dti), 2)                          AS avg_dti,
    CASE WHEN loan_status IN ('Charged Off',
         'Late (31-120 days)','Late (16-30 days)')
         THEN 'BAD LOAN' ELSE 'GOOD LOAN' END   AS loan_category
FROM bank_loans
GROUP BY loan_status
ORDER BY funded_exposure DESC;

-- ==============================================================
-- QUERY 05 — REVENUE BY LOAN GRADE (Risk-Adjusted)
-- ==============================================================
SELECT
    grade,
    COUNT(*)                                    AS loans,
    ROUND(SUM(funded_amount)/1e6, 2)            AS funded_M,
    ROUND(SUM(total_payment)/1e6, 2)            AS received_M,
    ROUND(AVG(int_rate), 2)                     AS avg_rate,
    ROUND(SUM(CASE WHEN is_bad_loan=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                AS bad_loan_pct,
    ROUND((SUM(total_payment) - SUM(funded_amount))
          / SUM(funded_amount) * 100, 1)        AS net_yield_pct
FROM bank_loans
GROUP BY grade
ORDER BY grade;

-- ==============================================================
-- QUERY 06 — PURPOSE-LEVEL PORTFOLIO ANALYSIS
-- ==============================================================
SELECT
    purpose,
    COUNT(*)                                    AS loans,
    ROUND(SUM(funded_amount)/1e6, 2)            AS funded_M,
    ROUND(AVG(funded_amount), 0)                AS avg_loan_size,
    ROUND(SUM(CASE WHEN is_bad_loan=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                AS bad_loan_pct,
    ROUND(AVG(int_rate), 2)                     AS avg_rate
FROM bank_loans
GROUP BY purpose
ORDER BY funded_M DESC
LIMIT 10;

-- ==============================================================
-- QUERY 07 — INTEREST RATE BRACKET ANALYSIS
-- ==============================================================
SELECT
    rate_bucket,
    COUNT(*)                                    AS loans,
    ROUND(SUM(funded_amount)/1e6, 2)            AS funded_M,
    ROUND(SUM(CASE WHEN is_bad_loan=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                AS bad_loan_pct,
    ROUND(AVG(dti), 2)                          AS avg_dti,
    ROUND((SUM(total_payment) - SUM(funded_amount))
          / SUM(funded_amount) * 100, 1)        AS net_yield_pct
FROM bank_loans
GROUP BY rate_bucket
ORDER BY MIN(int_rate);

-- ==============================================================
-- QUERY 08 — HOME OWNERSHIP vs RISK
-- ==============================================================
SELECT
    home_ownership,
    COUNT(*)                                    AS loans,
    ROUND(SUM(funded_amount)/1e6, 2)            AS funded_M,
    ROUND(AVG(funded_amount), 0)                AS avg_loan,
    ROUND(SUM(CASE WHEN is_bad_loan=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                AS bad_loan_pct,
    ROUND(AVG(annual_inc), 0)                   AS avg_annual_income
FROM bank_loans
GROUP BY home_ownership
ORDER BY funded_M DESC;

-- ==============================================================
-- QUERY 09 — EMPLOYMENT LENGTH vs DEFAULT RISK
-- ==============================================================
SELECT
    emp_length,
    COUNT(*)                                    AS loans,
    ROUND(AVG(funded_amount), 0)                AS avg_loan_size,
    ROUND(SUM(CASE WHEN is_bad_loan=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                AS bad_loan_pct,
    ROUND(AVG(int_rate), 2)                     AS avg_rate
FROM bank_loans
GROUP BY emp_length
ORDER BY bad_loan_pct DESC;

-- ==============================================================
-- QUERY 10 — TERM ANALYSIS (36 vs 60 months)
-- ==============================================================
SELECT
    term,
    COUNT(*)                                    AS loans,
    ROUND(SUM(funded_amount)/1e6, 2)            AS funded_M,
    ROUND(AVG(int_rate), 2)                     AS avg_rate,
    ROUND(SUM(CASE WHEN is_bad_loan=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                AS bad_loan_pct,
    ROUND(AVG(dti), 2)                          AS avg_dti
FROM bank_loans
GROUP BY term;

-- ==============================================================
-- QUERY 11 — YEARLY PORTFOLIO GROWTH (YoY)
-- ==============================================================
WITH yearly AS (
    SELECT
        issue_year,
        COUNT(*)                              AS loans,
        ROUND(SUM(funded_amount)/1e6, 2)     AS funded_M,
        ROUND(SUM(total_payment)/1e6, 2)     AS received_M
    FROM bank_loans
    GROUP BY issue_year
)
SELECT
    issue_year,
    loans,
    funded_M,
    received_M,
    ROUND((funded_M - LAG(funded_M) OVER (ORDER BY issue_year))
          * 100.0 / NULLIF(LAG(funded_M) OVER (ORDER BY issue_year), 0), 1) AS yoy_growth_pct
FROM yearly
ORDER BY issue_year;

-- ==============================================================
-- QUERY 12 — CHARGE-OFF RATE BY GRADE (Risk tier mapping)
-- ==============================================================
SELECT
    grade,
    COUNT(*)                                    AS total_loans,
    SUM(CASE WHEN loan_status='Charged Off' THEN 1 ELSE 0 END) AS charged_off,
    ROUND(SUM(CASE WHEN loan_status='Charged Off' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)               AS charge_off_pct,
    ROUND(SUM(CASE WHEN loan_status='Charged Off'
              THEN funded_amount ELSE 0 END)/1e6, 2) AS co_exposure_M
FROM bank_loans
GROUP BY grade
ORDER BY charge_off_pct DESC;

-- ==============================================================
-- QUERY 13 — DELINQUENCY AGEING ANALYSIS
-- ==============================================================
SELECT
    CASE
        WHEN loan_status = 'In Grace Period'      THEN '0–15 days late'
        WHEN loan_status = 'Late (16-30 days)'    THEN '16–30 days late'
        WHEN loan_status = 'Late (31-120 days)'   THEN '31–120 days late'
        WHEN loan_status = 'Charged Off'          THEN 'Charged off'
        WHEN loan_status = 'Current'              THEN 'Current (on time)'
        ELSE 'Fully Paid'
    END AS delinquency_bucket,
    COUNT(*)                                      AS loans,
    ROUND(SUM(funded_amount)/1e6, 2)             AS exposure_M,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM bank_loans
GROUP BY delinquency_bucket
ORDER BY exposure_M DESC;

-- ==============================================================
-- QUERY 14 — PAYMENT METHOD ANALYSIS
-- ==============================================================
SELECT
    payment_method,
    COUNT(*)                                      AS loans,
    ROUND(SUM(total_payment)/1e6, 2)             AS total_collected_M,
    ROUND(AVG(total_payment), 0)                  AS avg_collection,
    ROUND(SUM(CASE WHEN is_bad_loan=1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                  AS bad_loan_pct
FROM bank_loans
GROUP BY payment_method
ORDER BY total_collected_M DESC;

-- ==============================================================
-- QUERY 15 — RISK SUMMARY TABLE (Executive Snapshot)
-- Matches CV: 13.8% bad loan ratio, $65.5M exposure
-- ==============================================================
SELECT
    'Total Portfolio'  AS metric, ROUND(SUM(funded_amount)/1e6,1) AS value_M,
    CAST(COUNT(*) AS VARCHAR) AS loan_count
FROM bank_loans
UNION ALL
SELECT 'Total Funded',     ROUND(SUM(funded_amount)/1e6,1), '-' FROM bank_loans
UNION ALL
SELECT 'Total Repaid',     ROUND(SUM(total_payment)/1e6,1), '-' FROM bank_loans
UNION ALL
SELECT 'Net Yield',        ROUND((SUM(total_payment)-SUM(funded_amount))/SUM(funded_amount)*100,1), '%' FROM bank_loans
UNION ALL
SELECT 'Bad Loans',        ROUND(SUM(CASE WHEN is_bad_loan=1 THEN funded_amount ELSE 0 END)/1e6,1),
    CONCAT(ROUND(AVG(is_bad_loan)*100,1),'%')
FROM bank_loans;
