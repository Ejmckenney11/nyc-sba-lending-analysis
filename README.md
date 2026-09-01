# NYC SBA 504 Lending Analysis

**Where should a fintech expand its small business lending product in New York City — and where do traditional lenders leave the most room?**

This project analyzes ~3,800 SBA 504 loans across NYC (2009–2025), joined to U.S. Census population data, to identify which boroughs and zip codes are most underserved, how lending has shifted over time, and how concentrated the competitive landscape is. The output is a recommendation a product or strategy team could act on — not a list of observations.

**[View the interactive dashboard on Tableau Public →](https://public.tableau.com/views/ProjectManhattan/PJM1Dashboard?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link)**

---

## Key findings

1. **The Bronx and Staten Island are the most underserved boroughs per capita.** The Bronx receives just 0.67 SBA 504 loans per 10,000 residents — less than half Manhattan's 1.52. Yet Bronx loans support the *most* jobs per loan (13.3 vs Manhattan's 10.2), making it both underfunded and high-impact.

2. **Interest rates, not COVID, drove NYC 504 lending.** Contrary to the usual "lending collapsed in 2020" narrative, 504 lending *surged* 55% in the 2021 low-rate boom, then corrected 36% by 2023 as rates rose — with an earlier, slower structural decline from 2013–2016.

3. **One CDC controls 83% of the market.** A single Certified Development Company (Empire State) administers 83.3% of NYC 504 loans, while the conventional-bank capital layer stays fragmented (top bank: 11.6%). The concentration a new entrant can challenge sits at the intermediary layer, not the capital layer.

**Bottom line:** A fintech entering NYC should prioritize the Bronx and Staten Island — most underserved, highest economic impact per loan, and least contested by incumbents.

---

## Important data note — this is 504, not 7(a) data

This analysis uses the SBA **504** loan program, not the 7(a) program. The two behave differently:

- **504 loans** finance fixed assets (real estate, buildings, equipment) at below-market rates, backed by collateral and split across three parties (borrower 10%, conventional lender 50%, Certified Development Company 40%).
- Because they are collateral-backed, 504 loans default far less often than working-capital 7(a) loans — which is why this dataset shows a ~1.3% charge-off rate.
- The program tracks two lender types (the administering CDC and the third-party bank), which shapes the competitive analysis in Question 4.

---

## The five questions this project answers

| # | Question | SQL file |
|---|----------|----------|
| 1 | Which NYC boroughs receive the fewest 504 loans per capita? | `03_borough_per_capita.sql` |
| 2 | What business and loan characteristics correlate with outcomes? | `04_loan_characteristics.sql` |
| 3 | How has lending volume and loan size changed year over year? | `05_yoy_trend.sql` |
| 4 | Which lenders dominate NYC lending, and are they concentrated? | `06_lender_concentration.sql` |
| 5 | Which Bronx & Staten Island zips should be targeted most? *(self-initiated)* | `07_zip_target_score.sql` |

---

## Data sources

| Dataset | Source | Notes |
|---------|--------|-------|
| SBA 504 loans | [data.sba.gov](https://data.sba.gov) → "7(a) & 504 FOIA Data" | `foia-504-fy2010-present-asof-251231.csv` (~51MB). Free, no account. |
| NYC population | [data.census.gov](https://data.census.gov) → Table B01003 | ACS 5-Year estimates (2014, 2019, 2023), ZCTA geography, New York State. |

CSV files are **not** committed to this repo (see `/data/README.md` for download instructions). Only code and documentation are version-controlled.

---

## How to reproduce this analysis

**Environment:** PostgreSQL + a SQL client (DBeaver used here). All queries are PostgreSQL.

Run the SQL files in numeric order — the prefixes encode the dependency chain:

```
/sql
  00_create_table.sql              -- schema + CSV load instructions (run first)
  01_create_borough_map.sql        -- borough lookup VIEW (needed by all analysis)
  02_load_census.sql               -- census population tables (needed by Q1)
  03_borough_per_capita.sql        -- Q1
  04_loan_characteristics.sql      -- Q2
  05_yoy_trend.sql                 -- Q3
  06_lender_concentration.sql      -- Q4
  07_zip_target_score.sql          -- Q5
```

**Setup notes:**
- All columns load as `VARCHAR` deliberately (the raw CSV has mixed formats and braces). Numeric/date values are cast at query time with `::numeric` / `::date`.
- Use psql's `\copy` (not `COPY`) to load CSVs on a local install — the server process often can't read files in your home folder.
- `01` and `02` must run before any analysis query — the analysis joins against the `borough_map` view and `census_population` table.

A technical reviewer should be able to reproduce the full analysis in under 30 minutes.

---

## Repo structure

```
nyc-sba-lending-analysis/
  /sql        -- all analysis queries, numbered in run order
  /data       -- README with download instructions (no CSVs committed)
  /tableau    -- dashboard screenshots
  /docs        -- executive summary + insight notes
  README.md   -- this file
```

---

## Methodology & limitations

This project names its own assumptions — a deliberate practice:

- **Per-capita denominator (Q1):** population is used, not business density. Population is a defensible proxy, but loans-per-business would be the ideal measure.
- **Charge-off signal (Q2):** based on only 51 charge-offs — a *directional* signal, not a statistical conclusion.
- **Rate attribution (Q3):** the +55%/−36% pattern is proven in the data; the interest-rate cause is an informed inference (the dataset contains no rate data).
- **2009 excluded from the trend (Q3):** partial year (dataset begins mid-2009) makes its year-over-year comparison invalid.
- **Blended target score (Q5):** uses stated weights (35/35/20/10) and two principled exclusions (low-population zips, extreme job-impact outliers). Top zips carry a 2–3 loan thin-data caveat.

---

## Analysis & author

Full working notes with every finding, formula, and caveat are in [`/docs/insight_notes.md`](docs/insight_notes.md).

**Elijah McKenney** · [GitHub](https://github.com/Ejmckenney11/nyc-sba-lending-analysis)
Data: SBA 504 FOIA (2009–2025) & U.S. Census ACS 5-Year estimates.
