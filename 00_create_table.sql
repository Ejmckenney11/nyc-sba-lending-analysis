-- ============================================================
-- 00_create_table.sql
-- Creates the main sba_loans table and loads the SBA 504 CSV.
--
-- Data source: SBA 504 FOIA data (2009-2025)
--   Download: https://data.sba.gov  -> search "7(a) & 504 FOIA Data"
--   File used: foia-504-fy2010-present-asof-251231.csv (~51MB)
--
-- IMPORTANT: This project uses the SBA *504* program, not 7(a).
--   504 loans finance fixed assets (real estate, equipment) and are
--   collateral-backed, which is why charge-offs are rare (~1.3%).
--
-- Run order: THIS FILE FIRST, then 01, then 02, then the analysis queries.
-- ============================================================
 
-- ------------------------------------------------------------
-- Design note: every column is VARCHAR on purpose.
-- The raw CSV contains currency/number fields with mixed formats
-- and values wrapped in braces (e.g. {504}, {865000}). Loading
-- everything as text gets the data in without type-rejection errors.
-- Numeric/date columns are CAST at query time with ::numeric / ::date.
-- This is standard practice: load raw, clean/cast downstream.
--
-- Widths chosen from real errors hit during load:
--   borrname was bumped to 500 because some borrower names are long
--   legal ownership strings (e.g. "...as to an undivided 19% interest").
-- ------------------------------------------------------------
 
DROP TABLE IF EXISTS sba_loans;
 
CREATE TABLE sba_loans (
    asofdate                VARCHAR(20),
    program                 VARCHAR(20),
    l2locid                 VARCHAR(20),
    borrname                VARCHAR(500),   -- widened: long legal ownership strings
    borrstreet              VARCHAR(200),
    borrcity                VARCHAR(100),
    borrstate               VARCHAR(10),
    borrzip                 VARCHAR(20),
    cdc_name                VARCHAR(200),
    cdc_street              VARCHAR(200),
    cdc_city                VARCHAR(100),
    cdc_state               VARCHAR(10),
    cdc_zip                 VARCHAR(20),
    thirdpartylender_name   VARCHAR(200),
    thirdpartylender_city   VARCHAR(100),
    thirdpartylender_state  VARCHAR(10),
    thirdpartydollars       VARCHAR(20),
    grossapproval           VARCHAR(20),
    approvaldate            VARCHAR(20),
    approvalfiscalyear      VARCHAR(10),
    firstdisbursementdate   VARCHAR(20),
    processingmethod        VARCHAR(100),
    deliverymethod          VARCHAR(100),
    subprogram              VARCHAR(200),
    terminmonths            VARCHAR(20),
    naicscode               VARCHAR(20),
    naicsdescription        VARCHAR(200),
    franchisecode           VARCHAR(20),
    franchisename           VARCHAR(200),
    projectcounty           VARCHAR(100),
    projectstate            VARCHAR(10),
    sbadistrictoffice       VARCHAR(100),
    congressionaldistrict   VARCHAR(20),
    businesstype            VARCHAR(100),
    businessage             VARCHAR(100),
    loanstatus              VARCHAR(50),
    paidinfulldate          VARCHAR(20),
    chargeoffdate           VARCHAR(20),
    grosschargeoffamount    VARCHAR(20),
    jobssupported           VARCHAR(20),
    collateralind           VARCHAR(10)
);
 
-- ------------------------------------------------------------
-- Load the CSV.
--
-- Use \copy (psql client command), NOT COPY. On a conda/local
-- Postgres install the server process often can't read files in
-- your home/Downloads folder; \copy streams through the client,
-- which has your user's file access. Update the path to yours.
--
-- Run this line at the psql prompt (all one line):
--
-- \copy sba_loans FROM '/path/to/foia-504-fy2010-present-asof-251231.csv' DELIMITER ',' CSV HEADER;
--
-- Expected result: COPY 114511
-- ------------------------------------------------------------
 
-- Sanity check after loading:
SELECT COUNT(*) AS total_rows,
       MIN(approvaldate::date) AS earliest_loan,
       MAX(approvaldate::date) AS latest_loan
FROM sba_loans
WHERE borrstate = 'NY';
