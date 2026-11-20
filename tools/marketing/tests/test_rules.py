"""템플릿 개선 루프(1~12회차) 규칙의 결정성 테스트. 합성 이미지만 쓴다."""
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from template.checks import (auto_contrast, contrast, extend_limit_px, flip_neutral, side_bounds,
                             side_margin_pct)
from template.copy import mark_repeats
from template.layers import resolve_boxes


def _shot(tmp: Path, name: str, draw) -> Path:
    im = Image.new("RGB", (640, 1280), "#FFF7EE")
    draw(ImageDraw.Draw(im))
    p = tmp / name
    im.save(p)
    return p


class RulesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def test_flip_neutral_picks_white_on_navy(self):
        self.assertEqual(flip_neutral("#111111", "#0B3F6A", 3.0), "#FFFFFF")
        self.assertEqual(flip_neutral("#111111", "#FFFFFF", 3.0), "#111111")

    def test_auto_contrast_meets_wcag(self):
        preset = {"canvas": {"density": 2.0},
                  "typography": {"headline": {"size_px": 72, "weight": 800}, "body": {"size_px": 36, "weight": 400}},
                  "layers": [{"type": "background", "per_slide_color": True, "palette_per_slide": ["#FFF3C4"]},
                             {"type": "caption", "text_color": "#111111", "body_color": "#5A5A5A", "emphasis_color": "#FF8C32"}],
                  "slides": [{"headline": "[[a]]", "body": "b"}]}
        over = auto_contrast(preset)["slides"][0]["layers"]["caption"]
        self.assertGreaterEqual(contrast(over["emphasis_color"], "#FFF3C4"), 3.0)

    def test_side_bounds_strip_app_background_only(self):
        p = _shot(self.tmp, "card.png", lambda d: (d.rectangle((120, 300, 520, 900), fill="#FFFFFF", outline="#DDDDDD"),
                                                  d.text((300, 400), "x", fill="#000000")))
        box = (0, 300, 640, 900)
        self.assertGreater(side_margin_pct(str(p), box), 20)
        x0, x1 = side_bounds(str(p), box)
        self.assertLessEqual(x0, 120)
        self.assertGreaterEqual(x1, 520)

    def test_extend_limit_stops_at_large_gap(self):
        def draw(d):
            for y in range(100, 500, 24):
                d.line((40, y, 600, y), fill="#333333", width=3)
            d.line((0, 1240, 640, 1240), fill="#333333", width=6)   # 하단 바
        p = _shot(self.tmp, "gap.png", draw)
        limit = extend_limit_px(str(p), 300)
        self.assertLess(limit, 700)

    def test_mark_repeats(self):
        out = mark_repeats({"slides": [{"screen": ["a"]}, {"screen": ["b"]}, {"screen": ["a"]}]})
        self.assertEqual([s["repeat"] for s in out["slides"]], [0, 0, 1])

    def test_focus_moves_crop_and_zoom_on_repeat(self):
        layer = {"fit": "crop_top", "max_width_fraction": 0.9}
        layout = {"caption_area_pct": 34, "caption_position": "top", "margin_pct": 4}
        screens = {"s": {"shot": 0, "crop": [0, 0, 1, 0.5]}}
        focus = (0, 1100, 640, 1250)

        class F:
            def __call__(self, i):
                return focus
        fn = F()
        fn.window = lambda i, lo, hi, h: lo
        boxes = resolve_boxes((1080, 1080), layer, {"screen": ["s"]}, screens, layout, [(640, 1280)], focus_fn=fn)
        self.assertLessEqual(boxes[0][1], focus[1])
        self.assertGreaterEqual(boxes[0][3], focus[3])
        z = resolve_boxes((1080, 1080), layer, {"screen": ["s"], "repeat": 1}, screens, layout, [(640, 1280)], focus_fn=fn)
        self.assertLessEqual(z[0][1], focus[1])
        # 같은 입력이면 같은 결과
        self.assertEqual(z, resolve_boxes((1080, 1080), layer, {"screen": ["s"], "repeat": 1}, screens, layout,
                                          [(640, 1280)], focus_fn=fn))


if __name__ == "__main__":
    unittest.main()
