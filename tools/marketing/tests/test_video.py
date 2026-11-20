import unittest

from template.video import Motion, ease_out, frame_state


class VideoTimingTest(unittest.TestCase):
    def test_ease_bounds(self):
        self.assertEqual((ease_out(-1), ease_out(0), ease_out(1), ease_out(2)), (0, 0, 1, 1))

    def test_start_hidden_and_offset(self):
        s = frame_state(0, Motion())
        self.assertEqual((s["cap_alpha"], s["vis_alpha"], s["exit"]), (0, 0, 0))
        self.assertEqual(s["vis_dy"], Motion().visual_rise_px)

    def test_hold_and_exit(self):
        m = Motion()
        mid = frame_state(2.0, m)
        self.assertEqual((mid["cap_alpha"], mid["vis_alpha"], mid["exit"]), (1, 1, 0))
        self.assertLess(mid["vis_dy"], 0)  # 천천히 위로 흐름
        self.assertEqual(frame_state(m.duration, m)["exit"], 1)


if __name__ == "__main__":
    unittest.main()
