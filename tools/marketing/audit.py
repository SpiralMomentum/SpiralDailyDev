"""템플릿 감사: 모든 앱 프로필 x 카피 조합 x (1:1, 9:16) 를 렌더 없이 측정해 경고 종류별 건수를 낸다.

사용: python3 audit.py [--json out/audit/latest.json]
개선 루프의 전후 비교 기준이다 (doc/.../08_템플릿_운영_규칙.md 10절).
"""
from __future__ import annotations

import argparse
import collections
import json
import re
from pathlib import Path

import yaml

from template.render import measure_slide
from variations import MARKETING_DIR, STYLES, default_copy, load_app, load_copy, shots_of, style_preset
from video import vertical

KINDS = (("대비", "contrast"), ("강조 구분", "emphasis"), ("보이는 화면의 빈 구간", "empty_band"), ("화면 노출 높이", "visible_height"),
         ("화면 배율", "scale"), ("화면 좌우 여백", "side_margin"), ("초점 노출", "focus"), ("같은 화면 반복", "repeat"), ("화면 가로 노출", "visible_width"), ("캡션", "caption_overflow"),
         ("면 안 기울기", "tilt"), ("3D 회전", "tilt_3d"))


def kind(warning: str) -> str:
    return next((k for prefix, k in KINDS if warning.startswith(prefix)), "other:" + warning.split(" ")[0])


def combos_for(app: dict, voices: dict) -> list[tuple[str, str]]:
    listed = yaml.safe_load(default_copy(app).read_text(encoding="utf-8")).get("combos") or []
    return [tuple(c) for c in listed] or [(v, s) for v in sorted(voices) for s in STYLES]


def audit_app(app_id: str) -> dict:
    app = load_app(app_id)
    voices = load_copy(default_copy(app), app["screens"])
    shots = shots_of(app)
    counts: collections.Counter = collections.Counter()
    slides = 0
    examples: dict[str, str] = {}
    for voice, style in combos_for(app, voices):
        base = style_preset(f"{voice}_{style}", voices[voice], app, STYLES[style])
        for fmt, preset in (("1:1", base), ("9:16", vertical(base))):
            for i in range(len(preset["slides"])):
                slides += 1
                for w in measure_slide(preset, i, shots)["warnings"]:
                    k = f"{fmt} {kind(w)}"
                    counts[k] += 1
                    examples.setdefault(k, f"{voice}/{style}#{i}: {w}")
    return {"slides": slides, "counts": dict(sorted(counts.items())), "examples": examples}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", type=Path)
    a = ap.parse_args()
    apps = sorted(p.stem for p in (MARKETING_DIR / "apps").glob("*.yaml") if not p.stem.startswith("_"))
    result = {a_: audit_app(a_) for a_ in apps}
    total = collections.Counter()
    for name, r in result.items():
        total.update(r["counts"])
        print(f"{name}: slides={r['slides']} warnings={sum(r['counts'].values())} {r['counts']}")
    print(f"TOTAL warnings={sum(total.values())} {dict(sorted(total.items()))}")
    if a.json:
        a.json.parent.mkdir(parents=True, exist_ok=True)
        a.json.write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
