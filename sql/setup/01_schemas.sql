-- 01_schemas.sql
-- Creates the three layers of the pipeline. A schema is a folder for tables.
--   raw       = data exactly as it arrived (every column is text)
--   staging   = cleaned and typed by Python (etl/transform.py)
--   analytics = shaped for reporting; the only schema Superset can read

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA raw       IS 'Untouched copies of source files';
COMMENT ON SCHEMA staging   IS 'Cleaned, typed, validated data';
COMMENT ON SCHEMA analytics IS 'Reporting tables and views for Superset';
