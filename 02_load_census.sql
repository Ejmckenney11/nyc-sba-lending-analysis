-- ============================================================
-- 02_load_census.sql
-- Creates and loads the census_population table (per-capita denominator for Q1).
--
-- Data source: U.S. Census Bureau, American Community Survey (ACS)
--   5-Year Estimates, Table B01003 (Total Population)
--   Download: https://data.census.gov  -> search "B01003"
--   Geography: Zip Code Tabulation Areas (ZCTA), New York State
--
-- Three years loaded so loans can be matched to a nearby population year:
--   2014 ACS -> early loans | 2019 ACS -> mid | 2023 ACS -> recent
--   (The analysis currently anchors to 2019 as a single baseline; the
--    other two are loaded so a multi-year match can be added later.)
--
-- Depends on: nothing. Run AFTER 00, before Q1 (03).
-- ============================================================
 
-- ------------------------------------------------------------
-- Two quirks in the raw ACS CSV that this schema handles:
--
--   1. TRAILING COMMA: every row ends with a comma, creating a phantom
--      5th column. The `dummy` column absorbs it so COPY doesn't throw
--      "extra data after last expected column".
--
--   2. LABEL ROW: row 2 of each file is a second header ("Geographic
--      Area Name", "Estimate!!Total", ...). It loads as a data row and
--      is deleted at the end. Columns are widened to VARCHAR(50) so that
--      long label text doesn't overflow during load.
--
-- The zip lives inside GEO_ID (e.g. 8600000US10001 or 860Z200US10001 --
-- the prefix differs between older and newer files). RIGHT(geo_id, 5)
-- extracts the 5-digit zip regardless of prefix; that happens in Q1.
-- ------------------------------------------------------------
 
DROP TABLE IF EXISTS census_population;
 
CREATE TABLE census_population (
    geo_id          VARCHAR(50),
    name            VARCHAR(100),
    total_pop       VARCHAR(50),
    margin_of_error VARCHAR(50),
    dummy           VARCHAR(10),   -- absorbs the trailing-comma phantom column
    census_year     INTEGER
);
 
-- ------------------------------------------------------------
-- Load each file at the psql prompt with \copy, then tag its year.
-- Run these pairs one at a time. Update paths to your machine.
-- Column list is explicit (5 cols) so census_year stays NULL until tagged.
-- ------------------------------------------------------------
 
-- 2014:
-- \copy census_population (geo_id, name, total_pop, margin_of_error, dummy) FROM '/path/to/ACSDT5Y2014.B01003-Data.csv' DELIMITER ',' CSV HEADER;
-- UPDATE census_population SET census_year = 2014 WHERE census_year IS NULL;
 
-- 2019:
-- \copy census_population (geo_id, name, total_pop, margin_of_error, dummy) FROM '/path/to/ACSDT5Y2019.B01003-Data.csv' DELIMITER ',' CSV HEADER;
-- UPDATE census_population SET census_year = 2019 WHERE census_year IS NULL;
 
-- 2023:
-- \copy census_population (geo_id, name, total_pop, margin_of_error, dummy) FROM '/path/to/ACSDT5Y2023.B01003-Data.csv' DELIMITER ',' CSV HEADER;
-- UPDATE census_population SET census_year = 2023 WHERE census_year IS NULL;
 
-- Remove the label row that loaded as data from each file:
DELETE FROM census_population WHERE geo_id = 'Geography';
 
-- Verify: expect three years, ~1,795-1,825 zips each.
SELECT census_year, COUNT(*) AS zip_count
FROM census_population
GROUP BY census_year
ORDER BY census_year;
