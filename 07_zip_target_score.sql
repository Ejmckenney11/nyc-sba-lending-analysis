-- ============================================================
-- 07_zip_target_score.sql
-- QUESTION 5 (self-initiated): Which Bronx & Staten Island zips should
-- a fintech target most, based on the collective answer from Q1-Q4?
--
-- Depends on: sba_loans (00), borough_map view (01), census_population (02)
-- Data: SBA 504 FOIA (2009-2025), ACS 5-Year population (2019)
--
-- Goes beyond the brief's four questions. Q1-Q4 establish WHICH boroughs
-- to target; Q5 drills to WHICH zip codes -- turning diagnosis into an
-- actionable go-to-market target list.
--
-- RESULT: the Bronx takes the entire top five (10453, 10455, 10470,
-- 10468, 10460); top Staten Island zip is 10303 at rank 6. Consistent
-- with all four prior questions.
--
-- HONEST WEAKNESS (must state): the top zips have only 2-3 loans each,
-- right at the demand floor. Job-impact figures are averages over 2-3
-- loans -> directional, could be driven by one large project. A real
-- go-to-market plan would validate with external data first. Same
-- small-sample discipline as the 51 charge-offs in Q2.
-- ============================================================
 
-- ------------------------------------------------------------
-- METHOD -- a transparent BLENDED SCORE.
-- Four component signals (one per prior question) are min-max normalized
-- to a 0-1 scale and combined into a weighted target_score.
--
-- Min-max normalization: (value - min) / (max - min). Rescales metrics
-- on different scales (loans/10k ~0.2-3 vs jobs/loan ~3-32) so each
-- contributes equally. For "lower is better" metrics, invert: 1 - normalized.
--
-- WEIGHTS (a STATED ASSUMPTION, documented so the score isn't a black box;
-- changing them changes the ranking):
--   Underservice 35% + Job impact 35%  (the two headline findings lead)
--   Low competition 20% + Demand proof 10%  (supporting signals)
--
-- STATED DESIGN CHOICES:
--   * Minimum 2 loans/zip -> target proven demand, not empty zips.
--   * Two PRINCIPLED exclusions (data-validity, not cherry-picking):
--       - population < 15,000  -> unreliable per-capita denominator
--         (drops industrial zips like Hunts Point 10474, City Island 10464)
--       - avg_jobs >= 40       -> fragile small-sample outliers
--         (drops 10473, 10461 at ~52-53 jobs/loan over 2-5 loans)
-- ------------------------------------------------------------
 
WITH zip_loans AS (
    SELECT
        b.borough,
        l.borrzip AS zip,
        COUNT(*) AS loan_count,
        ROUND(AVG(l.jobssupported::numeric), 1) AS avg_jobs,
        COUNT(DISTINCT l.thirdpartylender_name) AS lender_count,   -- Q4 competition signal
        COUNT(*) FILTER (                                          -- Q3 recency signal
            WHERE DATE_PART('year', l.approvaldate::date) >= 2020
        ) AS recent_loans
    FROM public.sba_loans l
    JOIN borough_map b ON l.borrzip = b.zip
    WHERE l.borrstate = 'NY'
        AND b.borough IN ('Bronx', 'Staten Island')
        AND l.approvaldate IS NOT NULL
        AND l.approvaldate != ''
    GROUP BY b.borough, l.borrzip
    HAVING COUNT(*) >= 2                                            -- proven-demand floor
),
zip_pop AS (
    SELECT
        RIGHT(geo_id, 5) AS zip,
        total_pop::integer AS population
    FROM census_population
    WHERE census_year = 2019
),
base AS (
    SELECT
        zl.borough,
        zl.zip,
        zl.loan_count,
        zp.population,
        ROUND(zl.loan_count * 10000.0 / NULLIF(zp.population, 0), 2) AS loans_per_10k,
        zl.avg_jobs,
        zl.lender_count,
        zl.recent_loans
    FROM zip_loans zl
    JOIN zip_pop zp ON zl.zip = zp.zip
    WHERE zp.population >= 15000    -- EXCLUSION 1: unreliable per-capita denominator
      AND zl.avg_jobs < 40         -- EXCLUSION 2: fragile small-sample outliers
),
bounds AS (
    -- Global min/max per metric -- the range each metric is normalized against.
    SELECT
        MIN(loans_per_10k) AS min_und, MAX(loans_per_10k) AS max_und,
        MIN(avg_jobs)      AS min_job, MAX(avg_jobs)      AS max_job,
        MIN(lender_count)  AS min_lend, MAX(lender_count) AS max_lend,
        MIN(recent_loans)  AS min_rec, MAX(recent_loans)  AS max_rec
    FROM base
)
SELECT
    b.borough,
    b.zip,
    b.loan_count,
    b.population,
    b.loans_per_10k,
    b.avg_jobs,
    b.lender_count,
    b.recent_loans,
    ROUND(
        -- Underservice 35% -- INVERTED (lower loans/10k = better target)
        0.35 * (1 - (b.loans_per_10k - bd.min_und) / NULLIF(bd.max_und - bd.min_und, 0))
        -- Job impact 35% -- higher = better
      + 0.35 * ((b.avg_jobs - bd.min_job) / NULLIF(bd.max_job - bd.min_job, 0))
        -- Low competition 20% -- INVERTED (fewer lenders = better target)
      + 0.20 * (1 - (b.lender_count - bd.min_lend) / NULLIF(bd.max_lend - bd.min_lend, 0))
        -- Demand proof 10% -- more recent loans = better
      + 0.10 * ((b.recent_loans - bd.min_rec) / NULLIF(bd.max_rec - bd.min_rec, 0))
    , 3) AS target_score
FROM base b
CROSS JOIN bounds bd    -- one-row bounds table attached to every row for the math
ORDER BY target_score DESC;
