-- CS336 Project 2: fail-fast checks for the normalized database.
-- This script may compare against Preliminary; the report export never does.
-- Run in psql with: \i sql/03_validate.sql

\set ON_ERROR_STOP on
\encoding UTF8

DO $$
DECLARE
    source_applicant_races BIGINT;
    source_co_applicant_races BIGINT;
    source_denial_reasons BIGINT;
BEGIN
    IF (SELECT COUNT(*) FROM application) <> (SELECT COUNT(*) FROM nr809.preliminary) THEN
        RAISE EXCEPTION 'Application count differs from Preliminary';
    END IF;

    IF EXISTS (
        SELECT 1 FROM application GROUP BY application_id HAVING COUNT(*) <> 1
    ) THEN
        RAISE EXCEPTION 'application_id is not one-to-one with source rows';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM nr809.preliminary p
        LEFT JOIN application a ON a.application_id = p.sequence_number
        WHERE a.application_id IS NULL
    ) THEN
        RAISE EXCEPTION 'At least one source row has no normalized application';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM application a
        JOIN location l ON l.location_id = a.location_id
        JOIN nr809.preliminary p ON p.sequence_number = a.application_id
        WHERE ROW(
            l.county_code, l.msamd, l.state_code, l.census_tract_number,
            l.population, l.minority_population, l.hud_median_family_income,
            l.tract_to_msamd_income, l.number_of_owner_occupied_units,
            l.number_of_1_to_4_family_units
        ) IS DISTINCT FROM ROW(
            p.county_code, p.msamd, p.state_code, p.census_tract_number::text,
            p.population, p.minority_population, p.hud_median_family_income,
            p.tract_to_msamd_income, p.number_of_owner_occupied_units,
            p.number_of_1_to_4_family_units
        )
    ) THEN
        RAISE EXCEPTION 'At least one application has the wrong location_id';
    END IF;

    SELECT
        COUNT(applicant_race_1) + COUNT(applicant_race_2)
        + COUNT(applicant_race_3) + COUNT(applicant_race_4)
        + COUNT(applicant_race_5)
    INTO source_applicant_races
    FROM nr809.preliminary;

    SELECT
        COUNT(co_applicant_race_1) + COUNT(co_applicant_race_2)
        + COUNT(co_applicant_race_3) + COUNT(co_applicant_race_4)
        + COUNT(co_applicant_race_5)
    INTO source_co_applicant_races
    FROM nr809.preliminary;

    SELECT
        COUNT(denial_reason_1) + COUNT(denial_reason_2)
        + COUNT(denial_reason_3)
    INTO source_denial_reasons
    FROM nr809.preliminary;

    IF source_applicant_races <> (SELECT COUNT(*) FROM application_applicant_race) THEN
        RAISE EXCEPTION 'Applicant race rows were lost or duplicated';
    END IF;
    IF source_co_applicant_races <> (SELECT COUNT(*) FROM application_co_applicant_race) THEN
        RAISE EXCEPTION 'Co-applicant race rows were lost or duplicated';
    END IF;
    IF source_denial_reasons <> (SELECT COUNT(*) FROM application_denial_reason) THEN
        RAISE EXCEPTION 'Denial reason rows were lost or duplicated';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'nr809'
          AND table_name = 'application'
          AND (column_name LIKE '%name%' OR column_name IN (
              'county_code', 'msamd', 'state_code', 'census_tract_number',
              'population', 'minority_population', 'hud_median_family_income',
              'tract_to_msamd_income', 'number_of_owner_occupied_units',
              'number_of_1_to_4_family_units'
          ))
    ) THEN
        RAISE EXCEPTION 'Application still contains a name or location attribute';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'nr809'
          AND table_name IN (
              'application', 'application_applicant_race',
              'application_co_applicant_race', 'application_denial_reason'
          )
          AND column_name ~ '_(race|reason)_[1-5]$'
    ) THEN
        RAISE EXCEPTION 'A numbered repeating-group column remains';
    END IF;
END
$$;

-- Expected: all zero.
SELECT
    (SELECT COUNT(*) FROM nr809.preliminary)
        - (SELECT COUNT(*) FROM application) AS application_count_difference,
    2135 - (SELECT COUNT(*) FROM location) AS location_count_difference,
    351510 - (SELECT COUNT(*) FROM application_applicant_race)
        AS applicant_race_count_difference,
    350201 - (SELECT COUNT(*) FROM application_co_applicant_race)
        AS co_applicant_race_count_difference,
    45088 - (SELECT COUNT(*) FROM application_denial_reason)
        AS denial_reason_count_difference;

SELECT 'PASS: normalized database matches source counts and location mappings.'
    AS validation_result;
