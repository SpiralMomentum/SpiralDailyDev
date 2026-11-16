"""CLI: python tools/marketing/template render <preset.yaml> --copy copy/x.yaml --voice NAME [--shots DIR] [--glob PATTERN] [--out DIR]

결과는 stdout JSON 한 줄, 장별 PASS/FAIL 은 stderr.
"""
from __future__ import annotations

import argparse
import json
import yaml
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # tools/marketing

from template.checks import content_bbox_crop, normalize_profile, suggest_crop  # noqa: E402
from template.copy import compose  # noqa: E402
from template.render import MARKETING_DIR, find_screenshots, load_preset, render_to_files  # noqa: E402



def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="template")
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("render")
    r.add_argument("preset", type=Path)
    r.add_argument("--app", type=Path, required=True, help="앱 프로필 yaml (apps/<이름>.yaml)")
    r.add_argument("--copy", type=Path, help="카피 yaml (템플릿에 자리표시자가 있으면 필수)")
    r.add_argument("--voice", help="카피 yaml 의 voices 키")
    r.add_argument("--shots", type=Path, help="스크린샷 폴더 (기본: 앱 프로필의 shots_dir)")
    r.add_argument("--glob", default="*.png")
    r.add_argument("--out", type=Path, default=MARKETING_DIR / "out" / "template")
    r.add_argument("--assets", type=Path, default=MARKETING_DIR / "assets")
    sg = sub.add_parser("suggest-crop", help="화면 이름의 크롭 높이는 유지하고, 내용이 가장 많은 세로 위치를 제안한다")
    sg.add_argument("--app", type=Path, required=True)
    sg.add_argument("--screen", required=True)
    a = p.parse_args(argv)
    if a.cmd == "suggest-crop":
        prof = yaml.safe_load(a.app.read_text(encoding="utf-8"))
        entry = prof["screens"][a.screen]
        shots = find_screenshots(MARKETING_DIR / prof["shots_dir"], "*.png")
        x0, y0, x1, y1 = entry.get("crop") or [0, 0, 1, 1]
        from PIL import Image
        img = Image.open(shots[entry["shot"]])
        # R2: 크롭이 화면 전체면 내용 영역(content_bbox_crop), 아니면 높이 유지하고 위치만 이동(suggest_crop)
        full = round(y1 - y0, 2) >= 1.0
        suggested = content_bbox_crop(img) if full else suggest_crop(img, round(y1 - y0, 2), current_y0=y0)
        print(json.dumps({"screen": a.screen, "current": [x0, y0, x1, y1], "rule": "content_bbox" if full else "slide_window",
                          "suggested": suggested}))
        return 0
    profile = normalize_profile(yaml.safe_load(a.app.read_text(encoding="utf-8")))
    preset = load_preset(a.preset)
    voices = yaml.safe_load(a.copy.read_text(encoding="utf-8")).get("voices") or {} if a.copy else {}
    if a.voice not in voices:
        print(json.dumps(dict(ok=False, error=f"--copy/--voice 필요. 선택지: {list(voices)}"), ensure_ascii=False))
        return 2
    preset = compose(preset, profile, voices[a.voice])
    shots = find_screenshots(a.shots or MARKETING_DIR / profile["shots_dir"], a.glob)
    if not shots:
        print(json.dumps(dict(ok=False, error="no screenshots")))
        return 2
    rows = render_to_files(preset, shots, a.out, a.assets)
    for row in rows:
        print("PASS" if row["ok"] else "FAIL", row["file"], row["detail"], *row["errors"], file=sys.stderr)
        for w in row.get("warnings", []):
            print("  WARN", w, file=sys.stderr)
    print(json.dumps(dict(ok=all(r["ok"] for r in rows), preset=preset["template"]["id"], out=str(a.out), files=[r["file"] for r in rows]), ensure_ascii=False))
    return 0 if all(r["ok"] for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
