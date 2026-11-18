# CS336 Project 2 — HMDA normalization

This repository converts the 2017 New Jersey HMDA labeled CSV from the Project
1 `Preliminary` table into a lossless BCNF database, validates the result, and
reconstructs the original 78-column CSV without consulting `Preliminary`.

## Source data

Download the official archive:

<https://files.consumerfinance.gov/hmda-historic-loan-data/hmda_2017_nj_all-records_labels.zip>

Unzip `hmda_2017_nj_all-records_labels.csv` into the directory from which psql
will run `sql/01_preliminary.sql`. The CSV is intentionally ignored by Git.

Expected source facts:

- 349,563 data rows
- 78 columns
- 2,135 distinct assignment-defined locations
- 351,510 applicant-race values
- 350,201 co-applicant-race values
- 45,088 denial-reason values

## Run order

From psql:

```sql
\i sql/01_preliminary.sql
\i sql/02_normalize.sql
\i sql/03_validate.sql
\i sql/04_export.sql
```

`01_preliminary.sql` is the retained Project 1 import. If `Preliminary` already
exists and is correct, skip it. `02_normalize.sql` recreates only Project 2
tables and never drops the preliminary table. The included scripts consistently
use `public.Preliminary`, so the documented run order works from a clean database.

After `04_export.sql`, compare the result from the ordinary Linux shell:

```sh
diff hmda_2017_nj_all-records_labels.csv reconstructed.csv
```

Success means `diff` prints nothing and exits with status 0.

## Submission files

- `docs/functional_dependencies.txt`: canonical cover and 1NF transformation
- `er-diagram/HMDA_Project_2_BCNF_ER_Diagram.pdf`: final ER diagram
- `sql/01_preliminary.sql`: Project 1 preliminary import
- `sql/02_normalize.sql`: complete BCNF creation and population
- `sql/03_validate.sql`: source-to-normalized losslessness checks
- `sql/04_export.sql`: normalized-database-only CSV report
- `sql/05_invalid_insert_tests.sql`: three rejected writes for the video
- `sql/06_video_selects.sql`: quick previews of every normalized table

Both required recordings must be no longer than one minute. Open the generated
CSV in a spreadsheet application and capture the required comparison
screenshot separately.
