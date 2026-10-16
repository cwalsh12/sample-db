# Data Dictionary: Bin Pickups (MOCK_DATA.csv)

## Overview

| Item | Value |
|---|---|
| Source | Mockaroo (generated fake data) |
| File | `data/MOCK_DATA.csv` |
| Rows | 1,000 (plus header) |
| Date range | 2022-01-01 to 2022-12-30 |
| Grain (what one row means) | **One pickup of one bin**: a bin, its weight, and when/where it was collected |
| Contains personal data? | No (street addresses are fake and have no names attached) |

## Columns

| # | CSV column | Target column | Raw type | Target type | Example | Blanks | Allowed values / rules | Problems found | Cleaning action |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `bin_id` | `bin_id` | text | `integer` (nullable) | `1` | 29 (2.9%) | Positive whole number | 29 rows have no id. The non-blank ids are all unique, so each bin appears only once; this acts like a **pickup id**, not a bin id | Keep as nullable. Generate a separate `pickup_id` as the primary key. Flag rows with no `bin_id` |
| 2 | `weight` | `weight_lbs` | text | `numeric(6,2)` | `93.8` | 0 | Greater than 0 | Range 0.11–99.71. **Unit not stated** (assumed lbs) | Cast to number. `CHECK (weight_lbs > 0)` |
| 3 | `bin_type` | `bin_type` | text | `text` | `compost` | 0 | `waste`, `compost`, `recycling` | Clean, but conflicts with `waste_category` (see below) | Lowercase + trim. `CHECK` against the allowed list |
| 4 | `location` | `location` | text | `text` (nullable) | `0857 Susan Lane` | 53 (5.3%) | Street address | Street only: no city, state, or zip | Trim. Blank → `NULL`. Show as `Unknown` in analytics |
| 5 | `pickup_date` | *(combined into `pickup_at`)* | text | `date` | `3/21/2022` | 0 | Valid date | US format `M/D/YYYY`, no leading zeros | Parse with format `MM/DD/YYYY` |
| 6 | `pickup_time` | *(combined into `pickup_at`)* | text | `time` | `8:58 PM` | 0 | Valid 12-hour time | 12-hour clock with AM/PM. **Time zone not stated** | Parse, then combine with date into `pickup_at` (`timestamp`) |
| 7 | `recycling_type` | `material` | text | `text` | `plastic` | 0 | `paper`, `plastic`, `glass`, `metal` | Filled in for **every** bin type, including waste and compost bins | Lowercase + trim. Renamed to `material`. Set to `NULL` for non-recycling bins (business rule 3) |
| 8 | `waste_category` | `waste_category` | text | `text` | `food waste` | 0 | `non-recyclable`, `food waste`, `hazardous waste` | Conflicts with `bin_type` (see below) | Lowercase + trim. `CHECK` against the allowed list |
| 9 | `recycling_bin_color` | `bin_color_hex` | text | `char(7)` (nullable) | `#1957d1` | 54 (5.4%) | `#` + 6 hex digits | Random colors, almost all unique. Probably not useful for analysis | Keep in staging. Leave out of analytics |
| 10 | `recycling_bin_size` | `bin_size` | text | `text` | `large` | 0 | `small`, `medium`, `large` | Alphabetical sort gives the wrong order (large, medium, small) | Sort order (1=small, 2=medium, 3=large) lives in `analytics.dim_bin_size.size_rank` so charts sort correctly |

## Data quality findings

| Check | Result |
|---|---|
| Fully duplicate rows | 0 |
| Duplicate `bin_id` (non-blank) | 0 |
| Blank `bin_id` | 29 |
| Blank `location` | 53 |
| Blank `recycling_bin_color` | 54 |
| Invalid date / time / color formats | 0 |
| Negative or zero weights | 0 |
| **Rows where `bin_type` and `waste_category` contradict each other** | **Many**. For example, 85 `compost` bins are tagged `hazardous waste`, and 123 `recycling` bins are tagged `hazardous waste` |

The contradictions exist because Mockaroo picks each column at random. Real data has these problems too, for a different reason: people pick the wrong option on a form. This is good practice for writing **business rules**.

## Business rules (decide these before writing transforms)

These are suggested rules for practice. In a real project, the people who own the data would decide them.

1. A `compost` bin should only contain `food waste`.
2. A `recycling` bin should not contain `hazardous waste`.
3. `material` (paper/plastic/glass/metal) only applies to `recycling` bins.
4. Every pickup should have a `bin_id`.

**What to do with rows that break a rule:** don't delete them. Keep them and set a flag column (e.g. `is_valid = false`, plus `invalid_reason`). Then dashboards can show or hide them, and you can count how many rows are bad.

Rules 1, 2 and 4 flag the row. Rule 3 is a cleanup instead: it would flag two-thirds of the data, so `etl/transform.py` blanks out `material` on non-recycling bins.

Results from the first pipeline run (see `analytics.v_data_quality`):

| Status | Rows | % |
|---|---|---|
| valid | 649 | 64.9 |
| compost bin with non-food waste | 205 | 20.5 |
| hazardous waste in recycling bin | 117 | 11.7 |
| missing bin_id | 29 | 2.9 |

## Open questions (would ask the data owner)

- What unit is `weight` in: lbs or kg?
- What time zone are pickup times in?
- Is `bin_id` meant to identify a physical bin (which would repeat across pickups) or a single pickup?
- What city, state, or region are the addresses in?

## Planned tables

| Layer | Table | Contents |
|---|---|---|
| raw | `raw.bin_pickups` | All 10 CSV columns as `text`, plus `_source_file` and `_loaded_at` |
| staging | `staging.bin_pickups` | One row per pickup: `pickup_id` (= the CSV row number), typed and cleaned columns, `pickup_at`, `is_valid`, `invalid_reason` |
| analytics | `analytics.fact_pickups` | `pickup_id`, `pickup_at`, `weight_lbs`, plus keys to the dimension tables. No address or color columns |
| analytics | `analytics.dim_bin_type`, `analytics.dim_bin_size` | Lookup tables for filtering and sorting in Superset |
| analytics | `v_monthly_weight_by_bin_type`, `v_pickups_by_bin_size`, `v_data_quality` | Views: ready-made datasets for Superset |
