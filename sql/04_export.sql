-- CS336 Project 2: reconstruct the original 78-column CSV using only the
-- normalized database. The staging relation is intentionally never referenced.
-- Run in psql with: \i sql/04_export.sql

\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;

CREATE TEMP VIEW hmda_export AS
WITH applicant_races AS (
    SELECT
        ar.application_id,
        MAX(ar.race) FILTER (WHERE ar.race_number = 1) AS race_1,
        MAX(r.race_name) FILTER (WHERE ar.race_number = 1) AS race_name_1,
        MAX(ar.race) FILTER (WHERE ar.race_number = 2) AS race_2,
        MAX(r.race_name) FILTER (WHERE ar.race_number = 2) AS race_name_2,
        MAX(ar.race) FILTER (WHERE ar.race_number = 3) AS race_3,
        MAX(r.race_name) FILTER (WHERE ar.race_number = 3) AS race_name_3,
        MAX(ar.race) FILTER (WHERE ar.race_number = 4) AS race_4,
        MAX(r.race_name) FILTER (WHERE ar.race_number = 4) AS race_name_4,
        MAX(ar.race) FILTER (WHERE ar.race_number = 5) AS race_5,
        MAX(r.race_name) FILTER (WHERE ar.race_number = 5) AS race_name_5
    FROM application_applicant_race ar
    JOIN race r ON r.race = ar.race
    GROUP BY ar.application_id
),
co_applicant_races AS (
    SELECT
        cr.application_id,
        MAX(cr.race) FILTER (WHERE cr.race_number = 1) AS race_1,
        MAX(r.race_name) FILTER (WHERE cr.race_number = 1) AS race_name_1,
        MAX(cr.race) FILTER (WHERE cr.race_number = 2) AS race_2,
        MAX(r.race_name) FILTER (WHERE cr.race_number = 2) AS race_name_2,
        MAX(cr.race) FILTER (WHERE cr.race_number = 3) AS race_3,
        MAX(r.race_name) FILTER (WHERE cr.race_number = 3) AS race_name_3,
        MAX(cr.race) FILTER (WHERE cr.race_number = 4) AS race_4,
        MAX(r.race_name) FILTER (WHERE cr.race_number = 4) AS race_name_4,
        MAX(cr.race) FILTER (WHERE cr.race_number = 5) AS race_5,
        MAX(r.race_name) FILTER (WHERE cr.race_number = 5) AS race_name_5
    FROM application_co_applicant_race cr
    JOIN race r ON r.race = cr.race
    GROUP BY cr.application_id
),
denial_reasons AS (
    SELECT
        adr.application_id,
        MAX(adr.denial_reason) FILTER (WHERE adr.reason_number = 1) AS reason_1,
        MAX(dr.denial_reason_name) FILTER (WHERE adr.reason_number = 1) AS reason_name_1,
        MAX(adr.denial_reason) FILTER (WHERE adr.reason_number = 2) AS reason_2,
        MAX(dr.denial_reason_name) FILTER (WHERE adr.reason_number = 2) AS reason_name_2,
        MAX(adr.denial_reason) FILTER (WHERE adr.reason_number = 3) AS reason_3,
        MAX(dr.denial_reason_name) FILTER (WHERE adr.reason_number = 3) AS reason_name_3
    FROM application_denial_reason adr
    JOIN denial_reason dr ON dr.denial_reason = adr.denial_reason
    GROUP BY adr.application_id
)
SELECT
    a.application_id AS _export_order,
    COALESCE(a.as_of_year::TEXT, '') AS as_of_year,
    COALESCE(a.respondent_id, '') AS respondent_id,
    COALESCE(ag.agency_name, '') AS agency_name,
    COALESCE(ag.agency_abbr, '') AS agency_abbr,
    COALESCE(a.agency_code::TEXT, '') AS agency_code,
    COALESCE(lt.loan_type_name, '') AS loan_type_name,
    COALESCE(a.loan_type::TEXT, '') AS loan_type,
    COALESCE(pt.property_type_name, '') AS property_type_name,
    COALESCE(a.property_type::TEXT, '') AS property_type,
    COALESCE(lp.loan_purpose_name, '') AS loan_purpose_name,
    COALESCE(a.loan_purpose::TEXT, '') AS loan_purpose,
    COALESCE(oo.owner_occupancy_name, '') AS owner_occupancy_name,
    COALESCE(a.owner_occupancy::TEXT, '') AS owner_occupancy,
    COALESCE(a.loan_amount_000s::TEXT, '') AS loan_amount_000s,
    COALESCE(pa.preapproval_name, '') AS preapproval_name,
    COALESCE(a.preapproval::TEXT, '') AS preapproval,
    COALESCE(at.action_taken_name, '') AS action_taken_name,
    COALESCE(a.action_taken::TEXT, '') AS action_taken,
    COALESCE(m.msamd_name, '') AS msamd_name,
    COALESCE(l.msamd::TEXT, '') AS msamd,
    COALESCE(s.state_name, '') AS state_name,
    COALESCE(s.state_abbr, '') AS state_abbr,
    COALESCE(l.state_code::TEXT, '') AS state_code,
    COALESCE(c.county_name, '') AS county_name,
    COALESCE(l.county_code::TEXT, '') AS county_code,
    COALESCE(l.census_tract_number, '') AS census_tract_number,
    COALESCE(ae.ethnicity_name, '') AS applicant_ethnicity_name,
    COALESCE(a.applicant_ethnicity::TEXT, '') AS applicant_ethnicity,
    COALESCE(ce.ethnicity_name, '') AS co_applicant_ethnicity_name,
    COALESCE(a.co_applicant_ethnicity::TEXT, '') AS co_applicant_ethnicity,
    COALESCE(ar.race_name_1, '') AS applicant_race_name_1,
    COALESCE(ar.race_1::TEXT, '') AS applicant_race_1,
    COALESCE(ar.race_name_2, '') AS applicant_race_name_2,
    COALESCE(ar.race_2::TEXT, '') AS applicant_race_2,
    COALESCE(ar.race_name_3, '') AS applicant_race_name_3,
    COALESCE(ar.race_3::TEXT, '') AS applicant_race_3,
    COALESCE(ar.race_name_4, '') AS applicant_race_name_4,
    COALESCE(ar.race_4::TEXT, '') AS applicant_race_4,
    COALESCE(ar.race_name_5, '') AS applicant_race_name_5,
    COALESCE(ar.race_5::TEXT, '') AS applicant_race_5,
    COALESCE(cr.race_name_1, '') AS co_applicant_race_name_1,
    COALESCE(cr.race_1::TEXT, '') AS co_applicant_race_1,
    COALESCE(cr.race_name_2, '') AS co_applicant_race_name_2,
    COALESCE(cr.race_2::TEXT, '') AS co_applicant_race_2,
    COALESCE(cr.race_name_3, '') AS co_applicant_race_name_3,
    COALESCE(cr.race_3::TEXT, '') AS co_applicant_race_3,
    COALESCE(cr.race_name_4, '') AS co_applicant_race_name_4,
    COALESCE(cr.race_4::TEXT, '') AS co_applicant_race_4,
    COALESCE(cr.race_name_5, '') AS co_applicant_race_name_5,
    COALESCE(cr.race_5::TEXT, '') AS co_applicant_race_5,
    COALESCE(ase.sex_name, '') AS applicant_sex_name,
    COALESCE(a.applicant_sex::TEXT, '') AS applicant_sex,
    COALESCE(cse.sex_name, '') AS co_applicant_sex_name,
    COALESCE(a.co_applicant_sex::TEXT, '') AS co_applicant_sex,
    COALESCE(a.applicant_income_000s::TEXT, '') AS applicant_income_000s,
    COALESCE(pu.purchaser_type_name, '') AS purchaser_type_name,
    COALESCE(a.purchaser_type::TEXT, '') AS purchaser_type,
    COALESCE(d.reason_name_1, '') AS denial_reason_name_1,
    COALESCE(d.reason_1::TEXT, '') AS denial_reason_1,
    COALESCE(d.reason_name_2, '') AS denial_reason_name_2,
    COALESCE(d.reason_2::TEXT, '') AS denial_reason_2,
    COALESCE(d.reason_name_3, '') AS denial_reason_name_3,
    COALESCE(d.reason_3::TEXT, '') AS denial_reason_3,
    COALESCE(to_char(a.rate_spread, 'FM00.00'), '') AS rate_spread,
    COALESCE(hs.hoepa_status_name, '') AS hoepa_status_name,
    COALESCE(a.hoepa_status::TEXT, '') AS hoepa_status,
    COALESCE(ls.lien_status_name, '') AS lien_status_name,
    COALESCE(a.lien_status::TEXT, '') AS lien_status,
    ''::TEXT AS edit_status_name,
    ''::TEXT AS edit_status,
    ''::TEXT AS sequence_number,
    COALESCE(l.population::TEXT, '') AS population,
    COALESCE(l.minority_population::TEXT, '') AS minority_population,
    COALESCE(l.hud_median_family_income::TEXT, '') AS hud_median_family_income,
    COALESCE(l.tract_to_msamd_income::TEXT, '') AS tract_to_msamd_income,
    COALESCE(l.number_of_owner_occupied_units::TEXT, '') AS number_of_owner_occupied_units,
    COALESCE(l.number_of_1_to_4_family_units::TEXT, '') AS number_of_1_to_4_family_units,
    ''::TEXT AS application_date_indicator
FROM application a
JOIN agency ag ON ag.agency_code = a.agency_code
JOIN loan_type lt ON lt.loan_type = a.loan_type
JOIN property_type pt ON pt.property_type = a.property_type
JOIN loan_purpose lp ON lp.loan_purpose = a.loan_purpose
JOIN owner_occupancy oo ON oo.owner_occupancy = a.owner_occupancy
JOIN preapproval pa ON pa.preapproval = a.preapproval
JOIN action_taken at ON at.action_taken = a.action_taken
JOIN location l ON l.location_id = a.location_id
LEFT JOIN msamd m ON m.msamd = l.msamd
JOIN state s ON s.state_code = l.state_code
LEFT JOIN county c ON c.county_code = l.county_code
JOIN ethnicity ae ON ae.ethnicity = a.applicant_ethnicity
JOIN ethnicity ce ON ce.ethnicity = a.co_applicant_ethnicity
JOIN applicant_races ar ON ar.application_id = a.application_id
JOIN co_applicant_races cr ON cr.application_id = a.application_id
JOIN sex ase ON ase.sex = a.applicant_sex
JOIN sex cse ON cse.sex = a.co_applicant_sex
JOIN purchaser_type pu ON pu.purchaser_type = a.purchaser_type
LEFT JOIN denial_reasons d ON d.application_id = a.application_id
JOIN hoepa_status hs ON hs.hoepa_status = a.hoepa_status
JOIN lien_status ls ON ls.lien_status = a.lien_status;

-- Keep this psql \copy command on one physical line. The official source has
-- an unquoted header, every data field quoted, UTF-8 encoding, and LF endings.
\copy (SELECT as_of_year, respondent_id, agency_name, agency_abbr, agency_code, loan_type_name, loan_type, property_type_name, property_type, loan_purpose_name, loan_purpose, owner_occupancy_name, owner_occupancy, loan_amount_000s, preapproval_name, preapproval, action_taken_name, action_taken, msamd_name, msamd, state_name, state_abbr, state_code, county_name, county_code, census_tract_number, applicant_ethnicity_name, applicant_ethnicity, co_applicant_ethnicity_name, co_applicant_ethnicity, applicant_race_name_1, applicant_race_1, applicant_race_name_2, applicant_race_2, applicant_race_name_3, applicant_race_3, applicant_race_name_4, applicant_race_4, applicant_race_name_5, applicant_race_5, co_applicant_race_name_1, co_applicant_race_1, co_applicant_race_name_2, co_applicant_race_2, co_applicant_race_name_3, co_applicant_race_3, co_applicant_race_name_4, co_applicant_race_4, co_applicant_race_name_5, co_applicant_race_5, applicant_sex_name, applicant_sex, co_applicant_sex_name, co_applicant_sex, applicant_income_000s, purchaser_type_name, purchaser_type, denial_reason_name_1, denial_reason_1, denial_reason_name_2, denial_reason_2, denial_reason_name_3, denial_reason_3, rate_spread, hoepa_status_name, hoepa_status, lien_status_name, lien_status, edit_status_name, edit_status, sequence_number, population, minority_population, hud_median_family_income, tract_to_msamd_income, number_of_owner_occupied_units, number_of_1_to_4_family_units, application_date_indicator FROM pg_temp.hmda_export ORDER BY _export_order) TO 'reconstructed.csv' WITH (FORMAT CSV, HEADER TRUE, FORCE_QUOTE *, ENCODING 'UTF8')

DROP VIEW pg_temp.hmda_export;
COMMIT;

-- From the Linux shell, exact source-order validation should print nothing:
-- diff hmda_2017_nj_all-records_labels.csv reconstructed.csv
