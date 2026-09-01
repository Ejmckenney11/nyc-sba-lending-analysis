# Data — download instructions

The CSV files for this project are **not committed** to the repo. They are large (~50MB+), publicly available, and not mine to redistribute. This README tells you exactly what to download and where it goes so the SQL in `/sql` runs against the same data used in the analysis.

---

## 1. SBA 504 loan data (primary dataset)

- **Where:** [data.sba.gov](https://data.sba.gov) → search **"7(a) & 504 FOIA Data"**
- **File:** the 504 file — `foia-504-fy2010-present-asof-251231.csv` (~51MB unzipped)
- **Cost:** free, no account required
- **Note:** This project uses the **504** program (fixed-asset / real-estate loans), *not* 7(a). Make sure you download the 504 file.

Load it with `/sql/00_create_table.sql`, which contains the table schema and the `\copy` load command.

---

## 2. NYC population data (for per-capita analysis)

- **Where:** [data.census.gov](https://data.census.gov) → search **"B01003"** (Total Population)
- **Table:** B01003, American Community Survey **5-Year Estimates**
- **Geography:** Zip Code Tabulation Areas (ZCTA), New York State
- **Years needed:** 2014, 2019, and 2023 (three separate downloads)

Each download arrives as a zipped folder; the file you need is the one ending in **`.B01003-Data.csv`**. Load all three with `/sql/02_load_census.sql`, which tags each with its census year.

> **Heads-up on the census files:** each row has a trailing comma (creating a phantom column) and a second label row after the header. The load script in `02_load_census.sql` handles both — don't strip them manually.

---

## Where files should live

The SQL load commands use `\copy` with a file path you provide. Put the CSVs anywhere stable (a `data/raw/` folder outside version control is ideal) and update the paths in the load scripts to match. **Do not** move them after loading if you plan to re-run — broken paths are the most common load error.

---

## Query outputs (for Tableau)

The `/data/outputs` folder holds the CSV exports each analysis query produces (exported from DBeaver: right-click result grid → Export Data → CSV). These feed the Tableau dashboard:

| Export | Source query | Dashboard chart |
|--------|-------------|-----------------|
| `chart1_borough_per_capita.csv` | `03b_borough_per_capita_mapready.sql` | Borough loan density (map) |
| `chart2_yoy_trend.csv` | `05_yoy_trend.sql` | Year-over-year trend |
| `chart3_cdc_concentration.csv` | `06_lender_concentration.sql` (CDC layer) | Lender concentration |

These small output CSVs *may* be committed if you want the dashboard reproducible without re-running the queries — they're tiny. The large raw source files above should never be committed.
