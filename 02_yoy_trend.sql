WITH yearly AS (
  SELECT
    DATE_PART('year', approvaldate::date) AS loan_year,
    COUNT(*) AS loan_count,
    SUM(grossapproval::numeric) AS total_approved
  FROM public.sba_loans
  WHERE borrstate = 'NY'
    AND borrzip BETWEEN '10001' AND '11697'
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
