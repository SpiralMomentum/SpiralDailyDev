import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from build_life_tables import (  # noqa: E402
    extend_over_85,
    interpolate_abridged,
    parse_kostat_csv,
    parse_who,
    top_countries,
    validate,
)


class InterpolateAbridgedTest(unittest.TestCase):
    def test_linear_between_knots(self):
        series = interpolate_abridged({0: 80.0, 1: 79.5, 5: 75.6, 10: 70.6}, max_age=10)
        self.assertEqual(len(series), 11)
        self.assertAlmostEqual(series[0], 80.0)
        self.assertAlmostEqual(series[1], 79.5)
        self.assertAlmostEqual(series[2], 78.525)
        self.assertAlmostEqual(series[5], 75.6)
        self.assertAlmostEqual(series[7], 73.6)
        self.assertAlmostEqual(series[10], 70.6)

    def test_missing_last_knot_raises(self):
        with self.assertRaises(ValueError):
            interpolate_abridged({0: 80.0, 5: 75.0}, max_age=10)


class ExtendOver85Test(unittest.TestCase):
    def test_scales_korea_shape(self):
        korea_tail = [8.0 - 0.4 * i for i in range(16)]  # 85..100: 8.0 .. 2.0
        result = extend_over_85(country_e85=7.0, korea_tail=korea_tail)
        self.assertEqual(len(result), 16)
        self.assertAlmostEqual(result[0], 7.0)
        self.assertAlmostEqual(result[1], korea_tail[1] * 7.0 / 8.0)
        self.assertAlmostEqual(result[15], 2.0 * 7.0 / 8.0)

    def test_wrong_tail_length_raises(self):
        with self.assertRaises(ValueError):
            extend_over_85(country_e85=7.0, korea_tail=[8.0, 7.0])


class ValidateTest(unittest.TestCase):
    def _ok(self):
        return [80.0] + [79.5 - 0.7 * i for i in range(100)]

    def test_valid_series_passes(self):
        validate(self._ok())

    def test_age0_below_age1_allowed(self):
        s = self._ok()
        s[0] = 79.0
        validate(s)

    def test_wrong_length(self):
        with self.assertRaises(ValueError):
            validate(self._ok()[:100])

    def test_non_positive(self):
        s = self._ok()
        s[100] = 0.0
        with self.assertRaises(ValueError):
            validate(s)

    def test_increase_after_age1(self):
        s = self._ok()
        s[50] = s[49] + 0.1
        with self.assertRaises(ValueError):
            validate(s)


class ParseKostatCsvTest(unittest.TestCase):
    def test_parses_comment_header_and_rows(self):
        rows = "\n".join(f"{a},{90 - a * 0.8:.1f},{95 - a * 0.9:.1f}" for a in range(101))
        text = "# source comment\nage,male,female\n" + rows + "\n"
        male, female = parse_kostat_csv(text)
        self.assertEqual(len(male), 101)
        self.assertAlmostEqual(male[0], 90.0)
        self.assertAlmostEqual(female[100], 5.0)

    def test_missing_age_raises(self):
        text = "age,male,female\n0,80.8,86.6\n"
        with self.assertRaises(ValueError):
            parse_kostat_csv(text)


class ParseWhoTest(unittest.TestCase):
    def _row(self, sex, group, value, year=2023):
        return {"Dim1": sex, "Dim2": group, "TimeDim": year, "NumericValue": value}

    def test_groups_by_sex_and_start_age(self):
        doc = {"value": [
            self._row("SEX_MLE", "AGEGROUP_YEARS00-01", 76.0),
            self._row("SEX_MLE", "AGEGROUP_YEARS01-04", 75.5),
            self._row("SEX_MLE", "AGEGROUP_YEARS85PLUS", 6.0),
            self._row("SEX_FMLE", "AGEGROUP_YEARS05-09", 77.0),
            self._row("SEX_BTSX", "AGEGROUP_YEARS00-01", 78.0),
            self._row("SEX_MLE", "AGEGROUP_YEARS00-01", 70.0, year=2022),
        ]}
        parsed = parse_who(doc, year=2023)
        self.assertEqual(parsed["male"], {0: 76.0, 1: 75.5, 85: 6.0})
        self.assertEqual(parsed["female"], {5: 77.0})


class TopCountriesTest(unittest.TestCase):
    def test_excludes_aggregates_and_sorts(self):
        ngdpd = {"values": {"NGDPD": {
            "USA": {"2026": 30.0}, "WEOWORLD": {"2026": 100.0},
            "CHN": {"2026": 20.0}, "KOR": {"2026": 2.0}, "DEU": {"2025": 99.0},
        }}}
        countries = {"countries": {"USA": {}, "CHN": {}, "KOR": {}, "DEU": {}}}
        ranked = top_countries(ngdpd, countries, year=2026, n=2)
        self.assertEqual(ranked, [("USA", 30.0), ("CHN", 20.0)])


if __name__ == "__main__":
    unittest.main()
