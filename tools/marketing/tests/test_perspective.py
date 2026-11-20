"""template.perspective 순수 함수 테스트."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from PIL import Image  # noqa: E402

from template.layout import resolve_poses  # noqa: E402
from template.perspective import perspective_coeffs, project_corners, solve_linear, warp_card  # noqa: E402


class Perspective(unittest.TestCase):
    def test_solve_linear(self):
        x = solve_linear([[2, 1], [1, 3]], [5, 10])
        self.assertAlmostEqual(x[0], 1.0)
        self.assertAlmostEqual(x[1], 3.0)

    def test_identity_coeffs(self):
        quad = [(0, 0), (100, 0), (100, 200), (0, 200)]
        c = perspective_coeffs(quad, quad)
        for got, want in zip(c, [1, 0, 0, 0, 1, 0, 0, 0]):
            self.assertAlmostEqual(got, want, places=6)

    def test_no_rotation_keeps_rectangle(self):
        pts = project_corners(100, 200, 0, 0, 0)
        self.assertEqual([(round(x), round(y)) for x, y in pts], [(-50, -100), (50, -100), (50, 100), (-50, 100)])

    def test_yaw_makes_one_side_taller(self):
        tl, tr, br, bl = project_corners(100, 200, 30, 0, 0)
        left_h, right_h = bl[1] - tl[1], br[1] - tr[1]
        self.assertNotAlmostEqual(left_h, right_h, places=1)   # 원근: 한쪽이 더 커 보인다
        self.assertAlmostEqual(tl[0] + br[0], tr[0] + bl[0], places=6)  # 평행사변형 대칭은 깨지지 않는다

    def test_roll_only_is_pure_rotation(self):
        tl, tr, br, bl = project_corners(100, 100, 0, 0, 90)
        self.assertAlmostEqual(abs(tr[0] - tl[0]), 0, places=6)

    def test_warp_returns_center_inside_output(self):
        card = Image.new("RGBA", (120, 200), (255, 255, 255, 255))
        out, (cx, cy) = warp_card(card, 25, 10, 4)
        self.assertGreater(out.width, 0)
        self.assertTrue(0 < cx < out.width and 0 < cy < out.height)
        self.assertEqual(out.getpixel((int(cx), int(cy)))[3], 255)   # 카드 중심은 불투명

    def test_resolve_poses(self):
        self.assertEqual(resolve_poses([{"yaw": 20}], [], 0, 2), [(0.0, 0.0, 0.0), (0.0, 20.0, 0.0)])
        self.assertEqual(resolve_poses([], [5], 0, 1), [(5.0, 0.0, 0.0)])


if __name__ == "__main__":
    unittest.main()
