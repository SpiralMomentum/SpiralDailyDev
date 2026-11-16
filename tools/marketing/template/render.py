"""프리셋(YAML) -> 장별 이미지 렌더링 -> 규격 검증.

프리셋 스키마는 doc/00_마케팅/01_소재_디자인_리서치/07_템플릿_스펙.md 를 따른다.
순수 함수(resolve_*, validate_*)와 부수효과(load_preset, render_to_files)를 분리한다.
"""
from __future__ import annotations

from functools import reduce
from pathlib import Path
from typing import Any, Mapping, Sequence

import yaml
from PIL import Image

from template.checks import EMPTY_BAND_MAX_PCT, FOCUS_MIN_PCT, SIDE_MARGIN_MAX_PCT, auto_contrast, focus_visible_pct, load_focus, side_margin_pct, check_contrast, crop_metrics
from template.copy import assert_filled
from template.layers import RENDERERS, Ctx, resolve_boxes, shot_focus_fn, shot_limit_fn, shot_trim_fn, estimate_height, plan_for_slide, screen_names, slide_override
from template.layout import coverage

MARKETING_DIR = Path(__file__).resolve().parent.parent


def load_preset(path: Path) -> dict[str, Any]:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def find_screenshots(shot_dir: Path, pattern: str) -> list[Path]:
    return sorted(shot_dir.glob(pattern))


def slide_count(preset: Mapping[str, Any]) -> int:
    return len(preset.get("slides") or [{}])


def render_slide(preset: Mapping[str, Any], index: int, shots: Sequence[Path], assets_dir: Path) -> Image.Image:
    preset = auto_contrast(preset)
    canvas_spec = preset["canvas"]
    slides = preset.get("slides") or [{}]
    ctx = Ctx(index=index, count=len(slides), slide=slides[index], shots=shots,
              typography=preset["typography"], color=preset.get("color", {}),
              density=float(canvas_spec.get("density", 2.0)), assets_dir=assets_dir,
              screens=preset.get("screens") or {}, layout=preset.get("layout") or {})
    blank = Image.new("RGB", (int(canvas_spec["width_px"]), int(canvas_spec["height_px"])), "white")
    return reduce(lambda img, layer: RENDERERS[layer["type"]](img, layer, ctx), preset["layers"], blank)


def save_image(img: Image.Image, path: Path, fmt: str, max_bytes: int) -> Path:
    if fmt.lower() == "png":
        img.save(path, "PNG")
        return path
    quality = 92
    img.save(path, "JPEG", quality=quality, subsampling=0)
    while path.stat().st_size > max_bytes and quality > 40:
        quality -= 8
        img.save(path, "JPEG", quality=quality)
    return path


def validate_file(path: Path, canvas_spec: Mapping[str, Any]) -> dict[str, Any]:
    im = Image.open(path)
    expected = (int(canvas_spec["width_px"]), int(canvas_spec["height_px"]))
    errors = [e for e, bad in (
        (f"size {im.size} != {expected}", im.size != expected),
        (f"bytes {path.stat().st_size} > {canvas_spec.get('max_bytes')}", path.stat().st_size > int(canvas_spec.get("max_bytes", 1 << 40))),
        (f"format {im.format} != {canvas_spec['format'].upper()}", im.format != canvas_spec["format"].upper()),
        (f"alpha mode {im.mode}", not canvas_spec.get("alpha", False) and im.mode in ("RGBA", "LA", "P")),
    ) if bad]
    return dict(file=path.name, ok=not errors, detail=f"{im.size[0]}x{im.size[1]} {im.format} {path.stat().st_size // 1024}KB", errors=errors)


def render_to_files(preset: Mapping[str, Any], shots: Sequence[Path], out_dir: Path, assets_dir: Path) -> list[dict[str, Any]]:
    assert_filled(preset)
    out_dir.mkdir(parents=True, exist_ok=True)
    canvas_spec = preset["canvas"]
    ext = "png" if canvas_spec["format"].lower() == "png" else "jpg"
    rows = []
    for i in range(slide_count(preset)):
        img = render_slide(preset, i, shots, assets_dir)
        path = save_image(img, out_dir / f"{preset['template']['id']}_{i}.{ext}", canvas_spec["format"], int(canvas_spec.get("max_bytes", 1 << 40)))
        rows.append({**validate_file(path, canvas_spec), **measure_slide(preset, i, shots)})
    return rows


def measure_slide(preset: Mapping[str, Any], index: int, shots: Sequence[Path]) -> dict[str, Any]:
    """그리지 않고 배치만 계산해 지표와 경고를 돌려준다 (렌더와 같은 plan_for_slide 사용).

    layout.visual_min_height_pct : 화면 노출 높이(캔버스 대비 %) 하한. 미만이면 경고.
    layout.min_visible_width_pct : 화면 가로 노출 하한. 옆으로 밀어 걸칠 때 글자가 잘리는지 본다.
    layout.max_tilt_deg          : 면 안 기울기(roll) 상한(기본 20). layout.max_3d_deg: yaw/pitch 상한(기본 40). 둘 다 우리 설정값.
    layout.min_screen_scale      : 화면 원본 대비 배율 하한. 앱 글자 크기가 배율에 비례해 줄어든다.
    layout.caption_area_pct      : 캡션이 이 영역을 넘으면 경고.
    """
    preset = auto_contrast(preset)
    layout = preset.get("layout") or {}
    canvas_spec = preset["canvas"]
    size = (int(canvas_spec["width_px"]), int(canvas_spec["height_px"]))
    slide = (preset.get("slides") or [{}])[index]
    ctx = Ctx(index=index, count=slide_count(preset), slide=slide, shots=shots, typography=preset["typography"], color={})
    warnings: list[str] = []
    metrics: dict[str, Any] = {}
    screen_layer = next((l for l in preset["layers"] if l["type"] == "screen"), None)
    if screen_layer and screen_names(slide):
        layer = slide_override(screen_layer, ctx)
        card_bg = (layer.get("card_style") or {}).get("bg", "#FFFFFF")
        bottoms, trims, focus = shot_limit_fn(shots), shot_trim_fn(shots, card_bg), shot_focus_fn(shots)
        placements = plan_for_slide(size, layer, slide, preset.get("screens") or {}, layout, [Image.open(p).size for p in shots],
                                    bottoms, trims, focus)
        main = placements[-1:] if layer.get("arrange") == "stack" else placements   # 겹침은 맨 앞 카드 기준
        metrics.update(coverage(size, main))
        max_tilt = max((abs(p.tilt) for p in placements), default=0.0)
        max_3d = max((max(abs(p.yaw), abs(p.pitch)) for p in placements), default=0.0)
        metrics["max_tilt_deg"], metrics["max_3d_deg"] = max_tilt, max_3d
        if max_tilt > float(layout.get("max_tilt_deg", 20)):
            warnings.append(f"면 안 기울기 {max_tilt}도 > {layout.get('max_tilt_deg', 20)}도")
        if max_3d > float(layout.get("max_3d_deg", 40)):
            warnings.append(f"3D 회전 {max_3d}도 > {layout.get('max_3d_deg', 40)}도 (값은 우리 설정, 관측은 16도 초과 구간까지만 구분 raw/10)")
        floor = layout.get("visual_min_height_pct")
        if floor is not None and metrics["visible_height_pct"] < float(floor):
            warnings.append(f"화면 노출 높이 {metrics['visible_height_pct']}% < 하한 {floor}%")
        w_floor = layout.get("min_visible_width_pct")
        if w_floor is not None and metrics["min_visible_width_pct"] < float(w_floor):
            warnings.append(f"화면 가로 노출 {metrics['min_visible_width_pct']}% < 하한 {w_floor}% (옆이 잘려 글자가 잘림)")
        # 보이는 부분의 내용 밀도 (맨 앞/주 화면 기준, 크롭 원본에서 실제로 보이는 위쪽 비율만큼)
        names = screen_names(slide)
        entry = (preset.get("screens") or {})[names[-1]]
        x0, y0, x1, y1 = resolve_boxes(size, layer, slide, preset.get("screens") or {}, layout,
                                       [Image.open(p).size for p in shots], bottoms, trims, focus)[-1]
        p = main[-1]
        frac = min(1.0, p.visible.h / max(1, p.size[1]))
        top = y0 if layout.get("caption_position", "top") == "top" else y1 - int((y1 - y0) * frac)
        metrics["visible_content_pct"], metrics["empty_band_pct"] = crop_metrics(
            str(shots[entry["shot"]]), (x0, top, x1, top + int((y1 - y0) * frac)))
        metrics["repeat"] = int(slide.get("repeat") or 0)
        if metrics["repeat"] and not load_focus(str(shots[entry["shot"]])):
            warnings.append(f"같은 화면 반복 {metrics['repeat'] + 1}번째 ({names[-1]}), 초점 정보가 없어 확대 불가")
        f = load_focus(str(shots[entry["shot"]]))
        if f:
            region = (x0, top, x1, top + int((y1 - y0) * frac))
            # 초점이 보이는 높이보다 크면 '보일 수 있는 최대'(보이는 높이만큼) 대비로 잰다
            full = (f[2] - f[0]) * min(f[3] - f[1], region[3] - region[1])
            metrics["focus_visible_pct"] = round(focus_visible_pct(f, region) * (f[2] - f[0]) * (f[3] - f[1]) / max(1, full), 1)
            if metrics["focus_visible_pct"] < FOCUS_MIN_PCT:
                warnings.append(f"초점 노출 {metrics['focus_visible_pct']}% < 하한 {FOCUS_MIN_PCT}% (핵심 위젯이 잘림)")
        metrics["side_margin_pct"] = side_margin_pct(str(shots[entry["shot"]]), (x0, top, x1, top + int((y1 - y0) * frac)), card_bg)
        if metrics["side_margin_pct"] > SIDE_MARGIN_MAX_PCT:
            warnings.append(f"화면 좌우 여백 {metrics['side_margin_pct']}% > 상한 {SIDE_MARGIN_MAX_PCT}% (이중 테두리)")
        band_cap = float(layout.get("max_empty_band_pct", EMPTY_BAND_MAX_PCT))
        if metrics["empty_band_pct"] > band_cap:
            warnings.append(f"보이는 화면의 빈 구간 {metrics['empty_band_pct']}% > 상한 {band_cap}% (suggest-crop 으로 크롭 위치 재계산)")
        scale_floor = layout.get("min_screen_scale")
        if scale_floor is not None and metrics["min_screen_scale"] < float(scale_floor):
            warnings.append(f"화면 배율 {metrics['min_screen_scale']} < 하한 {scale_floor} (앱 글자가 작아 읽기 어려움)")
    caption = next((l for l in preset["layers"] if l["type"] == "caption"), None)
    if caption and "caption_area_pct" in layout and (slide.get("headline") or slide.get("body")):
        mx = int(size[0] * float(caption.get("margin_x_pct", 8)) / 100)
        used = int(size[1] * float(caption.get("margin_top_pct", 8)) / 100) + estimate_height(
            slide.get("headline", ""), slide.get("body", ""), size[0] - 2 * mx, preset["typography"], float(caption.get("gap_px", 24)))
        metrics["caption_used_pct"] = round(used / size[1] * 100, 1)
        if used > size[1] * float(layout["caption_area_pct"]) / 100:
            warnings.append(f"캡션 {metrics['caption_used_pct']}% > 캡션 영역 {layout['caption_area_pct']}%")
    c_metrics, c_warns = check_contrast(preset, index)
    metrics.update(c_metrics)
    warnings.extend(c_warns)
    return {"metrics": metrics, "warnings": warnings}
