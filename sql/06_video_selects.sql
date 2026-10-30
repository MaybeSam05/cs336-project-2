-- Fast table previews for the Step 3 video. Run with pager disabled so all
-- tables can be shown inside the one-minute limit.
\pset pager off
\pset null '[NULL]'

SELECT * FROM agency;
SELECT * FROM loan_type;
SELECT * FROM property_type;
SELECT * FROM loan_purpose;
SELECT * FROM owner_occupancy;
SELECT * FROM preapproval;
SELECT * FROM action_taken;
SELECT * FROM msamd;
SELECT * FROM state;
SELECT * FROM county;
SELECT * FROM ethnicity;
SELECT * FROM race;
SELECT * FROM sex;
SELECT * FROM purchaser_type;
SELECT * FROM denial_reason;
SELECT * FROM hoepa_status;
SELECT * FROM lien_status;
SELECT * FROM location LIMIT 5;
SELECT * FROM application LIMIT 5;
SELECT * FROM application_applicant_race LIMIT 5;
SELECT * FROM application_co_applicant_race LIMIT 5;
SELECT * FROM application_denial_reason LIMIT 5;
