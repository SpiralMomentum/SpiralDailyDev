"""눈 판단을 대신하는 결정적 검사와 결정적 보정 규칙.

같은 입력이면 어떤 사람·모델이 돌려도 같은 경고, 같은 보정값이 나와야 한다.
근거
  - 대비: WCAG 2.2 SC 1.4.3 (AA). 큰 글자(24 CSS px 이상, 또는 굵기 700 이상이면서 18.66 CSS px 이상)는 3:1, 그 외 4.5:1.
    캔버스 px 를 density 로 나눠 CSS px 로 본다.
  - 빈 영역: 우리 설정값 (CONTENT_*, EMPTY_BAND_MAX_PCT). 근거 관측 없음. 보정 기록은 tools/marketing/docs/템플릿_운영_규칙.md 7절.
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Any, Mapping, Sequence

from PIL import Image, ImageStat

DARK_BG = "#161616"          # variations.py dark 팔레트 배경
CONTENT_TILE_PX = 32         # 내용 판정 타일 크기 (스크린샷 원본 px)
CONTENT_TILE_STDDEV = 8.0    # 타일 밝기 표준편차가 이보다 크면 '내용 있음' (우리 설정)
EMPTY_BAND_MAX_PCT = 45.0    # 보이는 화면에서 연속으로 빈 줄(내용 타일 1개 이하)이 차지하는 최대 비율 (우리 설정, 운영 규칙 7절 보정표)
EMPHASIS_MIN_DIFF = 40     # 강조색과 제목색의 RGB 채널 최대 차 하한 (우리 설정)
MIX_STEP = 0.1               # 대비 보정 시 흰색/검정 섞는 단계


def hex_rgb(h: str) -> tuple[int, int, int]:
    v = h.lstrip("#")
    return int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)


def rgb_hex(c: Sequence[float]) -> str:
    return "#" + "".join(f"{round(x):02X}" for x in c)


def luminance(h: str) -> float:
    def ch(v: int) -> float:
        s = v / 255
        return s / 12.92 if s <= 0.04045 else ((s + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(v) for v in hex_rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return round((la + 0.05) / (lb + 0.05), 2)


def required_contrast(size_px: float, weight: int, density: float) -> float:
    css = size_px / density
    return 3.0 if css >= 24 or (weight >= 700 and css >= 18.66) else 4.5


def mix(color: str, toward: str, t: float) -> str:
    a, b = hex_rgb(color), hex_rgb(toward)
    return rgb_hex([x + (y - x) * t for x, y in zip(a, b)])


def ensure_contrast(color: str, backgrounds: Sequence[str], target: float) -> str:
    """color 가 모든 배경에서 target 이상이 되도록 흰색(어두운 배경) 또는 검정(밝은 배경) 쪽으로 MIX_STEP 씩 섞는다.
    이미 충분하면 그대로 돌려준다. 결정적이다."""
    dark = sum(luminance(b) for b in backgrounds) / len(backgrounds) < 0.18
    toward = "#FFFFFF" if dark else "#000000"
    for i in range(0, 11):
        cand = mix(color, toward, round(i * MIX_STEP, 2))
        if min(contrast(cand, b) for b in backgrounds) >= target:
            return cand
    return toward


def normalize_profile(profile: Mapping[str, Any]) -> dict[str, Any]:
    """brand.on_dark 가 없으면 규칙으로 만든다: primary 를 DARK_BG 위 4.5:1 이 될 때까지 흰색 쪽으로 섞은 값."""
    brand = dict(profile.get("brand") or {})
    if "on_dark" not in brand and "primary" in brand:
        brand["on_dark"] = ensure_contrast(brand["primary"], [DARK_BG], 4.5)
    return {**profile, "brand": brand}


def slide_background(preset: Mapping[str, Any], index: int) -> str | None:
    bg = next((l for l in preset["layers"] if l["type"] == "background"), None)
    if not bg:
        return None
    pal = bg.get("palette_per_slide") or []
    if bg.get("per_slide_color") and pal:
        return pal[index % len(pal)]
    return bg.get("color") or (pal[0] if pal else None)


def check_contrast(preset: Mapping[str, Any], index: int) -> tuple[dict[str, float], list[str]]:
    bg = slide_background(preset, index)
    cap = next((l for l in preset["layers"] if l["type"] == "caption"), None)
    slide = (preset.get("slides") or [{}])[index]
    if not bg or not cap or not str(bg).startswith("#"):
        return {}, []
    typo, density = preset["typography"], float(preset["canvas"].get("density", 2.0))
    hl, bd = typo["headline"], typo.get("body", typo["headline"])
    eff = {**cap, **((slide.get("layers") or {}).get("caption") or {})}
    roles = [("headline", eff.get("text_color", "#111111"), hl, bool(slide.get("headline"))),
             ("emphasis", eff.get("emphasis_color"), hl, "[[" in str(slide.get("headline", "")) + str(slide.get("body", ""))),
             ("body", eff.get("body_color", "#6B6B6B"), bd, bool(slide.get("body")))]
    metrics, warns = {}, []
    # 11회차: 강조색이 제목색과 구분되지 않으면 강조가 사라진다 (채널 최대 차 EMPHASIS_MIN_DIFF 미만)
    emph, head = eff.get("emphasis_color"), eff.get("text_color", "#111111")
    if roles[1][3] and emph and head and str(emph).startswith("#") and str(head).startswith("#"):
        diff = max(abs(a - b) for a, b in zip(hex_rgb(emph), hex_rgb(head)))
        metrics["emphasis_diff"] = diff
        if diff < EMPHASIS_MIN_DIFF:
            warns.append(f"강조 구분 {emph} vs 제목 {head} 차 {diff} < {EMPHASIS_MIN_DIFF} (강조가 안 보임)")
    for name, color, spec, used in roles:
        if not used or not color or not str(color).startswith("#"):
            continue
        need = required_contrast(float(spec["size_px"]), int(spec.get("weight", 400)), density)
        got = contrast(color, bg)
        metrics[f"contrast_{name}"] = got
        if got < need:
            warns.append(f"대비 {name} {color} / 배경 {bg} = {got}:1 < {need}:1 (WCAG 1.4.3)")
    return metrics, warns


def content_pct(img: Image.Image, tile: int = CONTENT_TILE_PX, threshold: float = CONTENT_TILE_STDDEV) -> float:
    g = img.convert("L")
    tiles = [g.crop((x, y, min(x + tile, g.width), min(y + tile, g.height)))
             for y in range(0, g.height, tile) for x in range(0, g.width, tile)]
    if not tiles:
        return 0.0
    return round(sum(ImageStat.Stat(t).stddev[0] > threshold for t in tiles) / len(tiles) * 100, 1)


def row_content(img: Image.Image, tile: int = CONTENT_TILE_PX, threshold: float = CONTENT_TILE_STDDEV) -> list[int]:
    """타일 행마다 내용 타일 개수."""
    g = img.convert("L")
    return [sum(ImageStat.Stat(g.crop((x, y, min(x + tile, g.width), min(y + tile, g.height)))).stddev[0] > threshold
                for x in range(0, g.width, tile)) for y in range(0, g.height, tile)]


def empty_band_pct(img: Image.Image, tile: int = CONTENT_TILE_PX) -> float:
    """가장 긴 '빈 줄' 연속 구간이 전체 높이에서 차지하는 비율(%). 빈 줄 = 내용 타일이 1개 이하인 타일 행."""
    rows = row_content(img, tile)
    best = cur = 0
    for n in rows:
        cur = cur + 1 if n <= 1 else 0
        best = max(best, cur)
    return round(best / len(rows) * 100, 1) if rows else 100.0


def content_bbox_crop(img: Image.Image, min_tiles: int = 2, pad_tiles: int = 1, tile: int = CONTENT_TILE_PX) -> list[float]:
    """내용 타일이 min_tiles 개 이상인 첫 행부터 마지막 행까지 (위아래로 pad_tiles 행 여유). [0, y0, 1, y1], 0.01 단위.
    화면 전체가 크롭일 때 R2 의 첫 단계로 쓴다."""
    rows = row_content(img, tile)
    hits = [i for i, n in enumerate(rows) if n >= min_tiles]
    if not hits:
        return [0, 0, 1, 1]
    y0 = max(0, hits[0] - pad_tiles) * tile / img.height
    y1 = min(len(rows), hits[-1] + 1 + pad_tiles) * tile / img.height
    return [0, round(y0, 2), 1, round(min(1.0, y1), 2)]


def suggest_crop(img: Image.Image, height_frac: float, current_y0: float = 0.0, tile: int = CONTENT_TILE_PX) -> list[float]:
    """높이 height_frac 창을 위에서 아래로 밀며 내용 타일이 가장 많은 위치를 고른다. [0, y0, 1, y1].
    동점이면 현재 위치(current_y0)에 가장 가까운 창, 그래도 같으면 위쪽 (다시 돌려도 같은 값이 나오게).
    0.01 단위로 반올림한다."""
    rows = row_content(img, tile)
    win = max(1, round(len(rows) * height_frac))
    best = max(range(0, len(rows) - win + 1),
               key=lambda i: (sum(rows[i:i + win]), -abs(i * tile / img.height - current_y0), -i))
    y0 = round(best * tile / img.height, 2)
    return [0, y0, 1, round(min(1.0, y0 + height_frac), 2)]


NEUTRAL_DARK, NEUTRAL_LIGHT = "#111111", "#FFFFFF"


def flip_neutral(color: str, bg: str, need: float) -> str:
    if contrast(color, bg) >= need:
        return color
    return max((NEUTRAL_DARK, NEUTRAL_LIGHT), key=lambda c: contrast(c, bg))


CAPTION_ROLES = (("headline", "text_color", "#111111", "headline"),
                 ("emphasis", "emphasis_color", None, "headline"),
                 ("body", "body_color", "#6B6B6B", "body"))


def auto_contrast(preset: Mapping[str, Any]) -> dict[str, Any]:
    """캡션 글자색을 장별 배경에 맞춰 WCAG 기준까지 보정한다 (R1 템플릿 규칙).
    caption.auto_contrast 가 false 면 그대로 둔다. 결과는 slides[i].layers.caption 덮어쓰기로 들어간다.
    보정 방향: 강조색은 배경이 어두우면 흰색, 밝으면 검정 쪽으로 MIX_STEP 씩 (ensure_contrast, 브랜드 색 유지 목적).
    제목·본문(중립색)은 미달이면 NEUTRAL_DARK / NEUTRAL_LIGHT 중 대비가 큰 쪽으로 바꾼다 (flip_neutral, 탁한 회색 방지)."""
    cap = next((l for l in preset["layers"] if l["type"] == "caption"), None)
    if not cap or cap.get("auto_contrast", True) is False:
        return dict(preset)
    typo, density = preset["typography"], float(preset["canvas"].get("density", 2.0))
    slides = []
    for i, slide in enumerate(preset.get("slides") or [{}]):
        bg = slide_background(preset, i)
        over = dict((slide.get("layers") or {}).get("caption") or {})
        if bg and str(bg).startswith("#"):
            for _, key, default, spec_name in CAPTION_ROLES:
                color = over.get(key, cap.get(key, default))
                if not color or not str(color).startswith("#"):
                    continue
                spec = typo.get(spec_name, typo["headline"])
                need = required_contrast(float(spec["size_px"]), int(spec.get("weight", 400)), density)
                fixed = (ensure_contrast(color, [bg], need) if key == "emphasis_color"
                         else flip_neutral(color, bg, need))
                if fixed != color:
                    over[key] = fixed
        layers = {**(slide.get("layers") or {}), **({"caption": over} if over else {})}
        slides.append({**slide, **({"layers": layers} if layers else {})})
    return {**preset, "slides": slides}


@lru_cache(maxsize=512)
def crop_metrics(path: str, box: tuple[int, int, int, int]) -> tuple[float, float]:
    """(content_pct, empty_band_pct) 캐시. 감사(audit)에서 같은 크롭을 수백 번 재는 것을 줄인다."""
    region = Image.open(path).crop(box)
    return content_pct(region), empty_band_pct(region)


GAP_STOP_FRAC = 0.10   # 크롭 연장 중 이만큼(스크린샷 높이 대비) 연속 빈 줄을 만나면 멈춘다 (우리 설정)


@lru_cache(maxsize=512)
def extend_limit_px(path: str, start_px: int, gap_frac: float = GAP_STOP_FRAC, tile: int = CONTENT_TILE_PX) -> int:
    """start_px 아래로 내려가며, 연속 빈 줄(내용 타일 1개 이하)이 gap_frac 이상 이어지는 첫 지점의 위 끝을 돌려준다.
    없으면 스크린샷 끝. 하단 탭 바·구분선을 넘어 빈 영역을 연장하지 않기 위한 한계 (5회차)."""
    img = Image.open(path)
    rows = row_content(img, tile)
    need = max(1, round(img.height * gap_frac / tile))
    run_start, run = None, 0
    for i in range(start_px // tile, len(rows)):
        if rows[i] <= 1:
            run_start = i if run == 0 else run_start
            run += 1
            if run >= need:
                return max(start_px, run_start * tile)
        else:
            run = 0
    return img.height


SIDE_MARGIN_MAX_PCT = 20.0   # 보이는 화면 좌우 단색 여백 합의 상한. 넘으면 앱 화면 자체가 카드(이중 테두리)로 본다 (우리 설정, 7회차)


FOREIGN_RGB_DIFF = 6   # 카드 배경과 이만큼(채널 최대 차) 다르면 '앱 배경색 띠'로 본다 (우리 설정)


@lru_cache(maxsize=1024)
def side_bounds(path: str, box: tuple[int, int, int, int], card_bg: str = "#FFFFFF", pad: bool = True,
                tile: int = CONTENT_TILE_PX, threshold: float = CONTENT_TILE_STDDEV) -> tuple[int, int]:
    """box 의 좌우 끝에서 안쪽으로, '내용 없고 카드 배경과 다른 색'인 열(앱 배경색 띠)을 걷어낸 x 범위 (원본 px).
    가운데 정렬 글자 옆의 흰 여백(카드 배경과 같은 색)은 걷어내지 않는다."""
    img = Image.open(path).convert("RGB").crop(box)
    g = img.convert("L")
    bg = hex_rgb(card_bg)

    def foreign(x: int) -> bool:
        col = (x, 0, min(x + tile, img.width), img.height)
        if any(ImageStat.Stat(g.crop((x, y, col[2], min(y + tile, g.height)))).stddev[0] > threshold
               for y in range(0, g.height, tile)):
            return False
        mean = ImageStat.Stat(img.crop(col)).mean
        return max(abs(m - b) for m, b in zip(mean, bg)) > FOREIGN_RGB_DIFF

    xs = list(range(0, img.width, tile))
    left = next((i for i, x in enumerate(xs) if not foreign(x)), len(xs))
    right = next((i for i, x in enumerate(reversed(xs)) if not foreign(x)), len(xs))
    # 1타일 여유: 타일 경계 때문에 카드 가장자리를 파먹지 않게 (경계 타일은 띠로 남을 수 있다, 최대 tile px)
    k = 1 if pad else 0
    x0 = box[0] + max(0, left - k) * tile
    x1 = box[2] - max(0, right - k) * tile
    return (x0, x1) if x1 > x0 else (box[0], box[2])


def side_margin_pct(path: str, box: tuple[int, int, int, int], card_bg: str = "#FFFFFF") -> float:
    """보이는 화면 좌우의 앱 배경색 띠 합 비율 (%). 측정이므로 여유 없이 잰다."""
    x0, x1 = side_bounds(path, box, card_bg, False)
    w = box[2] - box[0]
    return round((w - (x1 - x0)) / w * 100, 1) if w else 0.0


FOCUS_PAD_FRAC = 0.02   # 초점 위아래 여유 (스크린샷 높이 대비, 우리 설정)
FOCUS_MIN_PCT = 95.0    # 초점 사각형이 보여야 하는 최소 비율 (우리 설정)


@lru_cache(maxsize=256)
def load_focus(path: str) -> tuple[int, int, int, int] | None:
    """스크린샷 옆 사이드카 <name>.json 의 초점 사각형을 원본 px 로 (통합 테스트가 남긴다). 없으면 None."""
    import json
    side = Path(path).with_suffix(".json")
    if not side.exists():
        return None
    data = json.loads(side.read_text(encoding="utf-8"))
    dpr = float(data.get("dpr", 1))
    l, t, r, b = (float(v) * dpr for v in data["rect"])
    w, h = Image.open(path).size
    return max(0, round(l)), max(0, round(t)), min(w, round(r)), min(h, round(b))


def focus_visible_pct(focus: tuple[int, int, int, int], region: tuple[int, int, int, int]) -> float:
    """초점 사각형 중 보이는 원본 영역 안에 들어온 면적 비율 (%)."""
    ix0, iy0 = max(focus[0], region[0]), max(focus[1], region[1])
    ix1, iy1 = min(focus[2], region[2]), min(focus[3], region[3])
    area = max(1, (focus[2] - focus[0]) * (focus[3] - focus[1]))
    return round(max(0, ix1 - ix0) * max(0, iy1 - iy0) / area * 100, 1)


@lru_cache(maxsize=512)
def best_window_px(path: str, y_lo: int, y_hi: int, win_h: int, tile: int = CONTENT_TILE_PX) -> int:
    """[y_lo, y_hi] 안에서 높이 win_h 창 중 내용 타일이 가장 많은 창의 위 끝 (동점이면 위쪽). 큰 초점 안에서 쓴다 (10회차)."""
    rows = row_content(Image.open(path), tile)
    lo, hi, win = y_lo // tile, max(y_lo // tile, (y_hi - win_h) // tile), max(1, win_h // tile)
    best = max(range(lo, hi + 1), key=lambda i: (sum(rows[i:i + win]), -i))
    return best * tile
