"""template.layout 순수 함수 테스트. 실행: python3 -m unittest discover -s tools/marketing/tests -t tools/marketing"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from template.layout import Box, coverage, fit_placement, plan_screens, resolve_tilts, split_cells, split_regions  # noqa: E402

CANVAS = (1080, 1080)
PHONE = (1242, 2688)  # 세로 화면 스크린샷


class SplitRegions(unittest.TestCase):
    def test_top_caption(self):
        cap, vis = split_regions(CANVAS, 30, "top", 4)
        self.assertEqual(cap, Box(0, 0, 1080, 324))
        self.assertEqual(vis, Box(43, 324, 994, 756))  # 좌우 4% = 43px, 가장자리까지 이어짐

    def test_bottom_caption(self):
        cap, vis = split_regions(CANVAS, 30, "bottom", 4)
        self.assertEqual(cap.y, 756)
        self.assertEqual(vis.h, 756)


class FitPlacement(unittest.TestCase):
    def test_contain_never_exceeds_cell_and_keeps_ratio(self):
        p = plan_screens(CANVAS, [PHONE], caption_area_pct=30, fit="contain")[0]
        self.assertLessEqual(p.size[1], 756)
        self.assertAlmostEqual(p.size[0] / p.size[1], PHONE[0] / PHONE[1], places=2)
        self.assertEqual(p.visible.h, p.size[1])  # 잘림 없음

    def test_contain_keeps_bottom_margin(self):
        p = plan_screens(CANVAS, [PHONE], caption_area_pct=30, fit="contain", margin_pct=4)[0]
        self.assertLessEqual(p.pos[1] + p.size[1], 1080 - 43)

    def test_crop_top_fills_width_and_bleeds(self):
        p = plan_screens(CANVAS, [PHONE], caption_area_pct=30, fit="crop_top", max_width_fraction=0.9)[0]
        self.assertGreater(p.size[1], p.visible.h)   # 아래가 캔버스 밖
        self.assertEqual(p.visible.y + p.visible.h, 1080)
        self.assertEqual(p.visible.h, 756)           # 화면 영역 높이 전부 노출

    def test_two_up_cells_do_not_overlap(self):
        a, b = plan_screens(CANVAS, [PHONE, PHONE], caption_area_pct=30, fit="contain")
        self.assertLessEqual(a.pos[0] + a.size[0], b.pos[0])

    def test_unknown_fit_raises(self):
        with self.assertRaises(ValueError):
            fit_placement(PHONE, Box(0, 0, 100, 100), "cover", CANVAS)

    def test_split_cells_gap(self):
        cells = split_cells(Box(0, 0, 1000, 500), 2, 1.0, 40)
        self.assertEqual([c.w for c in cells], [480, 480])
        self.assertEqual(cells[1].x - (cells[0].x + cells[0].w), 40)


class Coverage(unittest.TestCase):
    def test_crop_top_beats_contain_on_square_canvas(self):
        contain = coverage(CANVAS, plan_screens(CANVAS, [PHONE], caption_area_pct=30, fit="contain"))
        crop = coverage(CANVAS, plan_screens(CANVAS, [PHONE], caption_area_pct=30, fit="crop_top"))
        self.assertGreater(crop["visible_area_pct"], contain["visible_area_pct"])


class Scale(unittest.TestCase):
    def test_scale_reflects_fit(self):
        contain = plan_screens(CANVAS, [PHONE], caption_area_pct=30, fit="contain")[0]
        crop = plan_screens(CANVAS, [PHONE], caption_area_pct=30, fit="crop_top", max_width_fraction=0.9)[0]
        self.assertAlmostEqual(contain.scale, contain.size[0] / PHONE[0])
        self.assertLess(contain.scale, 0.3)   # 1:1 에서 세로 화면 전체는 글자가 1/3 이하로 줄어든다
        self.assertGreater(crop.scale, 0.7)
        self.assertEqual(coverage(CANVAS, [contain])["min_screen_scale"], round(contain.scale, 2))


class Stack(unittest.TestCase):
    def stack(self, n, **kw):
        return plan_screens(CANVAS, [PHONE] * n, caption_area_pct=34, fit="crop_top", arrange="stack",
                            stack={"dx_pct": 10, "dy_pct": 5, "scale_step": 0.9, "side": "left"}, **kw)

    def test_front_card_is_largest_and_back_cards_peek_out_on_the_left(self):
        a, b, c = self.stack(3)          # 뒤 -> 앞
        self.assertLess(a.size[0], b.size[0])
        self.assertLess(b.size[0], c.size[0])
        self.assertLess(a.pos[0], b.pos[0])
        self.assertLess(b.pos[0], c.pos[0])
        self.assertGreater(a.pos[1], b.pos[1])   # 뒤 카드가 더 아래

    def test_shift_pushes_group_toward_edge(self):
        base = self.stack(2)[-1]
        shifted = self.stack(2, shift_x_pct=12)[-1]
        self.assertEqual(shifted.pos[0] - base.pos[0], round(1080 * 0.12))

    def test_tilts_align_to_front_and_pad_back(self):
        self.assertEqual(resolve_tilts([5, -3], 0, 3), [0.0, 5.0, -3.0])
        self.assertEqual(resolve_tilts([], 4, 2), [4.0, 4.0])
        self.assertEqual([p.tilt for p in self.stack(2, tilts=[6, -2])], [6.0, -2.0])

    def test_unknown_arrange_raises(self):
        with self.assertRaises(ValueError):
            plan_screens(CANVAS, [PHONE], caption_area_pct=30, arrange="fan")


class EdgeBleed(unittest.TestCase):
    def test_visible_width_drops_when_pushed_off_edge(self):
        inside = plan_screens(CANVAS, [PHONE], caption_area_pct=34, fit="crop_top", max_width_fraction=0.9)
        pushed = plan_screens(CANVAS, [PHONE], caption_area_pct=34, fit="crop_top", max_width_fraction=0.9, shift_x_pct=25)
        self.assertEqual(coverage(CANVAS, inside)["min_visible_width_pct"], 100.0)
        self.assertLess(coverage(CANVAS, pushed)["min_visible_width_pct"], 92)


if __name__ == "__main__":
    unittest.main()
