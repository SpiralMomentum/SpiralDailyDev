"""Build assets/life_tables/life_tables.json from the raw files in tool/raw/.

Inputs (downloaded with curl, see assets/life_tables/SOURCES.md):
  raw/imf_ngdpd.json, raw/imf_countries.json  IMF WEO nominal GDP (USD)
  raw/who_<ISO3>.json                         WHO GHO LIFE_0000000035 (ex), one year
  raw/kostat_life_table.csv                   KOSIS DT_1B42 complete life table

Usage (from apps/life_balance):
  python3 -I tool/build_life_tables.py            # writes the asset
  python3 -I tool/build_life_tables.py --check    # rebuilds and compares, no write

Standard library only. All functions except main() are pure.
"""

import json
import os
import re
import sys

VERSION = "2026.11"
RETRIEVED = "2026-11-25"
IMF_YEAR = 2026
WHO_YEAR = 2023
KR_YEAR = 2024
TOP_N = 10
MAX_AGE = 100
WHO_OPEN_AGE = 85

# ISO3 (IMF/WHO) -> (ISO2, Korean name). Ranking must only produce these codes.
COUNTRIES = {
    "KOR": ("KR", "대한민국"),
    "USA": ("US", "미국"),
    "CHN": ("CN", "중국"),
    "DEU": ("DE", "독일"),
    "JPN": ("JP", "일본"),
    "GBR": ("GB", "영국"),
    "IND": ("IN", "인도"),
    "FRA": ("FR", "프랑스"),
    "RUS": ("RU", "러시아"),
    "ITA": ("IT", "이탈리아"),
    "BRA": ("BR", "브라질"),
}

KR_SOURCE = {
    "name": "국가데이터처 완전생명표(1세별)",
    "url": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1B42",
    "year": KR_YEAR,
    "retrieved": RETRIEVED,
}

WHO_SOURCE_NAME = "WHO GHO 생명표 ex"
WHO_URL = (
    "https://ghoapi.azureedge.net/api/LIFE_0000000035"
    "?$filter=SpatialDim eq '{iso3}' and TimeDim eq {year}"
)

_SEX = {"SEX_MLE": "male", "SEX_FMLE": "female"}
_AGE_GROUP = re.compile(r"AGEGROUP_YEARS(\d+)(?:-\d+|PLUS)$")


def top_countries(ngdpd, countries, year, n):
    """Top n (ISO3, value) by NGDPD in `year`, countries only (no aggregates)."""
    key = str(year)
    known = countries["countries"]
    rows = [
        (code, series[key])
        for code, series in ngdpd["values"]["NGDPD"].items()
        if code in known and key in series
    ]
    return sorted(rows, key=lambda r: r[1], reverse=True)[:n]


def parse_who(doc, year):
    """{'male': {start_age: ex}, 'female': {...}} for one year."""
    result = {"male": {}, "female": {}}
    for row in doc["value"]:
        sex = _SEX.get(row["Dim1"])
        match = _AGE_GROUP.match(row["Dim2"] or "")
        if sex is None or match is None or row["TimeDim"] != year:
            continue
        result[sex] = {**result[sex], int(match.group(1)): float(row["NumericValue"])}
    return result


def parse_kostat_csv(text):
    """(male[101], female[101]) from 'age,male,female' CSV; '#' lines ignored."""
    lines = [ln.strip() for ln in text.splitlines()]
    rows = [ln.split(",") for ln in lines if ln and not ln.startswith("#")]
    header, body = rows[0], rows[1:]
    if header != ["age", "male", "female"]:
        raise ValueError(f"unexpected header {header}")
    by_age = {int(r[0]): (float(r[1]), float(r[2])) for r in body}
    if sorted(by_age) != list(range(MAX_AGE + 1)):
        raise ValueError(f"ages must be 0..{MAX_AGE}, got {len(by_age)} rows")
    male = [by_age[a][0] for a in range(MAX_AGE + 1)]
    female = [by_age[a][1] for a in range(MAX_AGE + 1)]
    return male, female


def interpolate_abridged(points, max_age):
    """Linear interpolation between interval start ages, indexes 0..max_age."""
    knots = sorted(points)
    if knots[0] != 0 or knots[-1] != max_age:
        raise ValueError(f"knots must span 0..{max_age}, got {knots}")

    def value_at(age):
        if age in points:
            return points[age]
        lo = max(k for k in knots if k < age)
        hi = min(k for k in knots if k > age)
        return points[lo] + (points[hi] - points[lo]) * (age - lo) / (hi - lo)

    return [value_at(a) for a in range(max_age + 1)]


def extend_over_85(country_e85, korea_tail):
    """Ages 85..100: e_c(x) = e_KR(x) * e_c(85) / e_KR(85) (same sex)."""
    expected = MAX_AGE - WHO_OPEN_AGE + 1
    if len(korea_tail) != expected:
        raise ValueError(f"korea_tail must have {expected} values")
    ratio = country_e85 / korea_tail[0]
    return [v * ratio for v in korea_tail]


def validate(series):
    """Length 101, all > 0, non-increasing from age 1 (age 0 < age 1 allowed)."""
    if len(series) != MAX_AGE + 1:
        raise ValueError(f"length {len(series)}, expected {MAX_AGE + 1}")
    if any(v <= 0 for v in series):
        raise ValueError("non-positive value")
    for age in range(1, MAX_AGE):
        if series[age + 1] > series[age]:
            raise ValueError(f"increase at age {age + 1}")
    return series


def who_series(points, korea):
    """Full 0..100 series for a WHO country from its abridged points."""
    head = interpolate_abridged(points, max_age=WHO_OPEN_AGE)
    tail = extend_over_85(head[WHO_OPEN_AGE], korea[WHO_OPEN_AGE:])
    return validate([round(v, 2) for v in head[:WHO_OPEN_AGE] + tail])


def build_document(ranked_iso3, who_docs, kr_male, kr_female):
    """Assemble the asset dict. KR first, then IMF rank order."""
    def entry(name, source, male, female):
        return {"name": name, "source": source, "male": male, "female": female}

    kr = entry(COUNTRIES["KOR"][1], KR_SOURCE, validate(kr_male), validate(kr_female))
    others = {}
    for iso3 in ranked_iso3:
        if iso3 not in COUNTRIES:
            raise ValueError(f"no ISO2/name mapping for {iso3}")
        iso2, name = COUNTRIES[iso3]
        parsed = parse_who(who_docs[iso3], WHO_YEAR)
        source = {
            "name": WHO_SOURCE_NAME,
            "url": WHO_URL.format(iso3=iso3, year=WHO_YEAR),
            "year": WHO_YEAR,
            "retrieved": RETRIEVED,
        }
        others[iso2] = entry(
            name,
            source,
            who_series(parsed["male"], kr_male),
            who_series(parsed["female"], kr_female),
        )
    return {"version": VERSION, "countries": {"KR": kr, **others}}


def render(document):
    return json.dumps(document, ensure_ascii=False, indent=1) + "\n"


def main(argv):
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    raw = os.path.join(tool_dir, "raw")
    out = os.path.join(tool_dir, "..", "assets", "life_tables", "life_tables.json")

    def read(name):
        with open(os.path.join(raw, name), encoding="utf-8") as f:
            return f.read()

    ranked = top_countries(
        json.loads(read("imf_ngdpd.json")),
        json.loads(read("imf_countries.json")),
        IMF_YEAR,
        TOP_N,
    )
    iso3s = [code for code, _ in ranked]
    who_docs = {c: json.loads(read(f"who_{c}.json")) for c in iso3s}
    kr_male, kr_female = parse_kostat_csv(read("kostat_life_table.csv"))
    text = render(build_document(iso3s, who_docs, kr_male, kr_female))

    for rank, (code, value) in enumerate(ranked, start=1):
        print(f"{rank:2d} {code} {value}")
    if "--check" in argv:
        with open(out, encoding="utf-8") as f:
            same = f.read() == text
        print("up to date" if same else "OUT OF DATE")
        return 0 if same else 1
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {os.path.normpath(out)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
