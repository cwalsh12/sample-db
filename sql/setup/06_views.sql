-- 06_views.sql
-- Views are saved queries. They store no data; they run against fact_pickups
-- every time someone reads them, so they are always up to date.
-- In Superset, each view can be added as a dataset.

-- Total and average weight per month for each bin type (valid rows only)
CREATE OR REPLACE VIEW analytics.v_monthly_weight_by_bin_type AS
SELECT
    date_trunc('month', f.pickup_at)::date  AS month,
    f.bin_type,
    count(*)                                AS pickups,
    sum(f.weight_lbs)                       AS total_weight_lbs,
    round(avg(f.weight_lbs), 2)             AS avg_weight_lbs
FROM analytics.fact_pickups AS f
WHERE f.is_valid
GROUP BY 1, 2;

-- Pickups per bin size, with size_rank so charts sort small -> medium -> large
CREATE OR REPLACE VIEW analytics.v_pickups_by_bin_size AS
SELECT
    s.bin_size,
    s.size_rank,
    count(f.pickup_id)           AS pickups,
    round(avg(f.weight_lbs), 2)  AS avg_weight_lbs
FROM analytics.dim_bin_size AS s
LEFT JOIN analytics.fact_pickups AS f
    ON f.bin_size = s.bin_size AND f.is_valid
GROUP BY s.bin_size, s.size_rank;

-- How many rows broke each business rule
CREATE OR REPLACE VIEW analytics.v_data_quality AS
SELECT
    coalesce(f.invalid_reason, 'valid')                    AS status,
    count(*)                                               AS row_count,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1)     AS pct_of_rows
FROM analytics.fact_pickups AS f
GROUP BY 1;
