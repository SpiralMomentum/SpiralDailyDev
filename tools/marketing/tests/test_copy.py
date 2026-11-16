import unittest

from template.copy import assert_filled, fill_copy, placeholders


class CopyTest(unittest.TestCase):
    tpl = {"slides": [{"headline": "{{headline}}", "body": "{{body?}}", "screen": "{{screens}}",
                       "layers": {"x": {"crop": "{{crop}}"}}, "n": 3}]}

    def test_fill_raw_and_optional(self):
        out = fill_copy(self.tpl, [{"headline": "안녕", "screens": ["a", "b"], "crop": [0, 0, 1, 1]}])
        s = out["slides"][0]
        self.assertEqual((s["headline"], s["body"], s["screen"], s["layers"]["x"]["crop"], s["n"]),
                         ("안녕", "", ["a", "b"], [0, 0, 1, 1], 3))

    def test_missing_required_key(self):
        with self.assertRaises(ValueError):
            fill_copy(self.tpl, [{"screens": [], "crop": []}])

    def test_slide_count_mismatch(self):
        with self.assertRaises(ValueError):
            fill_copy(self.tpl, [])

    def test_inline_and_placeholders(self):
        tpl = {"slides": [{"t": "지금 {{name}} 시작"}]}
        self.assertEqual(fill_copy(tpl, [{"name": "앱"}])["slides"][0]["t"], "지금 앱 시작")
        self.assertEqual(placeholders(self.tpl), {"headline": True, "body": False, "screens": True, "crop": True})
        with self.assertRaises(ValueError):
            assert_filled(self.tpl)


if __name__ == "__main__":
    unittest.main()


class AppProfileTest(unittest.TestCase):
    profile = {"name": "다른 앱", "font": "f", "brand": {"primary": "#111111"},
               "screens": {"home": {"shot": 2, "crop": [0, 0, 1, 0.5]}, "tab": {"shot": 3}}}
    tpl = {"color": {"p": "{{app.brand.primary}}", "f": "{{app.font}}"},
           "slides": [{"headline": "{{headline}}", "shot": "{{shot}}", "crop": "{{crop}}", "t": "{{app.name}} 시작"}]}

    def test_compose_fills_everything(self):
        from template.copy import compose, placeholders
        out = compose(self.tpl, self.profile, [{"headline": "문구", "screen": "tab"}])
        s = out["slides"][0]
        self.assertEqual((out["color"], s["shot"], s["crop"], s["t"]),
                         ({"p": "#111111", "f": "f"}, 3, [0, 0, 1, 1], "다른 앱 시작"))
        self.assertEqual(placeholders(out), {})

    def test_unknown_screen_and_missing_app_key(self):
        from template.copy import compose
        with self.assertRaises(ValueError):
            compose(self.tpl, self.profile, [{"headline": "x", "screen": "nope"}])
        with self.assertRaises(ValueError):
            compose(self.tpl, {"screens": self.profile["screens"]}, [{"headline": "x", "screen": "tab"}])

    def test_stack_prepends_with(self):
        from template.copy import derive_screen
        d = derive_screen([{"screen": "home", "with": ["tab"]}], self.profile["screens"], stack=True)[0]
        self.assertEqual((d["screens"], d["shot"]), (["tab", "home"], 2))


class ChecksTest(unittest.TestCase):
    def test_contrast_known_values(self):
        from template.checks import contrast, required_contrast
        self.assertEqual(contrast("#000000", "#FFFFFF"), 21.0)
        self.assertEqual(required_contrast(72, 800, 2.0), 3.0)   # 36 CSS px
        self.assertEqual(required_contrast(36, 400, 2.0), 4.5)   # 18 CSS px

    def test_on_dark_rule_is_deterministic(self):
        from template.checks import DARK_BG, contrast, normalize_profile
        a = normalize_profile({"brand": {"primary": "#0B3F6A"}})["brand"]["on_dark"]
        self.assertEqual(a, normalize_profile({"brand": {"primary": "#0B3F6A"}})["brand"]["on_dark"])
        self.assertGreaterEqual(contrast(a, DARK_BG), 4.5)
        self.assertEqual(normalize_profile({"brand": {"primary": "#FFC107"}})["brand"]["on_dark"], "#FFC107")

    def test_empty_band_flags_old_map_crop(self):
        from pathlib import Path
        from PIL import Image
        from template.checks import EMPTY_BAND_MAX_PCT, empty_band_pct, suggest_crop
        shot = Path(__file__).resolve().parent.parent / "assets/shots/world_of_beast/ko/3_map.png"
        if not shot.exists():
            self.skipTest("스크린샷 없음")
        im = Image.open(shot)
        w, h = im.size
        self.assertGreater(empty_band_pct(im.crop((0, 0, w, int(h * 0.6)))), EMPTY_BAND_MAX_PCT)
        x0, y0, x1, y1 = suggest_crop(im, 0.3)
        self.assertLessEqual(empty_band_pct(im.crop((0, int(h * y0), w, int(h * y1)))), EMPTY_BAND_MAX_PCT)


class ContentBboxTest(unittest.TestCase):
    def test_bbox_is_idempotent_for_centered_card(self):
        from PIL import Image, ImageDraw
        from template.checks import content_bbox_crop, suggest_crop
        im = Image.new("RGB", (320, 640), "#FFF7EE")
        d = ImageDraw.Draw(im)
        for y in range(200, 440, 20):
            d.line((40, y, 280, y), fill="#3C2D25", width=3)
        x0, y0, x1, y1 = content_bbox_crop(im)
        self.assertLess(y0, 200 / 640)
        self.assertGreater(y1, 440 / 640)
        crop = im.crop((0, int(640 * y0), 320, int(640 * y1)))
        self.assertEqual(suggest_crop(im, round(y1 - y0, 2), current_y0=y0)[1], y0)
        self.assertGreater(crop.height, 0)
