#!/usr/bin/env python3
"""Profile the Project 2 HMDA source without third-party dependencies."""

from __future__ import annotations

import csv
import json
import sys
from collections import defaultdict
from pathlib import Path


CODE_NAME_GROUPS = {
    "agency": ("agency_code", ("agency_name", "agency_abbr")),
    "loan_type": ("loan_type", ("loan_type_name",)),
    "property_type": ("property_type", ("property_type_name",)),
    "loan_purpose": ("loan_purpose", ("loan_purpose_name",)),
    "owner_occupancy": ("owner_occupancy", ("owner_occupancy_name",)),
    "preapproval": ("preapproval", ("preapproval_name",)),
    "action_taken": ("action_taken", ("action_taken_name",)),
    "msamd": ("msamd", ("msamd_name",)),
    "state": ("state_code", ("state_name", "state_abbr")),
    "county": ("county_code", ("county_name",)),
    "ethnicity_applicant": (
        "applicant_ethnicity",
        ("applicant_ethnicity_name",),
    ),
    "ethnicity_coapplicant": (
        "co_applicant_ethnicity",
        ("co_applicant_ethnicity_name",),
    ),
    "sex_applicant": ("applicant_sex", ("applicant_sex_name",)),
    "sex_coapplicant": ("co_applicant_sex", ("co_applicant_sex_name",)),
    "purchaser_type": ("purchaser_type", ("purchaser_type_name",)),
    "hoepa_status": ("hoepa_status", ("hoepa_status_name",)),
    "lien_status": ("lien_status", ("lien_status_name",)),
    "edit_status": ("edit_status", ("edit_status_name",)),
}

for role in ("applicant", "co_applicant"):
    for number in range(1, 6):
        CODE_NAME_GROUPS[f"{role}_race_{number}"] = (
            f"{role}_race_{number}",
            (f"{role}_race_name_{number}",),
        )

for number in range(1, 4):
    CODE_NAME_GROUPS[f"denial_reason_{number}"] = (
        f"denial_reason_{number}",
        (f"denial_reason_name_{number}",),
    )

LOCATION_COLUMNS = (
    "county_code",
    "msamd",
    "state_code",
    "census_tract_number",
    "population",
    "minority_population",
    "hud_median_family_income",
    "tract_to_msamd_income",
    "number_of_owner_occupied_units",
    "number_of_1_to_4_family_units",
)


def sorted_values(values: set[str]) -> list[str]:
    return sorted(values, key=lambda value: (value == "", value))


def main() -> int:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "data/hmda_2017_nj_all-records_labels.csv"
    )
    destination = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("data/profile.json")

    with source.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise SystemExit("CSV has no header")

        fieldnames = tuple(reader.fieldnames)
        null_counts = {column: 0 for column in fieldnames}
        distinct_values = {column: set() for column in fieldnames}
        dependency_maps = {
            group: defaultdict(set) for group in CODE_NAME_GROUPS
        }
        locations: set[tuple[str, ...]] = set()
        repeated_nonnull = defaultdict(int)
        row_count = 0

        for row_count, row in enumerate(reader, start=1):
            for column in fieldnames:
                value = row[column]
                if value == "":
                    null_counts[column] += 1
                distinct_values[column].add(value)

            for group, (determinant, dependents) in CODE_NAME_GROUPS.items():
                dependency_maps[group][row[determinant]].add(
                    tuple(row[dependent] for dependent in dependents)
                )

            locations.add(tuple(row[column] for column in LOCATION_COLUMNS))

            for role in ("applicant", "co_applicant"):
                for number in range(1, 6):
                    if row[f"{role}_race_{number}"] != "":
                        repeated_nonnull[f"{role}_race"] += 1
            for number in range(1, 4):
                if row[f"denial_reason_{number}"] != "":
                    repeated_nonnull["denial_reason"] += 1

    dependencies = {}
    for group, (determinant, dependents) in CODE_NAME_GROUPS.items():
        mapping = dependency_maps[group]
        conflicts = {
            code: sorted([list(values) for values in mapped_values])
            for code, mapped_values in mapping.items()
            if len(mapped_values) > 1
        }
        dependencies[group] = {
            "determinant": determinant,
            "dependents": list(dependents),
            "holds": not conflicts,
            "mapping_count": len(mapping),
            "conflicts": conflicts,
            "mappings": {
                code: sorted([list(values) for values in mapped_values])
                for code, mapped_values in sorted(mapping.items())
            },
        }

    profile = {
        "source": str(source),
        "row_count": row_count,
        "column_count": len(fieldnames),
        "columns": list(fieldnames),
        "column_profiles": {
            column: {
                "null_count": null_counts[column],
                "not_null_count": row_count - null_counts[column],
                "distinct_count_including_blank": len(distinct_values[column]),
                "values": sorted_values(distinct_values[column])
                if len(distinct_values[column]) <= 100
                else None,
            }
            for column in fieldnames
        },
        "dependencies": dependencies,
        "location_columns": list(LOCATION_COLUMNS),
        "distinct_location_count": len(locations),
        "repeating_nonnull_counts": dict(repeated_nonnull),
    }

    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(profile, indent=2) + "\n", encoding="utf-8")
    print(f"Profiled {row_count:,} rows and {len(fieldnames)} columns")
    print(f"Distinct locations: {len(locations):,}")
    print(json.dumps(dict(repeated_nonnull), indent=2))
    print(f"Wrote {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
