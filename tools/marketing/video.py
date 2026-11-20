"""카피 x 스타일 -> 세로 영상(MP4, 1080x1920). 예: python3 video.py --app daily_memo --voice maker --style cover_3d"""
import argparse
import sys
from pathlib import Path

from template.video import Motion, render_video
from variations import MARKETING_DIR, STYLES, default_copy, load_app, load_copy, shots_of, style_preset


def vertical(preset: dict) -> dict:
    """1:1 프리셋을 9:16 로 바꾼다 (캔버스 높이와 캡션 영역만)."""
    layout = {**preset["layout"], "caption_area_pct": 30} if "layout" in preset else None
    return {**preset, "canvas": {**preset["canvas"], "height_px": 1920, "aspect": "9:16"},
            **({"layout": layout} if layout else {})}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--app", required=True, help="앱 프로필 이름 또는 경로")
    ap.add_argument("--copy", type=Path)
    ap.add_argument("--voice", required=True)
    ap.add_argument("--style", required=True)
    ap.add_argument("--out", type=Path, default=MARKETING_DIR / "out" / "video")
    ap.add_argument("--seconds", type=float, default=3.2, help="장당 길이")
    a = ap.parse_args()
    app = load_app(a.app)
    voices = load_copy(a.copy or default_copy(app), app["screens"])
    if a.voice not in voices or a.style not in STYLES:
        sys.exit(f"voices={list(voices)} styles={list(STYLES)}")
    vid = f"video_{app['id']}_{a.voice}_{a.style}"
    preset = vertical(style_preset(vid, voices[a.voice], app, STYLES[a.style]))
    print(render_video(preset, shots_of(app), MARKETING_DIR / "assets", a.out / f"{vid}.mp4", Motion(duration=a.seconds)))


if __name__ == "__main__":
    main()
