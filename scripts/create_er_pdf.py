#!/usr/bin/env python3
"""Create the final vector ER diagram PDF for CS336 Project 2."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas


PAGE = (36 * 72, 24 * 72)
OUTPUT = Path("er-diagram/HMDA_Project_2_BCNF_ER_Diagram.pdf")

NAVY = colors.HexColor("#18324A")
BLUE = colors.HexColor("#DDECF7")
GREEN = colors.HexColor("#DFF1E5")
GOLD = colors.HexColor("#F6E8BF")
PURPLE = colors.HexColor("#E9DFF4")
INK = colors.HexColor("#1F2933")
MUTED = colors.HexColor("#52606D")
LINE = colors.HexColor("#486581")


TABLES = {
    "agency": (50, 1430, 330, 160, BLUE, [
        ("PK", "agency_code", "SMALLINT"),
        ("", "agency_name", "TEXT NOT NULL"),
        ("", "agency_abbr", "TEXT NOT NULL"),
    ]),
    "loan_type": (405, 1430, 300, 140, BLUE, [
        ("PK", "loan_type", "SMALLINT"),
        ("", "loan_type_name", "TEXT NOT NULL"),
    ]),
    "property_type": (730, 1430, 330, 140, BLUE, [
        ("PK", "property_type", "SMALLINT"),
        ("", "property_type_name", "TEXT NOT NULL"),
    ]),
    "loan_purpose": (1085, 1430, 330, 140, BLUE, [
        ("PK", "loan_purpose", "SMALLINT"),
        ("", "loan_purpose_name", "TEXT NOT NULL"),
    ]),
    "owner_occupancy": (1440, 1430, 355, 140, BLUE, [
        ("PK", "owner_occupancy", "SMALLINT"),
        ("", "owner_occupancy_name", "TEXT NOT NULL"),
    ]),
    "preapproval": (1820, 1430, 310, 140, BLUE, [
        ("PK", "preapproval", "SMALLINT"),
        ("", "preapproval_name", "TEXT NOT NULL"),
    ]),
    "action_taken": (2155, 1430, 355, 140, BLUE, [
        ("PK", "action_taken", "SMALLINT"),
        ("", "action_taken_name", "TEXT NOT NULL"),
    ]),
    "msamd": (80, 1140, 280, 140, GREEN, [
        ("PK", "msamd", "INTEGER"),
        ("", "msamd_name", "TEXT"),
    ]),
    "state": (385, 1140, 280, 160, GREEN, [
        ("PK", "state_code", "SMALLINT"),
        ("", "state_name", "TEXT NOT NULL"),
        ("", "state_abbr", "TEXT NOT NULL"),
    ]),
    "county": (80, 940, 280, 140, GREEN, [
        ("PK", "county_code", "SMALLINT"),
        ("", "county_name", "TEXT NOT NULL"),
    ]),
    "location": (80, 360, 640, 520, GREEN, [
        ("PK", "location_id", "BIGSERIAL"),
        ("FK/AK", "county_code", "SMALLINT"),
        ("FK/AK", "msamd", "INTEGER"),
        ("FK/AK", "state_code", "SMALLINT NOT NULL"),
        ("AK", "census_tract_number", "TEXT"),
        ("AK", "population", "INTEGER"),
        ("AK", "minority_population", "NUMERIC"),
        ("AK", "hud_median_family_income", "INTEGER"),
        ("AK", "tract_to_msamd_income", "NUMERIC"),
        ("AK", "number_of_owner_occupied_units", "INTEGER"),
        ("AK", "number_of_1_to_4_family_units", "INTEGER"),
    ]),
    "application": (850, 420, 760, 810, GOLD, [
        ("PK", "application_id", "BIGINT"),
        ("", "as_of_year", "SMALLINT NOT NULL"),
        ("", "respondent_id", "TEXT NOT NULL"),
        ("FK", "agency_code", "SMALLINT NOT NULL"),
        ("FK", "loan_type", "SMALLINT NOT NULL"),
        ("FK", "property_type", "SMALLINT NOT NULL"),
        ("FK", "loan_purpose", "SMALLINT NOT NULL"),
        ("FK", "owner_occupancy", "SMALLINT NOT NULL"),
        ("", "loan_amount_000s", "INTEGER"),
        ("FK", "preapproval", "SMALLINT NOT NULL"),
        ("FK", "action_taken", "SMALLINT NOT NULL"),
        ("FK", "location_id", "BIGINT NOT NULL"),
        ("FK", "applicant_ethnicity", "SMALLINT NOT NULL"),
        ("FK", "co_applicant_ethnicity", "SMALLINT NOT NULL"),
        ("FK", "applicant_sex", "SMALLINT NOT NULL"),
        ("FK", "co_applicant_sex", "SMALLINT NOT NULL"),
        ("", "applicant_income_000s", "INTEGER"),
        ("FK", "purchaser_type", "SMALLINT NOT NULL"),
        ("", "rate_spread", "NUMERIC"),
        ("FK", "hoepa_status", "SMALLINT NOT NULL"),
        ("FK", "lien_status", "SMALLINT NOT NULL"),
    ]),
    "application_applicant_race": (1700, 1060, 420, 180, PURPLE, [
        ("PK/FK", "application_id", "BIGINT"),
        ("PK", "race_number", "SMALLINT (1-5)"),
        ("FK", "race", "SMALLINT NOT NULL"),
    ]),
    "application_co_applicant_race": (1700, 800, 420, 180, PURPLE, [
        ("PK/FK", "application_id", "BIGINT"),
        ("PK", "race_number", "SMALLINT (1-5)"),
        ("FK", "race", "SMALLINT NOT NULL"),
    ]),
    "application_denial_reason": (1700, 540, 420, 180, PURPLE, [
        ("PK/FK", "application_id", "BIGINT"),
        ("PK", "reason_number", "SMALLINT (1-3)"),
        ("FK", "denial_reason", "SMALLINT NOT NULL"),
    ]),
    "race": (2220, 965, 320, 140, PURPLE, [
        ("PK", "race", "SMALLINT"),
        ("", "race_name", "TEXT NOT NULL"),
    ]),
    "denial_reason": (2200, 570, 350, 140, PURPLE, [
        ("PK", "denial_reason", "SMALLINT"),
        ("", "denial_reason_name", "TEXT NOT NULL"),
    ]),
    "ethnicity": (80, 100, 330, 140, BLUE, [
        ("PK", "ethnicity", "SMALLINT"),
        ("", "ethnicity_name", "TEXT NOT NULL"),
    ]),
    "sex": (440, 100, 300, 140, BLUE, [
        ("PK", "sex", "SMALLINT"),
        ("", "sex_name", "TEXT NOT NULL"),
    ]),
    "purchaser_type": (770, 100, 380, 140, BLUE, [
        ("PK", "purchaser_type", "SMALLINT"),
        ("", "purchaser_type_name", "TEXT NOT NULL"),
    ]),
    "hoepa_status": (1180, 100, 350, 140, BLUE, [
        ("PK", "hoepa_status", "SMALLINT"),
        ("", "hoepa_status_name", "TEXT NOT NULL"),
    ]),
    "lien_status": (1560, 100, 330, 140, BLUE, [
        ("PK", "lien_status", "SMALLINT"),
        ("", "lien_status_name", "TEXT NOT NULL"),
    ]),
}


def center(name: str) -> tuple[float, float]:
    x, y, w, h, _, _ = TABLES[name]
    return x + w / 2, y + h / 2


def draw_relation(c: canvas.Canvas, points: list[tuple[float, float]],
                  left_card: str = "1", right_card: str = "N") -> None:
    c.setStrokeColor(LINE)
    c.setLineWidth(2)
    c.setLineJoin(1)
    path = c.beginPath()
    path.moveTo(*points[0])
    for point in points[1:]:
        path.lineTo(*point)
    c.drawPath(path)


def draw_table(c: canvas.Canvas, name: str) -> None:
    x, y, w, h, fill, fields = TABLES[name]
    c.setFillColor(colors.white)
    c.setStrokeColor(NAVY)
    c.setLineWidth(2)
    c.roundRect(x, y, w, h, 8, fill=1, stroke=1)
    c.setFillColor(fill)
    c.roundRect(x, y + h - 42, w, 42, 8, fill=1, stroke=0)
    c.rect(x, y + h - 42, w, 10, fill=1, stroke=0)
    c.setFillColor(NAVY)
    c.setFont("Helvetica-Bold", 15)
    c.drawString(x + 14, y + h - 28, name.upper())

    usable = h - 55
    step = min(27, usable / max(len(fields), 1))
    baseline = y + h - 61
    for marker, field, datatype in fields:
        c.setFillColor(NAVY if marker else MUTED)
        c.setFont("Helvetica-Bold", 10)
        c.drawString(x + 12, baseline, marker)
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold" if "PK" in marker else "Helvetica", 11)
        c.drawString(x + 72, baseline, field)
        c.setFillColor(MUTED)
        c.setFont("Helvetica", 9.5)
        right = x + w - 12
        width = stringWidth(datatype, "Helvetica", 9.5)
        c.drawString(max(x + 72, right - width), baseline, datatype)
        baseline -= step


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUTPUT), pagesize=PAGE, pageCompression=1)
    width, height = PAGE
    c.setTitle("CS336 Project 2 - HMDA BCNF ER Diagram")
    c.setAuthor("CS336 Section 09 project team")

    c.setFillColor(colors.white)
    c.rect(0, 0, width, height, fill=1, stroke=0)
    c.setFillColor(NAVY)
    c.setFont("Helvetica-Bold", 28)
    c.drawString(50, height - 48, "CS336 Project 2 - HMDA 2017 NJ BCNF ER Diagram")
    c.setFillColor(MUTED)
    c.setFont("Helvetica", 13)
    c.drawString(
        50,
        height - 72,
        "Implemented schema: lossless decomposition, application-specific demographics, and shared code lookups",
    )

    # Top lookup relations: lookup 1 -> N application.
    top_names = [
        "agency", "loan_type", "property_type", "loan_purpose",
        "owner_occupancy", "preapproval", "action_taken",
    ]
    app_x, app_y, app_w, app_h, _, _ = TABLES["application"]
    for index, name in enumerate(top_names):
        x, y, w, _, _, _ = TABLES[name]
        start = (x + w / 2, y)
        end = (app_x + 55 + index * 105, app_y + app_h)
        bend_y = 1340 - index * 7
        draw_relation(c, [start, (start[0], bend_y), (end[0], bend_y), end])

    # Bottom lookup relations.
    bottom_names = ["ethnicity", "sex", "purchaser_type", "hoepa_status", "lien_status"]
    bottom_ports = [940, 1080, 1220, 1360, 1500]
    for name, port_x in zip(bottom_names, bottom_ports):
        x, y, w, h, _, _ = TABLES[name]
        start = (x + w / 2, y + h)
        end = (port_x, app_y)
        bend_y = 320
        draw_relation(c, [start, (start[0], bend_y), (end[0], bend_y), end])

    # Geographic hierarchy and location -> application.
    draw_relation(c, [(220, 1140), (220, 1095), (300, 1095), (300, 880)])
    draw_relation(c, [(525, 1140), (525, 1110), (500, 1110), (500, 880)])
    draw_relation(c, [(220, 940), (220, 910), (180, 910), (180, 880)])
    draw_relation(c, [(720, 650), (785, 650), (785, 700), (850, 700)])

    # Application -> repeating rows.
    join_names = [
        "application_applicant_race",
        "application_co_applicant_race",
        "application_denial_reason",
    ]
    app_ports_y = [1120, 900, 650]
    for name, port_y in zip(join_names, app_ports_y):
        x, y, _, h, _, _ = TABLES[name]
        draw_relation(c, [(app_x + app_w, port_y), (1660, port_y), (1660, y + h / 2), (x, y + h / 2)])

    # Shared race lookup serves both applicant roles; denial lookup serves reasons.
    draw_relation(c, [(2220, 1035), (2165, 1035), (2165, 1150), (2120, 1150)])
    draw_relation(c, [(2220, 1015), (2145, 1015), (2145, 890), (2120, 890)])
    draw_relation(c, [(2200, 640), (2160, 640), (2160, 630), (2120, 630)])

    for name in TABLES:
        draw_table(c, name)

    # Redraw cardinality labels outside table borders so they stay visible
    # after the boxes are painted over the relationship lines.
    c.setFillColor(NAVY)
    c.setFont("Helvetica-Bold", 12)
    for index, name in enumerate(top_names):
        x, y, w, _, _, _ = TABLES[name]
        c.drawString(x + w / 2 + 6, y - 17, "1")
        c.drawString(app_x + 61 + index * 105, app_y + app_h + 7, "N")
    for name, port_x in zip(bottom_names, bottom_ports):
        x, y, w, h, _, _ = TABLES[name]
        c.drawString(x + w / 2 + 6, y + h + 7, "1")
        c.drawString(port_x + 6, app_y - 17, "N")
    for x, y, label in [
        (226, 1123, "1"), (306, 887, "N"),
        (531, 1123, "1"), (506, 887, "N"),
        (226, 923, "1"), (186, 887, "N"),
        (728, 658, "1"), (830, 708, "N"),
        (1620, 1128, "1"), (1680, 1158, "N"),
        (1620, 908, "1"), (1680, 898, "N"),
        (1620, 658, "1"), (1680, 638, "N"),
        (2198, 1043, "1"), (2130, 1158, "N"),
        (2198, 1023, "1"), (2130, 898, "N"),
        (2178, 648, "1"), (2130, 638, "N"),
    ]:
        c.drawString(x, y, label)

    c.setFillColor(MUTED)
    c.setFont("Helvetica", 11)
    c.drawString(1950, 190, "Cardinality labels: 1 = referenced row; N = referencing rows")
    c.drawString(1950, 170, "PK = primary key   FK = foreign key   AK = ten-column alternate location key")
    c.drawString(1950, 150, "Applicant is not a reusable person entity: the source has no cross-application person ID.")
    c.drawString(1950, 130, "Universally null CSV fields are reconstructed as constants and are not redundantly stored.")

    c.showPage()
    c.save()
    print(OUTPUT)


if __name__ == "__main__":
    main()
