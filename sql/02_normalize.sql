-- CS336 Project 2: create and populate the normalized HMDA database.
-- Prerequisite: Project 1's public.Preliminary table with 349,563 rows.
-- Run in psql with: \i sql/02_normalize.sql

\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;

-- Remove only Project 2 objects, in dependency order. Preliminary is untouched.
DROP TABLE IF EXISTS application_denial_reason CASCADE;
DROP TABLE IF EXISTS application_co_applicant_race CASCADE;
DROP TABLE IF EXISTS application_applicant_race CASCADE;
DROP TABLE IF EXISTS application CASCADE;
DROP TABLE IF EXISTS location CASCADE;
DROP TABLE IF EXISTS denial_reason CASCADE;
DROP TABLE IF EXISTS race CASCADE;
DROP TABLE IF EXISTS sex CASCADE;
DROP TABLE IF EXISTS ethnicity CASCADE;
DROP TABLE IF EXISTS lien_status CASCADE;
DROP TABLE IF EXISTS hoepa_status CASCADE;
DROP TABLE IF EXISTS purchaser_type CASCADE;
DROP TABLE IF EXISTS county CASCADE;
DROP TABLE IF EXISTS state CASCADE;
DROP TABLE IF EXISTS msamd CASCADE;
DROP TABLE IF EXISTS action_taken CASCADE;
DROP TABLE IF EXISTS preapproval CASCADE;
DROP TABLE IF EXISTS owner_occupancy CASCADE;
DROP TABLE IF EXISTS loan_purpose CASCADE;
DROP TABLE IF EXISTS property_type CASCADE;
DROP TABLE IF EXISTS loan_type CASCADE;
DROP TABLE IF EXISTS agency CASCADE;

-- Each lookup implements one or more verified code -> name dependencies.
CREATE TABLE agency (
    agency_code SMALLINT PRIMARY KEY,
    agency_name TEXT NOT NULL,
    agency_abbr TEXT NOT NULL
);

CREATE TABLE loan_type (
    loan_type SMALLINT PRIMARY KEY,
    loan_type_name TEXT NOT NULL
);

CREATE TABLE property_type (
    property_type SMALLINT PRIMARY KEY,
    property_type_name TEXT NOT NULL
);

CREATE TABLE loan_purpose (
    loan_purpose SMALLINT PRIMARY KEY,
    loan_purpose_name TEXT NOT NULL
);

CREATE TABLE owner_occupancy (
    owner_occupancy SMALLINT PRIMARY KEY,
    owner_occupancy_name TEXT NOT NULL
);

CREATE TABLE preapproval (
    preapproval SMALLINT PRIMARY KEY,
    preapproval_name TEXT NOT NULL
);

CREATE TABLE action_taken (
    action_taken SMALLINT PRIMARY KEY,
    action_taken_name TEXT NOT NULL
);

CREATE TABLE msamd (
    msamd INTEGER PRIMARY KEY,
    msamd_name TEXT
);

CREATE TABLE state (
    state_code SMALLINT PRIMARY KEY,
    state_name TEXT NOT NULL,
    state_abbr TEXT NOT NULL
);

CREATE TABLE county (
    county_code SMALLINT PRIMARY KEY,
    county_name TEXT NOT NULL
);

-- Applicant and co-applicant use the same code systems. One shared lookup
-- avoids the duplicate-identical-table rubric error.
CREATE TABLE ethnicity (
    ethnicity SMALLINT PRIMARY KEY,
    ethnicity_name TEXT NOT NULL
);

CREATE TABLE race (
    race SMALLINT PRIMARY KEY,
    race_name TEXT NOT NULL
);

CREATE TABLE sex (
    sex SMALLINT PRIMARY KEY,
    sex_name TEXT NOT NULL
);

CREATE TABLE purchaser_type (
    purchaser_type SMALLINT PRIMARY KEY,
    purchaser_type_name TEXT NOT NULL
);

CREATE TABLE denial_reason (
    denial_reason SMALLINT PRIMARY KEY,
    denial_reason_name TEXT NOT NULL
);

CREATE TABLE hoepa_status (
    hoepa_status SMALLINT PRIMARY KEY,
    hoepa_status_name TEXT NOT NULL
);

CREATE TABLE lien_status (
    lien_status SMALLINT PRIMARY KEY,
    lien_status_name TEXT NOT NULL
);

-- location_id is one of the two assignment-authorized identifiers. The ten
-- source attributes are the assignment-specified alternate composite key.
CREATE TABLE location (
    location_id BIGSERIAL PRIMARY KEY,
    county_code SMALLINT REFERENCES county(county_code),
    msamd INTEGER REFERENCES msamd(msamd),
    state_code SMALLINT NOT NULL REFERENCES state(state_code),
    census_tract_number TEXT,
    population INTEGER,
    minority_population NUMERIC,
    hud_median_family_income INTEGER,
    tract_to_msamd_income NUMERIC,
    number_of_owner_occupied_units INTEGER,
    number_of_1_to_4_family_units INTEGER,
    CHECK (county_code IS NULL OR county_code >= 0),
    CHECK (msamd IS NULL OR msamd >= 0),
    CHECK (population IS NULL OR population >= 0),
    CHECK (minority_population IS NULL OR minority_population >= 0),
    CHECK (hud_median_family_income IS NULL OR hud_median_family_income >= 0),
    CHECK (tract_to_msamd_income IS NULL OR tract_to_msamd_income >= 0),
    CHECK (number_of_owner_occupied_units IS NULL OR number_of_owner_occupied_units >= 0),
    CHECK (number_of_1_to_4_family_units IS NULL OR number_of_1_to_4_family_units >= 0)
);

-- PostgreSQL versions before 15 lack UNIQUE NULLS NOT DISTINCT. This
-- expression index enforces the ten-column alternate key even for the 697
-- source rows whose tract fields are null. The checks above reserve -1 and
-- the empty string as safe null sentinels for this index only.
CREATE UNIQUE INDEX location_source_key_uq ON location (
    COALESCE(county_code, -1),
    COALESCE(msamd, -1),
    state_code,
    COALESCE(census_tract_number, ''),
    COALESCE(population, -1),
    COALESCE(minority_population, -1),
    COALESCE(hud_median_family_income, -1),
    COALESCE(tract_to_msamd_income, -1),
    COALESCE(number_of_owner_occupied_units, -1),
    COALESCE(number_of_1_to_4_family_units, -1)
);

-- application_id comes from Project 1's generated sequence_number and is the
-- other assignment-authorized identifier. No applicant entity is invented:
-- the source contains no stable person identifier across applications.
CREATE TABLE application (
    application_id BIGINT PRIMARY KEY,
    as_of_year SMALLINT NOT NULL,
    respondent_id TEXT NOT NULL,
    agency_code SMALLINT NOT NULL REFERENCES agency(agency_code),
    loan_type SMALLINT NOT NULL REFERENCES loan_type(loan_type),
    property_type SMALLINT NOT NULL REFERENCES property_type(property_type),
    loan_purpose SMALLINT NOT NULL REFERENCES loan_purpose(loan_purpose),
    owner_occupancy SMALLINT NOT NULL REFERENCES owner_occupancy(owner_occupancy),
    loan_amount_000s INTEGER,
    preapproval SMALLINT NOT NULL REFERENCES preapproval(preapproval),
    action_taken SMALLINT NOT NULL REFERENCES action_taken(action_taken),
    location_id BIGINT NOT NULL REFERENCES location(location_id),
    applicant_ethnicity SMALLINT NOT NULL REFERENCES ethnicity(ethnicity),
    co_applicant_ethnicity SMALLINT NOT NULL REFERENCES ethnicity(ethnicity),
    applicant_sex SMALLINT NOT NULL REFERENCES sex(sex),
    co_applicant_sex SMALLINT NOT NULL REFERENCES sex(sex),
    applicant_income_000s INTEGER,
    purchaser_type SMALLINT NOT NULL REFERENCES purchaser_type(purchaser_type),
    rate_spread NUMERIC,
    hoepa_status SMALLINT NOT NULL REFERENCES hoepa_status(hoepa_status),
    lien_status SMALLINT NOT NULL REFERENCES lien_status(lien_status),
    CHECK (as_of_year = 2017),
    CHECK (loan_amount_000s IS NULL OR loan_amount_000s >= 0)
);

-- Numbered race/reason columns become rows. The ordinal is retained so the
-- original CSV can be reconstructed exactly.
CREATE TABLE application_applicant_race (
    application_id BIGINT NOT NULL REFERENCES application(application_id) ON DELETE CASCADE,
    race_number SMALLINT NOT NULL CHECK (race_number BETWEEN 1 AND 5),
    race SMALLINT NOT NULL REFERENCES race(race),
    PRIMARY KEY (application_id, race_number)
);

CREATE TABLE application_co_applicant_race (
    application_id BIGINT NOT NULL REFERENCES application(application_id) ON DELETE CASCADE,
    race_number SMALLINT NOT NULL CHECK (race_number BETWEEN 1 AND 5),
    race SMALLINT NOT NULL REFERENCES race(race),
    PRIMARY KEY (application_id, race_number)
);

CREATE TABLE application_denial_reason (
    application_id BIGINT NOT NULL REFERENCES application(application_id) ON DELETE CASCADE,
    reason_number SMALLINT NOT NULL CHECK (reason_number BETWEEN 1 AND 3),
    denial_reason SMALLINT NOT NULL REFERENCES denial_reason(denial_reason),
    PRIMARY KEY (application_id, reason_number)
);

-- Populate code/name relations directly from the data. Conflicting mappings
-- would violate their primary keys and stop the transaction.
INSERT INTO agency
SELECT DISTINCT agency_code, agency_name, agency_abbr
FROM public.Preliminary;

INSERT INTO loan_type
SELECT DISTINCT loan_type, loan_type_name FROM public.Preliminary;

INSERT INTO property_type
SELECT DISTINCT property_type, property_type_name FROM public.Preliminary;

INSERT INTO loan_purpose
SELECT DISTINCT loan_purpose, loan_purpose_name FROM public.Preliminary;

INSERT INTO owner_occupancy
SELECT DISTINCT owner_occupancy, owner_occupancy_name FROM public.Preliminary;

INSERT INTO preapproval
SELECT DISTINCT preapproval, preapproval_name FROM public.Preliminary;

INSERT INTO action_taken
SELECT DISTINCT action_taken, action_taken_name FROM public.Preliminary;

INSERT INTO msamd
SELECT DISTINCT msamd, msamd_name
FROM public.Preliminary
WHERE msamd IS NOT NULL;

INSERT INTO state
SELECT DISTINCT state_code, state_name, state_abbr FROM public.Preliminary;

INSERT INTO county
SELECT DISTINCT county_code, county_name
FROM public.Preliminary
WHERE county_code IS NOT NULL;

INSERT INTO ethnicity
SELECT applicant_ethnicity, applicant_ethnicity_name FROM public.Preliminary
UNION
SELECT co_applicant_ethnicity, co_applicant_ethnicity_name FROM public.Preliminary;

INSERT INTO sex
SELECT applicant_sex, applicant_sex_name FROM public.Preliminary
UNION
SELECT co_applicant_sex, co_applicant_sex_name FROM public.Preliminary;

INSERT INTO race
SELECT race_code, race_name
FROM public.Preliminary p
CROSS JOIN LATERAL (
    VALUES
        (p.applicant_race_1, p.applicant_race_name_1),
        (p.applicant_race_2, p.applicant_race_name_2),
        (p.applicant_race_3, p.applicant_race_name_3),
        (p.applicant_race_4, p.applicant_race_name_4),
        (p.applicant_race_5, p.applicant_race_name_5),
        (p.co_applicant_race_1, p.co_applicant_race_name_1),
        (p.co_applicant_race_2, p.co_applicant_race_name_2),
        (p.co_applicant_race_3, p.co_applicant_race_name_3),
        (p.co_applicant_race_4, p.co_applicant_race_name_4),
        (p.co_applicant_race_5, p.co_applicant_race_name_5)
) AS values_from_source(race_code, race_name)
WHERE race_code IS NOT NULL
GROUP BY race_code, race_name;

INSERT INTO purchaser_type
SELECT DISTINCT purchaser_type, purchaser_type_name FROM public.Preliminary;

INSERT INTO denial_reason
SELECT reason_code, reason_name
FROM public.Preliminary p
CROSS JOIN LATERAL (
    VALUES
        (p.denial_reason_1, p.denial_reason_name_1),
        (p.denial_reason_2, p.denial_reason_name_2),
        (p.denial_reason_3, p.denial_reason_name_3)
) AS values_from_source(reason_code, reason_name)
WHERE reason_code IS NOT NULL
GROUP BY reason_code, reason_name;

INSERT INTO hoepa_status
SELECT DISTINCT hoepa_status, hoepa_status_name FROM public.Preliminary;

INSERT INTO lien_status
SELECT DISTINCT lien_status, lien_status_name FROM public.Preliminary;

-- Assign one stable integer to each distinct ten-attribute location tuple.
INSERT INTO location (
    county_code, msamd, state_code, census_tract_number, population,
    minority_population, hud_median_family_income, tract_to_msamd_income,
    number_of_owner_occupied_units, number_of_1_to_4_family_units
)
SELECT DISTINCT
    county_code, msamd, state_code, census_tract_number, population,
    minority_population, hud_median_family_income, tract_to_msamd_income,
    number_of_owner_occupied_units, number_of_1_to_4_family_units
FROM public.Preliminary
ORDER BY
    county_code NULLS FIRST,
    msamd NULLS FIRST,
    state_code,
    census_tract_number NULLS FIRST,
    population NULLS FIRST,
    minority_population NULLS FIRST,
    hud_median_family_income NULLS FIRST,
    tract_to_msamd_income NULLS FIRST,
    number_of_owner_occupied_units NULLS FIRST,
    number_of_1_to_4_family_units NULLS FIRST;

INSERT INTO application (
    application_id, as_of_year, respondent_id, agency_code, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status
)
SELECT
    p.sequence_number,
    p.as_of_year,
    p.respondent_id,
    p.agency_code,
    p.loan_type,
    p.property_type,
    p.loan_purpose,
    p.owner_occupancy,
    p.loan_amount_000s,
    p.preapproval,
    p.action_taken,
    l.location_id,
    p.applicant_ethnicity,
    p.co_applicant_ethnicity,
    p.applicant_sex,
    p.co_applicant_sex,
    p.applicant_income_000s,
    p.purchaser_type,
    p.rate_spread,
    p.hoepa_status,
    p.lien_status
FROM public.Preliminary p
JOIN location l ON
    l.county_code IS NOT DISTINCT FROM p.county_code
    AND l.msamd IS NOT DISTINCT FROM p.msamd
    AND l.state_code = p.state_code
    AND l.census_tract_number IS NOT DISTINCT FROM p.census_tract_number
    AND l.population IS NOT DISTINCT FROM p.population
    AND l.minority_population IS NOT DISTINCT FROM p.minority_population
    AND l.hud_median_family_income IS NOT DISTINCT FROM p.hud_median_family_income
    AND l.tract_to_msamd_income IS NOT DISTINCT FROM p.tract_to_msamd_income
    AND l.number_of_owner_occupied_units IS NOT DISTINCT FROM p.number_of_owner_occupied_units
    AND l.number_of_1_to_4_family_units IS NOT DISTINCT FROM p.number_of_1_to_4_family_units;

INSERT INTO application_applicant_race (application_id, race_number, race)
SELECT p.sequence_number, values_from_source.race_number, values_from_source.race
FROM public.Preliminary p
CROSS JOIN LATERAL (
    VALUES
        (1, p.applicant_race_1),
        (2, p.applicant_race_2),
        (3, p.applicant_race_3),
        (4, p.applicant_race_4),
        (5, p.applicant_race_5)
) AS values_from_source(race_number, race)
WHERE values_from_source.race IS NOT NULL;

INSERT INTO application_co_applicant_race (application_id, race_number, race)
SELECT p.sequence_number, values_from_source.race_number, values_from_source.race
FROM public.Preliminary p
CROSS JOIN LATERAL (
    VALUES
        (1, p.co_applicant_race_1),
        (2, p.co_applicant_race_2),
        (3, p.co_applicant_race_3),
        (4, p.co_applicant_race_4),
        (5, p.co_applicant_race_5)
) AS values_from_source(race_number, race)
WHERE values_from_source.race IS NOT NULL;

INSERT INTO application_denial_reason (application_id, reason_number, denial_reason)
SELECT p.sequence_number, values_from_source.reason_number, values_from_source.denial_reason
FROM public.Preliminary p
CROSS JOIN LATERAL (
    VALUES
        (1, p.denial_reason_1),
        (2, p.denial_reason_2),
        (3, p.denial_reason_3)
) AS values_from_source(reason_number, denial_reason)
WHERE values_from_source.denial_reason IS NOT NULL;

-- Source-specific invariants. A failure rolls back the complete build.
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM public.Preliminary) <> 349563 THEN
        RAISE EXCEPTION 'Expected 349563 Preliminary rows';
    END IF;
    IF (SELECT COUNT(*) FROM application) <> 349563 THEN
        RAISE EXCEPTION 'Application row count does not match Preliminary';
    END IF;
    IF (SELECT COUNT(*) FROM location) <> 2135 THEN
        RAISE EXCEPTION 'Expected 2135 distinct locations';
    END IF;
    IF (SELECT COUNT(*) FROM application_applicant_race) <> 351510 THEN
        RAISE EXCEPTION 'Applicant race row count mismatch';
    END IF;
    IF (SELECT COUNT(*) FROM application_co_applicant_race) <> 350201 THEN
        RAISE EXCEPTION 'Co-applicant race row count mismatch';
    END IF;
    IF (SELECT COUNT(*) FROM application_denial_reason) <> 45088 THEN
        RAISE EXCEPTION 'Denial reason row count mismatch';
    END IF;
END
$$;

COMMIT;

-- Compact completion summary.
SELECT 'application' AS table_name, COUNT(*) AS row_count FROM application
UNION ALL SELECT 'location', COUNT(*) FROM location
UNION ALL SELECT 'application_applicant_race', COUNT(*) FROM application_applicant_race
UNION ALL SELECT 'application_co_applicant_race', COUNT(*) FROM application_co_applicant_race
UNION ALL SELECT 'application_denial_reason', COUNT(*) FROM application_denial_reason
ORDER BY table_name;
