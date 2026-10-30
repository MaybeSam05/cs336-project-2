# Final submission checklist

## Files to submit

- [ ] `docs/functional_dependencies.txt`
- [ ] `er-diagram/HMDA_Project_2_BCNF_ER_Diagram.pdf`
- [ ] `sql/01_preliminary.sql`
- [ ] `sql/02_normalize.sql`
- [ ] `sql/04_export.sql`
- [ ] Step 3 table-preview video, at most 1 minute
- [ ] Step 4 rejected-write video, at most 1 minute
- [ ] Screenshot of `reconstructed.csv` in a spreadsheet application

The validation and helper scripts may also be submitted to make the work easy
to grade, although Canvas does not explicitly require them.

## Clean grading-machine run

1. Put the official CSV in the directory where psql starts.
2. Start psql in that directory.
3. Run:

   ```sql
   \i sql/01_preliminary.sql
   \i sql/02_normalize.sql
   \i sql/03_validate.sql
   \i sql/04_export.sql
   ```

4. Exit psql and run:

   ```sh
   diff hmda_2017_nj_all-records_labels.csv reconstructed.csv
   ```

5. Confirm `diff` produces no output.

## Step 3 video

Start recording only after the database is built and psql is open. Run:

```sql
\i sql/06_video_selects.sql
```

The script previews every normalized table with the pager disabled. Scroll at
a steady pace if necessary and stop recording before one minute.

## Step 4 video

Start a fresh recording and run:

```sql
\i sql/05_invalid_insert_tests.sql
```

Keep the three different error messages visible:

1. invalid `property_type` foreign key;
2. null required `respondent_id`; and
3. invalid applicant race position.

The script rolls back everything, so the database remains unchanged.

## Spreadsheet screenshot

Open `reconstructed.csv` in Excel, Numbers, or LibreOffice Calc. Capture the
header and several data rows. Keep the filename visible in the application
window. For stronger evidence, place the terminal beside it showing:

```sh
diff hmda_2017_nj_all-records_labels.csv reconstructed.csv
echo $?
```

The expected exit status is `0`.

## Rubric audit

- [ ] No `*_name` column appears in `application`.
- [ ] No numbered race or denial-reason column appears in a normalized table.
- [ ] Main application values are numeric except `respondent_id`.
- [ ] `application` contains only `location_id`, not raw location attributes.
- [ ] All lookup codes are protected by foreign keys.
- [ ] Nullability matches the real source data.
- [ ] The ER diagram exactly matches the SQL tables and cardinalities.
- [ ] Applicant is not represented as a reusable cross-application person.
- [ ] Export script never references `Preliminary`.
- [ ] Both videos are at most one minute.
