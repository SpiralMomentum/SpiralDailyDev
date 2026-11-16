"""한 앱으로 템플릿 변형을 대량 생성한다 (앱 프로필 apps/<이름>.yaml + 카피 copy/<이름>.yaml). 카피(copy/*.yaml) x 스타일(STYLES) 조합을 프리셋 dict 로 만들어 렌더한다.

사용: python3 tools/marketing/variations.py --app daily_memo [--copy copy/daily_memo.yaml] [--voice V --style S] [--out DIR]

스타일의 `visual` 값
  none   : 앱 화면 없이 문장만
  popout : 기존 ui_popout (크롭 카드를 y_pct 위치에 걸침). 화면 노출량은 y_pct 에 우연히 좌우된다.
  screen : 레이아웃 모델. 캡션/화면 영역을 나누고 fit(contain | crop_top)으로 화면을 맞춘다. 노출 비율을 검증한다.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from types import MappingProxyType

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from template.checks import normalize_profile
from template.copy import compose
from template.render import MARKETING_DIR, find_screenshots, render_to_files  # noqa: E402



# --- 카피 파일 ---

def load_app(name_or_path: str) -> dict:
    """앱 프로필. 이름(daily_memo) 또는 경로."""
    path = Path(name_or_path)
    if not path.suffix:
        path = MARKETING_DIR / "apps" / f"{name_or_path}.yaml"
    return normalize_profile(yaml.safe_load(path.read_text(encoding="utf-8")))


def load_copy(path: Path, screens: dict) -> dict:
    """카피 파일 -> voices {이름: 슬라이드 목록}. 화면 이름이 앱 프로필 screens 에 없으면 ValueError."""
    voices = yaml.safe_load(path.read_text(encoding="utf-8")).get("voices") or {}
    names = lambda x: [x["screen"]] if isinstance(x["screen"], str) else list(x["screen"])  # noqa: E731
    bad = [f"{v}[{i}]" for v, sl in voices.items() for i, x in enumerate(sl)
           if "headline" not in x or "screen" not in x or not set(names(x) + list(x.get("with", []))) <= screens.keys()
           or len(names(x)) > 2 or len(names(x)) + len(x.get("with", [])) > 3]
    if not voices or bad:
        raise ValueError(f"{path}: voices 가 비었거나 headline·screen(앱 프로필에 등록된 이름, 최대 2개) 오류: {bad}")
    return voices


def default_copy(app: dict) -> Path:
    return MARKETING_DIR / "copy" / f"{app['id']}.yaml"


def shots_of(app: dict) -> list:
    return find_screenshots(MARKETING_DIR / app["shots_dir"], "*.png")


# --- 스타일 ---
PALETTES = MappingProxyType({
    "pastel": ["#D7F0E6", "#FBE3D6", "#FFF3C4", "#E3F1D6", "#E6E1F7"],
    "paper": ["#F6F3EC"] * 4,
    "brand": ["{{app.brand.primary}}"] * 4,
    "notion": ["#CFE6F7", "#F6F3EC", "#FFE58A", "#BFE6DD"],
    "dark": ["#161616"] * 4,
})

STYLES = MappingProxyType({
    # 카드 계열 (원래 ui_popout 이었으나 검사 사각지대라 3회차에 screen 레이어로 옮김. 모양 값은 유지)
    "left_tilt": dict(visual="screen", fit="crop_top", palette="pastel", page=True, cap_top=8, cap_area=34, min_visible=60,
                      max_w=0.86, tilts_by_slide=[[-3]]),
    "center_flat": dict(visual="screen", fit="crop_top", palette="notion", align="center", cap_top=8, cap_area=34,
                        min_visible=60, max_w=0.84),
    "dark_card": dict(visual="screen", fit="crop_top", palette="dark", dark=True, cap_top=8, cap_area=34, min_visible=60,
                      max_w=0.9, shadow="tailwind_2xl"),
    "paper_grid": dict(visual="screen", fit="crop_top", palette="paper", bg_kind="pattern", cap_top=8, cap_area=34,
                       min_visible=60, max_w=0.9, tilts_by_slide=[[2]]),
    "big_card": dict(visual="screen", fit="crop_top", palette="pastel", card_w=1.0, radius=0, cap_top=8, cap_area=34,
                     min_visible=60, max_w=1.0, shadow="tailwind_sm"),
    "text_only": dict(visual="none", palette="brand", h_px=104, cap_top=24, emph="{{app.brand.on_dark}}"),
    # 레이아웃 모델 계열: 화면 영역을 보장하고 노출 비율을 검증한다
    "screen_crop": dict(visual="screen", fit="crop_top", palette="pastel", cap_top=8, cap_area=34, min_visible=60, max_w=0.9),
    "screen_contain": dict(visual="screen", fit="contain", palette="notion", align="center", cap_top=8, cap_area=34,
                           min_visible=60, max_w=0.9),
    # 구도 변주 계열: 겹침, 장별 기울기(리서치 관측 범위 약 -3~10도), 가장자리 걸침
    "stack_tilt": dict(visual="screen", fit="crop_top", arrange="stack", palette="pastel", cap_top=8, cap_area=34,
                       min_visible=60, max_w=0.92, stack=dict(dx_pct=9, dy_pct=4, scale_step=0.9),
                       tilts_by_slide=[[5, -3], [-4, 3], [6, -2], [-3, 4]], sides=["left", "right"]),
    "edge_diag": dict(visual="screen", fit="crop_top", palette="notion", cap_top=8, cap_area=34, min_visible=60, max_w=0.88,
                      tilts_by_slide=[[-6], [5], [-4], [7]], shifts=[4, -4, 4, -4]),
    "stack_dark": dict(visual="screen", fit="crop_top", arrange="stack", palette="dark", dark=True, cap_top=8, cap_area=34,
                       min_visible=60, max_w=0.9, shadow="tailwind_2xl", stack=dict(dx_pct=12, dy_pct=5, scale_step=0.88),
                       tilts_by_slide=[[8, -4], [-6, 3], [7, -3], [-5, 5]], sides=["right", "left"]),
    # 표지 장만 강한 3D 원근, 나머지는 평면 (raw/10: Outlook·엽기떡볶이는 1장만, 기운 장 19장 중 13장이 16도 초과)
    "cover_3d": dict(visual="screen", fit="crop_top", palette="pastel", cap_top=8, cap_area=34, min_visible=60, max_w=0.86,
                     poses_by_slide=[[dict(yaw=-24, pitch=8, roll=5)], [], [], []], shifts=[6, 0, 0, 0]),
    "cover_3d_dark": dict(visual="screen", fit="crop_top", palette="dark", dark=True, cap_top=8, cap_area=34, min_visible=60,
                          max_w=0.86, shadow="tailwind_2xl",
                          poses_by_slide=[[dict(yaw=26, pitch=8, roll=-6)], [], [], [dict(yaw=-20, pitch=6, roll=4)]],
                          shifts=[-6, 0, 0, 6]),
    "cover_3d_stack": dict(visual="screen", fit="crop_top", arrange="stack", palette="notion", cap_top=8, cap_area=34,
                           min_visible=60, max_w=0.9, stack=dict(dx_pct=11, dy_pct=4, scale_step=0.9, side="left"),
                           poses_by_slide=[[dict(yaw=-30, pitch=6, roll=6), dict(yaw=-20, pitch=8, roll=3)], [], [], []]),
    "screen_dark": dict(visual="screen", fit="crop_top", palette="dark", dark=True, cap_top=8, cap_area=34,
                        min_visible=60, max_w=0.86, shadow="tailwind_2xl"),
})



def style_preset(vid: str, copy: list, app: dict, style: dict) -> dict:
    """템플릿(문구·앱 값 없음) + 앱 프로필 + 카피 -> 렌더 가능한 프리셋."""
    return compose(style_template(vid, app["screens"], style, len(copy)), app, copy, stack=style.get("arrange") == "stack")


def style_template(vid: str, screens: dict, style: dict, n: int) -> dict:
    """문구 자리표시자만 있는 템플릿. n = 장 수."""
    dark = style.get("dark", False)
    fg, sub, emph = ("#F5F5F5", "#B5B5B5", "{{app.brand.on_dark}}") if dark else ("#111111", "#5A5A5A", style.get("emph", "{{app.brand.accent}}"))
    visual = style["visual"]
    bg = {"type": "background", "kind": style.get("bg_kind", "solid"), "per_slide_color": True,
          "palette_per_slide": PALETTES[style["palette"]]}
    if style.get("bg_kind") == "pattern":
        bg["pattern"] = {"kind": "grid", "spacing_px": 54, "color": "#FFFFFF" if dark else "#000000", "opacity": 0.06}
    caption = {"type": "caption", "position": "top", "align": style.get("align", "left"), "margin_x_pct": 7,
               "margin_top_pct": style.get("cap_top", 11), "gap_px": 20,
               "text_color": fg, "body_color": sub, "emphasis_color": emph}
    card_style = {"bg": "#FFFFFF", "radius_px": style.get("radius", 36), "padding_px": 0, "shadow": style.get("shadow", "tailwind_xl")}
    brand = {"type": "brand", "logo": {"present": False},
             "page_number": {"present": style.get("page", False), "format": "n/N", "position": "top_left",
                             "margin_pct": 6, "size_px": 30, "weight": 500, "color": sub}}
    visual_layers = {
        "none": [],
        "popout": [{"type": "ui_popout", "width_fraction": style.get("card_w", 0.84), "card_style": card_style,
                    "anchor": "top_center", "x_pct": 50, "y_pct": style.get("card_y", 52)}],
        "screen": [{"type": "screen", "fit": style.get("fit", "contain"), "max_width_fraction": style.get("max_w", 0.9),
                    "gap_px": 24, "card_style": card_style, "arrange": style.get("arrange", "row"),
                    **({"stack": style["stack"]} if "stack" in style else {})}],
    }[visual]

    def slide(i: int) -> dict:
        base = {"headline": "{{headline}}", "body": "{{body?}}"}
        if visual == "screen":
            override: dict = {}
            if "tilts_by_slide" in style:
                override["tilts"] = style["tilts_by_slide"][i % len(style["tilts_by_slide"])]
            if "poses_by_slide" in style:
                override["poses"] = style["poses_by_slide"][i % len(style["poses_by_slide"])]
            if "shifts" in style:
                override["shift_x_pct"] = style["shifts"][i % len(style["shifts"])]
            if "sides" in style:
                override["stack"] = {**style["stack"], "side": style["sides"][i % len(style["sides"])]}
            return {**base, "screen": "{{screens}}", **({"layers": {"screen": override}} if override else {})}
        if visual == "popout":  # popout 은 화면 1개: 이름 -> 스크린샷 번호 + 크롭 (derive_copy 가 shot/crop 을 만든다)
            return {**base, "screenshot": "{{shot}}",
                    "layers": {"ui_popout": {"crop": "{{crop}}", "tilt_deg": style.get("tilt", 0)}}}
        return base

    preset = {
        "template": {"id": vid, "channel": "instagram_carousel", "spec_ref": "variations.py"},
        "canvas": {"width_px": 1080, "height_px": 1080, "aspect": "1:1", "format": "jpeg",
                   "max_bytes": 8388608, "alpha": False, "density": 2.0},
        "typography": {"families": {"headline": "{{app.font}}", "body": "{{app.font}}"},
                       "headline": {"size_px": style.get("h_px", 72), "weight": 800, "line_height": 1.25},
                       "body": {"size_px": 36, "weight": 400, "line_height": 1.45}},
        "color": {"palette": {"primary": "{{app.brand.primary}}", "accent": "{{app.brand.accent}}", "neutral": ["#111111"]}},
        "layers": [bg, caption, *visual_layers, {"type": "device_frame", "present": False}, brand,
                   {"type": "decoration", "kind": "none"}],
        "slides": [slide(i) for i in range(n)],
    }
    if visual == "screen":
        preset["screens"] = screens
        preset["layout"] = {"caption_area_pct": style.get("cap_area", 34), "caption_position": "top",
                            "margin_pct": 4, "visual_min_height_pct": style.get("min_visible", 60),
                            "min_screen_scale": style.get("min_scale", 0.5),
                            "min_visible_width_pct": style.get("min_vis_w", 92)}
    return preset


def main() -> None:
    ap = argparse.ArgumentParser(description="카피 파일 x 스타일 조합 렌더")
    ap.add_argument("--app", required=True, help="앱 프로필 이름(apps/<이름>.yaml) 또는 경로")
    ap.add_argument("--copy", type=Path, help="카피 yaml (기본 copy/<앱 id>.yaml)")
    ap.add_argument("--voice", help="카피 말투 이름 (생략하면 카피 파일 combos, 없으면 전체)")
    ap.add_argument("--style", help="스타일 이름 (생략하면 카피 파일 combos, 없으면 전체)")
    ap.add_argument("--out", type=Path, default=MARKETING_DIR / "out" / "variations")
    a = ap.parse_args()
    app = load_app(a.app)
    voices = load_copy(a.copy or default_copy(app), app["screens"])
    # 조합: --voice/--style 지정 > 카피 파일의 combos > 모든 말투 x 모든 스타일 (정렬 순서)
    listed = [tuple(c) for c in yaml.safe_load((a.copy or default_copy(app)).read_text(encoding="utf-8")).get("combos") or []]
    combos = ((a.voice, a.style),) if a.voice and a.style else (listed or [(v, s) for v in sorted(voices) for s in STYLES])
    unknown = [c for c in combos if c[0] not in voices or c[1] not in STYLES]
    if unknown:
        sys.exit(f"없는 조합: {unknown}. voices={list(voices)} styles={list(STYLES)}")
    a.out.mkdir(parents=True, exist_ok=True)
    shots = shots_of(app)
    summary = []
    for n, (voice, style) in enumerate(combos, 1):
        vid = f"v{n:02d}_{voice}_{style}"
        rows = render_to_files(style_preset(vid, voices[voice], app, STYLES[style]), shots, a.out, MARKETING_DIR / "assets")
        summary.append({"id": vid, "n": len(rows), "ok": all(r["ok"] for r in rows),
                        "warnings": [w for r in rows for w in r.get("warnings", [])],
                        "visible_height_pct": [r["metrics"].get("visible_height_pct") for r in rows]})
    print(json.dumps(summary, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
