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
),
lender_borough AS (
  SELECT
    b.borough,
    l.thirdpartylender_name,
    COUNT(*) AS loans_made,
    SUM(l.grossapproval::numeric) AS capital_deployed,
    RANK() OVER (
      PARTITION BY b.borough
      ORDER BY COUNT(*) DESC
    ) AS rank_in_borough
  FROM public.sba_loans l
  JOIN borough_map b ON l.borrzip = b.zip
  GROUP BY b.borough, l.thirdpartylender_name
)
SELECT *
FROM lender_borough
WHERE rank_in_borough <= 5
ORDER BY borough, rank_in_borough;
