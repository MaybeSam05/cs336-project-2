-- Three intentionally invalid statements for the Step 4 evidence video.
-- Every failure is isolated and the outer transaction is rolled back.

\set ON_ERROR_STOP off
\encoding UTF8
BEGIN;

\echo 'TEST 1: invalid property_type 4 must fail its foreign key'
SAVEPOINT invalid_property_type;
INSERT INTO application (
    application_id, as_of_year, respondent_id, agency_code, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status
)
SELECT
    9000001, as_of_year, respondent_id, agency_code, loan_type,
    4, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status
FROM application
LIMIT 1;
ROLLBACK TO SAVEPOINT invalid_property_type;

\echo 'TEST 2: null respondent_id must fail NOT NULL'
SAVEPOINT missing_required_value;
INSERT INTO application (
    application_id, as_of_year, respondent_id, agency_code, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status
)
SELECT
    9000002, as_of_year, NULL, agency_code, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status
FROM application
LIMIT 1;
ROLLBACK TO SAVEPOINT missing_required_value;

\echo 'TEST 3: applicant race position 6 must fail its CHECK constraint'
SAVEPOINT invalid_race_position;
INSERT INTO application_applicant_race (application_id, race_number, race)
SELECT application_id, 6, 1
FROM application
LIMIT 1;
ROLLBACK TO SAVEPOINT invalid_race_position;

ROLLBACK;
\echo 'All three bad writes were rejected; the database is unchanged.'
