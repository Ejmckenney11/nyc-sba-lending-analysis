-- ============================================================
-- 06_lender_concentration.sql
-- QUESTION 4: Which lenders dominate NYC lending, and are they concentrated?
--
-- Depends on: sba_loans (00), borough_map view (01)
-- Data: SBA 504 FOIA (2009-2025)
-- Concepts practiced: SUM(COUNT(*)) OVER () market share, RANK() by borough
--
-- 504 loans have TWO distinct "lender" fields, analyzed separately:
--   cdc_name              -- Certified Development Company (admins, puts up 40%)
--   thirdpartylender_name -- conventional bank (puts up 50%)
-- They tell different competitive stories.
--
-- HEADLINE TWO-LAYER FINDING: NYC 504 lending is concentrated at the
-- ADMINISTRATION layer (one CDC, Empire State, controls 83.3% -- a
-- near-monopoly, 14x the next competitor) but COMPETITIVE at the CAPITAL
-- layer (top bank JPMorgan Chase holds only 11.6%; dozens split the rest).
-- The fintech opportunity isn't to be bank #31 fighting for 2% -- it's to
-- challenge the concentrated intermediary layer facing almost no competition.
-- ============================================================
 
 
-- ------------------------------------------------------------
-- 4.1  CDC layer -- market share (the near-monopoly)
-- Empire State Certified Development Corp = 83.3% of all NYC 504 loans.
-- Not the "3 banks control 60%" oligopoly the brief imagined.
-- ------------------------------------------------------------
SELECT
    cdc_name,
    COUNT(*) AS loans_made,
    ROUND(SUM(grossapproval::numeric), 0) AS total_capital,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_market
FROM public.sba_loans
WHERE borrstate = 'NY'
    AND cdc_name IS NOT NULL
    AND cdc_name != ''
GROUP BY cdc_name
ORDER BY loans_made DESC
LIMIT 10;
 
 
-- ------------------------------------------------------------
-- 4.2  Bank layer -- market share (fragmented and competitive)
-- Top bank holds only 11.6%; it takes ~8 banks combined to match Empire
-- State's single share. This contrast IS the story.
-- ------------------------------------------------------------
SELECT
    thirdpartylender_name,
    COUNT(*) AS loans_made,
    ROUND(SUM(grossapproval::numeric), 0) AS total_capital,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_market
FROM public.sba_loans
WHERE borrstate = 'NY'
    AND thirdpartylender_name IS NOT NULL
    AND thirdpartylender_name != ''
GROUP BY thirdpartylender_name
ORDER BY loans_made DESC
LIMIT 10;
 
 
-- ------------------------------------------------------------
-- 4.3  Top 5 banks per borough (RANK window function)
-- RANK() OVER (PARTITION BY borough ORDER BY COUNT(*) DESC): PARTITION BY
-- restarts the ranking for each borough, so every borough gets its own
-- 1-2-3. WHERE rank <= 5 yields top-5-per-borough.
--
-- FINDING: Chase leads/ties #1 in Bronx, Brooklyn, Manhattan, Queens.
-- Local players break through (Webster in Bronx; Flushing/Dime in
-- Brooklyn/Queens; Empire State Bank leads Staten Island). Underserved
-- boroughs have the THINNEST competition -- Bronx #1 bank has just 13
-- loans (vs 69 in Brooklyn), Staten Island's #1 has 6. Ties back to Q1:
-- fewer loans AND fewer active lenders = least resistance for a new entrant.
-- ------------------------------------------------------------
WITH lender_borough AS (
    SELECT
        b.borough,
        l.thirdpartylender_name,
        COUNT(*) AS loans_made,
        ROUND(SUM(l.grossapproval::numeric), 0) AS capital_deployed,
        RANK() OVER (
            PARTITION BY b.borough
            ORDER BY COUNT(*) DESC
        ) AS rank_in_borough
    FROM public.sba_loans l
    JOIN borough_map b ON l.borrzip = b.zip
    WHERE l.borrstate = 'NY'
        AND l.thirdpartylender_name IS NOT NULL
        AND l.thirdpartylender_name != ''
    GROUP BY b.borough, l.thirdpartylender_name
)
SELECT *
FROM lender_borough
WHERE rank_in_borough <= 5
ORDER BY borough, rank_in_borough;
