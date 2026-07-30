-- ============================================================
-- 04_loan_characteristics.sql
-- QUESTION 2: What business/loan characteristics correlate with outcomes?
--
-- Depends on: sba_loans (00), borough_map view (01)
-- Data: SBA 504 FOIA (2009-2025)
--
-- Approached in two parts:
--   PART 1 -- the lending landscape (strong data)
--   PART 2 -- the charge-off risk signal (thin data, directional only)
--
-- HEADLINE TWO-VARIABLE INSIGHT: the Bronx is the most underserved
-- borough per capita (Q1) AND its loans support the most jobs per loan
-- (13.3, above Manhattan's 10.2). Underservice there is not just an
-- equity gap -- it is a missed economic-impact opportunity.
-- ============================================================
 
 
-- ------------------------------------------------------------
-- 2.0  THE OUTCOME VARIABLE -- loanstatus distribution
-- Establishes the baseline. EXEMPT (50%) = active loans withheld under
-- FOIA Exemption 4. Only 1.3% charged off -- itself a finding: 504 loans
-- are collateral-backed and inherently low-risk.
-- SUM(COUNT(*)) OVER () = grand total as denominator on every row.
-- ------------------------------------------------------------
SELECT
    loanstatus,
    COUNT(*) AS loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM public.sba_loans
WHERE borrstate = 'NY'
GROUP BY loanstatus
ORDER BY loan_count DESC;
 
 
-- ------------------------------------------------------------
-- 2.1  PART 1 -- Industry concentration (top 15 by loan volume)
-- Restaurants dominate by VOLUME (232) but are small-ticket ($704K).
-- Hotels dominate by CAPITAL ($370M) despite fewer loans -- real-estate
-- heavy, a perfect fit for the 504 fixed-asset purpose. The landscape
-- splits into high-volume small-ticket vs low-volume large-ticket.
-- ::numeric casts required -- money columns loaded as VARCHAR.
-- ------------------------------------------------------------
SELECT
    naicsdescription,
    COUNT(*) AS loan_count,
    ROUND(AVG(grossapproval::numeric), 0) AS avg_loan_size,
    ROUND(SUM(grossapproval::numeric), 0) AS total_capital
FROM public.sba_loans
WHERE borrstate = 'NY'
    AND naicsdescription IS NOT NULL
    AND naicsdescription != ''
GROUP BY naicsdescription
ORDER BY loan_count DESC
LIMIT 15;
 
 
-- ------------------------------------------------------------
-- 2.2  PART 1 -- Business type
-- 96.8% of NYC 504 borrowers are corporations. NOT a strong
-- differentiator (one category dominates) -> a one-line supporting fact,
-- not a chart. Reinforces that 504 serves established businesses.
-- ------------------------------------------------------------
SELECT
    businesstype,
    COUNT(*) AS loan_count,
    ROUND(AVG(grossapproval::numeric), 0) AS avg_loan_size,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_loans
FROM public.sba_loans
WHERE borrstate = 'NY'
    AND businesstype IS NOT NULL
    AND businesstype != ''
GROUP BY businesstype
ORDER BY loan_count DESC;
 
 
-- ------------------------------------------------------------
-- 2.3  PART 1 -- Loan size & impact by borough
-- Avg loan size is FLAT across boroughs ($1.25M-$1.50M) -> the Bronx's
-- underservice is about loan COUNT, not loan SIZE. The standout: the
-- Bronx leads in jobs supported per loan (13.3). Loans in underserved
-- boroughs support MORE jobs.
-- ------------------------------------------------------------
SELECT
    b.borough,
    COUNT(*) AS loan_count,
    ROUND(AVG(l.grossapproval::numeric), 0) AS avg_loan_size,
    ROUND(SUM(l.grossapproval::numeric), 0) AS total_capital,
    ROUND(AVG(l.jobssupported::numeric), 1) AS avg_jobs_supported
FROM public.sba_loans l
JOIN borough_map b ON l.borrzip = b.zip
WHERE l.borrstate = 'NY'
GROUP BY b.borough
ORDER BY total_capital DESC;
 
 
-- ------------------------------------------------------------
-- 2.4  PART 2 -- The charge-off risk signal (DIRECTIONAL ONLY)
-- Compares resolved outcomes: PIF (paid in full) vs CHGOFF (charged off).
-- Charged-off loans were SMALLER ($715K vs $900K) and supported FEWER
-- jobs (8.6 vs 10.9). Term length nearly identical -> not a differentiator.
--
-- CRITICAL CAVEAT: only 51 charge-offs. This is a DIRECTIONAL SIGNAL,
-- NOT a statistical conclusion. Honest framing: "charge-offs skewed
-- toward smaller, lower-job-count loans -- a pattern worth investigating
-- with a larger sample." Never overclaim on 51 data points.
-- ------------------------------------------------------------
SELECT
    loanstatus,
    COUNT(*) AS loan_count,
    ROUND(AVG(grossapproval::numeric), 0) AS avg_loan_size,
    ROUND(AVG(jobssupported::numeric), 1) AS avg_jobs,
    ROUND(AVG(terminmonths::numeric), 0) AS avg_term_months
FROM public.sba_loans
WHERE borrstate = 'NY'
    AND loanstatus IN ('PIF', 'CHGOFF')
GROUP BY loanstatus;
