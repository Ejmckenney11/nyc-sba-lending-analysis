-- ============================================================
-- 03_borough_per_capita.sql
-- QUESTION 1: Which NYC boroughs receive the fewest SBA loans per capita?
--
-- Depends on: sba_loans (00), borough_map view (01), census_population (02)
-- Data: SBA 504 FOIA (2009-2025), ACS 5-Year population (2019 baseline)
--
-- HEADLINE FINDING: The Bronx is the most underserved borough at 0.67
-- loans per 10k residents -- less than half Manhattan's 1.52. A Manhattan
-- resident is ~2.3x more likely to see a 504 loan in their zip than a
-- Bronx resident. Staten Island is second-most underserved (0.80).
-- ============================================================
 
-- ------------------------------------------------------------
-- CRITICAL STRUCTURE: loan counts and population are aggregated in
-- SEPARATE CTEs, then divided. Computing them in one joined query causes
-- a FAN-OUT JOIN -- each zip's population gets counted once PER LOAN
-- instead of once per zip, inflating population ~10x (Brooklyn showed
-- 25M instead of 2.6M). Aggregate each side independently, then divide.
--
-- Per-capita formula: (total loans / total population) * 10,000
--   * 10,000 is a readability scaler -- 504 loans are rare enough that
--     per-person gives tiny decimals (0.0000674). Per-10k -> clean 0.67.
--   * 10000.0 (the .0) forces DECIMAL division. Without it, integer
--     division rounds every result to 0 and the analysis silently breaks.
--   * NULLIF(pop, 0) prevents division-by-zero.
--
-- LIMITATION: population is the denominator. Ideal would be business
-- density (loans per business, not per resident). Population is a strong,
-- defensible proxy -- stated here as an assumption.
-- ------------------------------------------------------------
 
WITH loan_counts AS (
    -- One clean loan count per borough. No population here -> no fan-out.
    SELECT
        b.borough,
        COUNT(*) AS total_loans
    FROM public.sba_loans l
    JOIN borough_map b ON l.borrzip = b.zip
    WHERE l.borrstate = 'NY'
    GROUP BY b.borough
),
pop_totals AS (
    -- Population summed per borough, each zip counted exactly once
    -- (census joined to borough_map only, never to loans).
    SELECT
        b.borough,
        SUM(c.total_pop::integer) AS total_population
    FROM census_population c
    JOIN borough_map b ON RIGHT(c.geo_id, 5) = b.zip
    WHERE c.census_year = 2019
    GROUP BY b.borough
)
SELECT
    lc.borough,
    lc.total_loans,
    pt.total_population,
    ROUND(
        lc.total_loans * 10000.0 / NULLIF(pt.total_population, 0)
    , 2) AS loans_per_10k_residents
FROM loan_counts lc
JOIN pop_totals pt ON lc.borough = pt.borough
ORDER BY loans_per_10k_residents ASC;   -- most underserved first      ('10301', 'Staten Island'), ('10302', 'Staten Island'), ('10303', 'Staten Island'),
      ('10304', 'Staten Island'), ('10305', 'Staten Island'), ('10306', 'Staten Island'),
      ('10307', 'Staten Island'), ('10308', 'Staten Island'), ('10309', 'Staten Island'),
      ('10310', 'Staten Island'), ('10311', 'Staten Island'), ('10312', 'Staten Island'),
      ('10314', 'Staten Island')
  ) AS t(zip, borough)
)
SELECT
  b.borough,
  COUNT(*) AS total_loans,
  ROUND(AVG(l.grossapproval::numeric), 0) AS avg_loan_size,
  SUM(l.grossapproval::numeric) AS total_capital_deployed,
  ROUND(AVG(l.jobssupported::numeric), 1) AS avg_jobs_per_loan
FROM public.sba_loans l
JOIN borough_map b ON l.borrzip = b.zip
WHERE l.borrstate = 'NY'
GROUP BY b.borough
ORDER BY total_loans DESC;
