WITH borough_map AS (
  SELECT zip, borough
  FROM (
    VALUES
      ('10001', 'Manhattan'), ('10002', 'Manhattan'),
      ('11201', 'Brooklyn'),  ('11203', 'Brooklyn'),
      ('10451', 'Bronx'),     ('10452', 'Bronx'),
      ('11101', 'Queens'),    ('11102', 'Queens'),
      ('10301', 'Staten Island')
  ) AS t(zip, borough)
)
SELECT
  b.borough,
  l.loanstatus,
  COUNT(*) AS loan_count,
  ROUND(
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY b.borough)
  , 1) AS pct_of_borough_loans,
  ROUND(AVG(l.grossapproval::numeric), 0) AS avg_loan_size
FROM public.sba_loans l
JOIN borough_map b ON l.borrzip = b.zip
WHERE l.loanstatus IN ('P', 'CHGOFF', 'PIF', 'C')
GROUP BY b.borough, l.loanstatus
ORDER BY b.borough, loan_count DESC;
