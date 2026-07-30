-- ============================================================
-- 05_yoy_trend.sql
-- QUESTION 3: How has lending volume changed year over year?
--
-- Depends on: sba_loans (00)
-- Data: SBA 504 FOIA (2009-2025)
-- Concept practiced: LAG() window function
--
-- COUNTERINTUITIVE HEADLINE: the brief assumed a "lending collapsed in
-- 2020" (7(a)) narrative. The actual 504 data shows the OPPOSITE -- 2020
-- was UP, and 2021 surged +55.2% (the biggest jump in the series). 504's
-- real-estate nature means low COVID-era rates BOOSTED it. Two movements:
--   1. Mid-decade structural slide 2013-2016 (309 -> 173, ~44% loss)
--   2. Rate-driven boom-bust: +55% in 2021, -36.5% by 2023 as rates rose
--
-- FRAMING DISCIPLINE -- pattern proven, cause inferred: the +55%/-36%
-- swings are proven in the data. The interest-rate explanation is an
-- informed inference (dataset has no rate data). State the pattern as
-- fact, the rate cause as the likely driver.
-- ============================================================
 
-- ------------------------------------------------------------
-- Calendar year via DATE_PART('year', approvaldate::date), NOT
-- approvalfiscalyear. The SBA fiscal year runs Oct-Sep, which would
-- misplace late-year loans; calendar year aligns the trend with
-- real-world events (Fed rate moves, COVID).
--
-- LAG(loan_count) OVER (ORDER BY loan_year) looks BACK one row to pull
-- the prior year's count into the current row, enabling YoY % change:
--     ((this year - prev year) / prev year) * 100
-- First year (2009) returns NULL for the change -- correct, no prior
-- year to compare. NULLIF guards a zero prior-year; 100.0 forces decimal.
--
-- NOTE: 2009 is a partial year (dataset starts mid-2009, only 75 loans) --
-- do not misread it as a real dip.
-- ------------------------------------------------------------
 
WITH yearly AS (
    SELECT
        DATE_PART('year', approvaldate::date) AS loan_year,
        COUNT(*) AS loan_count,
        ROUND(SUM(grossapproval::numeric), 0) AS total_approved
    FROM public.sba_loans
    WHERE borrstate = 'NY'
        AND approvaldate IS NOT NULL
        AND approvaldate != ''
    GROUP BY loan_year
)
SELECT
    loan_year,
    loan_count,
    total_approved,
    LAG(loan_count) OVER (ORDER BY loan_year) AS prev_year_count,
    ROUND(
        (loan_count - LAG(loan_count) OVER (ORDER BY loan_year))
        * 100.0 /
        NULLIF(LAG(loan_count) OVER (ORDER BY loan_year), 0)
    , 1) AS yoy_pct_change
FROM yearly
ORDER BY loan_year;
