"""레이어 렌더러. 07_템플릿_스펙.md 4장의 레이어 유형을 디스패치 테이블로 구현한다.

각 렌더러는 (canvas, layer, ctx) -> 새 canvas 를 돌려주며 입력 이미지는 수정하지 않는다.
구현 범위: background, caption, device_frame(generic bezel), ui_popout, brand.
decoration(일러스트·스티커)은 라이선스 확인된 에셋 파일이 없어 `kind: none`만 허용한다.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from PIL import Image, ImageDraw, ImageFilter

from template.fonts import line_width, load_font, tokenize, wrap_tokens
from template.checks import FOCUS_PAD_FRAC, best_window_px, SIDE_MARGIN_MAX_PCT, extend_limit_px, load_focus, side_bounds, side_margin_pct
from template.layout import Placement, plan_screens
from template.perspective import warp_card

Color = tuple[int, int, int]

# Tailwind box-shadow (raw/06 #29): (x, y, blur, opacity) CSS px 기준. density 배율로 캔버스 px 환산.
SHADOWS: dict[str, list[tuple[int, int, int, float]]] = {
    "none": [],
    "tailwind_sm": [(0, 1, 2, 0.05)],
    "tailwind_md": [(0, 4, 6, 0.10), (0, 2, 4, 0.10)],
    "tailwind_lg": [(0, 10, 15, 0.10), (0, 4, 6, 0.10)],
    "tailwind_xl": [(0, 20, 25, 0.10), (0, 8, 10, 0.10)],
    "tailwind_2xl": [(0, 25, 50, 0.25)],
}


@dataclass(frozen=True)
class Ctx:
    index: int                    # 0-based slide index
    count: int
    slide: Mapping[str, Any]      # 장별 콘텐츠 (headline, body, screenshot, ...)
    shots: Sequence[Path]
    typography: Mapping[str, Any]
    color: Mapping[str, Any]
    density: float = 2.0          # CSS px -> 캔버스 px 배율
    screens: Mapping[str, Any] = field(default_factory=dict)   # 앱 화면 레지스트리: 이름 -> {shot, crop}
    layout: Mapping[str, Any] = field(default_factory=dict)    # 캡션/화면 영역 분할 (layout.py)
    assets_dir: Path = field(default_factory=Path)


def hex_to_rgb(value: str) -> Color:
    v = value.lstrip("#")
    return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def pick_per_slide(values: Sequence[Any], index: int) -> Any:
    return values[index % len(values)]


def slide_override(layer: Mapping[str, Any], ctx: Ctx) -> dict[str, Any]:
    """slide.layers.<type> 에 적힌 값이 템플릿 레이어 값을 덮는다 (새 dict 반환)."""
    override = (ctx.slide.get("layers") or {}).get(layer["type"], {})
    return {**layer, **override}


# ---------- 공통 도형 ----------

def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def with_shadow(card: Image.Image, shadow: str, density: float) -> tuple[Image.Image, tuple[int, int]]:
    """카드(RGBA) 뒤에 그림자를 깔아 더 큰 RGBA와 카드의 오프셋을 돌려준다."""
    specs = SHADOWS[shadow]
    if not specs:
        return card, (0, 0)
    pad = int(max(abs(y) + blur * 2 for _, y, blur, _ in specs) * density) + 4
    out = Image.new("RGBA", (card.width + pad * 2, card.height + pad * 2), (0, 0, 0, 0))
    for dx, dy, blur, opacity in specs:
        layer = Image.new("RGBA", out.size, (0, 0, 0, 0))
        box = (pad + int(dx * density), pad + int(dy * density),
               pad + int(dx * density) + card.width, pad + int(dy * density) + card.height)
        ImageDraw.Draw(layer).rectangle(box, fill=(0, 0, 0, int(255 * opacity)))
        layer = layer.filter(ImageFilter.GaussianBlur(blur * density / 2))
        out = Image.alpha_composite(out, layer)
    out.alpha_composite(card, (pad, pad))
    return out, (pad, pad)


def shadow_behind(img: Image.Image, shadow: str, density: float) -> tuple[Image.Image, tuple[int, int]]:
    """이미 변환된 RGBA 의 알파 모양대로 그림자를 깐다 (원근 변환 뒤에는 사각형 그림자를 쓸 수 없다)."""
    specs = SHADOWS[shadow]
    if not specs:
        return img, (0, 0)
    pad = int(max(abs(y) + blur * 2 for _, y, blur, _ in specs) * density) + 4
    out = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    alpha = img.getchannel("A")
    for dx, dy, blur, opacity in specs:
        mask = Image.new("L", out.size, 0)
        mask.paste(alpha.point(lambda a, o=opacity: int(a * o)), (pad + int(dx * density), pad + int(dy * density)))
        mask = mask.filter(ImageFilter.GaussianBlur(blur * density / 2))
        layer = Image.new("RGBA", out.size, (0, 0, 0, 0))
        layer.putalpha(mask)
        out = Image.alpha_composite(out, layer)
    out.alpha_composite(img, (pad, pad))
    return out, (pad, pad)


def rotate(img: Image.Image, deg: float) -> Image.Image:
    return img if not deg else img.rotate(deg, resample=Image.BICUBIC, expand=True)


def paste_anchored(canvas: Image.Image, item: Image.Image, anchor: str, x_pct: float, y_pct: float) -> Image.Image:
    """anchor: center | top_left | top_center | bottom_center | top_right 기준으로 item(RGBA)을 합성."""
    w, h = canvas.size
    ax, ay = {"center": (0.5, 0.5), "top_left": (0, 0), "top_center": (0.5, 0), "top_right": (1, 0),
              "bottom_center": (0.5, 1), "bottom_left": (0, 1), "bottom_right": (1, 1), "center_left": (0, 0.5)}[anchor]
    x = int(w * x_pct / 100 - item.width * ax)
    y = int(h * y_pct / 100 - item.height * ay)
    out = canvas.convert("RGBA")
    out.alpha_composite(item, (x, y))
    return out.convert("RGB")


def screenshot_for(ctx: Ctx, layer: Mapping[str, Any]) -> Image.Image:
    ref = layer.get("screenshot", ctx.slide.get("screenshot", ctx.index))
    path = ctx.shots[ref] if isinstance(ref, int) else Path(ref)
    return Image.open(path).convert("RGB")


# ---------- background ----------

def gradient_image(size: tuple[int, int], start: Color, end: Color, angle_deg: int) -> Image.Image:
    w, h = size
    diag = int(math.hypot(w, h)) + 2
    strip = Image.new("RGB", (1, diag))
    px = strip.load()
    for y in range(diag):
        t = y / (diag - 1)
        px[0, y] = tuple(int(s + (e - s) * t) for s, e in zip(start, end))
    big = strip.resize((diag, diag)).rotate(-angle_deg, resample=Image.BICUBIC)
    left, top = (diag - w) // 2, (diag - h) // 2
    return big.crop((left, top, left + w, top + h))


def draw_grid(canvas: Image.Image, spacing_px: int, color: Color, opacity: float) -> Image.Image:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rgba = (*color, int(255 * opacity))
    for x in range(0, canvas.width, spacing_px):
        d.line((x, 0, x, canvas.height), fill=rgba, width=2)
    for y in range(0, canvas.height, spacing_px):
        d.line((0, y, canvas.width, y), fill=rgba, width=2)
    return Image.alpha_composite(canvas.convert("RGBA"), layer).convert("RGB")


def render_background(canvas: Image.Image, layer: Mapping[str, Any], ctx: Ctx) -> Image.Image:
    layer = slide_override(layer, ctx)
    kind = layer.get("kind", "solid")
    color = hex_to_rgb(pick_per_slide(layer["palette_per_slide"], ctx.index) if layer.get("per_slide_color") else layer.get("color", "#FFFFFF"))
    if kind == "none_full_bleed":
        shot = screenshot_for(ctx, layer)
        return shot.resize(canvas.size, Image.LANCZOS)
    if kind == "gradient_two_tone":
        g = layer["gradient"]
        out = gradient_image(canvas.size, hex_to_rgb(g["from"]), hex_to_rgb(g["to"]), int(g.get("angle_deg", 180)))
    else:
        out = Image.new("RGB", canvas.size, color)
    pattern = layer.get("pattern")
    if pattern and pattern.get("kind") == "grid":
        out = draw_grid(out, int(pattern.get("spacing_px", 60)), hex_to_rgb(pattern.get("color", "#000000")), float(pattern.get("opacity", 0.06)))
    return out


# ---------- caption ----------

def draw_text_block(canvas: Image.Image, text: str, *, font, color: Color, emphasis_color: Color, align: str,
                    x_left: int, x_right: int, y_top: int, line_height: float) -> tuple[Image.Image, int]:
    """텍스트 블록을 그리고 (새 캔버스, 블록 바닥 y)를 돌려준다."""
    out = canvas.copy()
    d = ImageDraw.Draw(out)
    lines = wrap_tokens(tokenize(text), font, x_right - x_left)
    step = int(font.size * line_height)
    space = font.getlength(" ")
    y = y_top
    for line in lines:
        lw = line_width(line, font)
        x = x_left if align == "left" else (x_left + x_right) / 2 - lw / 2 if align == "center" else x_right - lw
        for word in line:
            for segment, emph in word:
                d.text((x, y), segment, font=font, fill=emphasis_color if emph else color)
                x += font.getlength(segment)
            x += space
        y += step
    return out, y


def render_caption(canvas: Image.Image, layer: Mapping[str, Any], ctx: Ctx) -> Image.Image:
    layer = slide_override(layer, ctx)
    if not layer.get("present", True):
        return canvas
    headline = ctx.slide.get("headline", "")
    body = ctx.slide.get("body", "")
    if not headline and not body:
        return canvas
    w, h = canvas.size
    mx = int(w * float(layer.get("margin_x_pct", 8)) / 100)
    y = int(h * float(layer.get("margin_top_pct", 8)) / 100)
    color = hex_to_rgb(pick_per_slide(layer["text_color_per_slide"], ctx.index) if layer.get("text_color_per_slide") else layer.get("text_color", "#111111"))
    emph = hex_to_rgb(layer.get("emphasis_color", ctx.color.get("palette", {}).get("accent", "#111111")))
    align = layer.get("align", "center")
    hl = ctx.typography["headline"]
    bd = ctx.typography.get("body", hl)
    out = canvas
    if layer.get("position") == "bottom":
        # 아래에서 위로 쌓기 위해 높이를 먼저 측정
        y = h - int(h * float(layer.get("margin_bottom_pct", 8)) / 100) - estimate_height(headline, body, w - 2 * mx, ctx.typography, float(layer.get("gap_px", 24)))
    if headline:
        out, y = draw_text_block(out, headline, font=load_font(ctx.typography["families"]["headline"], int(hl["weight"]), int(hl["size_px"])),
                                 color=color, emphasis_color=emph, align=align, x_left=mx, x_right=w - mx, y_top=y, line_height=float(hl.get("line_height", 1.2)))
        y += int(layer.get("gap_px", 24))
    if body:
        body_color = hex_to_rgb(layer.get("body_color", "#6B6B6B"))
        out, y = draw_text_block(out, body, font=load_font(ctx.typography["families"]["body"], int(bd["weight"]), int(bd["size_px"])),
                                 color=body_color, emphasis_color=emph, align=align, x_left=mx, x_right=w - mx, y_top=y, line_height=float(bd.get("line_height", 1.4)))
    return out


def estimate_height(headline: str, body: str, width: int, typography: Mapping[str, Any], gap: float) -> int:
    def block(text: str, role: str) -> int:
        if not text:
            return 0
        spec = typography.get(role, typography["headline"])
        font = load_font(typography["families"][role], int(spec["weight"]), int(spec["size_px"]))
        return len(wrap_tokens(tokenize(text), font, width)) * int(font.size * float(spec.get("line_height", 1.2)))
    return block(headline, "headline") + (int(gap) if headline and body else 0) + block(body, "body")


# ---------- device_frame ----------

def build_device(shot: Image.Image, device_w: int, bezel_px: int, outer_radius: int, screen_radius: int, color: Color) -> Image.Image:
    """단색 베젤(generic) 기기 이미지(RGBA). Apple 공식 베젤 파일은 Apple 플랫폼 UI 목업 전용 라이선스(raw/05 #2)라 쓰지 않는다."""
    screen_w = device_w - bezel_px * 2
    screen_h = int(shot.height * screen_w / shot.width)
    screen = shot.resize((screen_w, screen_h), Image.LANCZOS)
    device = Image.new("RGBA", (device_w, screen_h + bezel_px * 2), (0, 0, 0, 0))
    ImageDraw.Draw(device).rounded_rectangle((0, 0, device_w - 1, device.height - 1), radius=outer_radius, fill=(*color, 255))
    device.paste(screen, (bezel_px, bezel_px), rounded_mask(screen.size, screen_radius))
    return device


def render_device_frame(canvas: Image.Image, layer: Mapping[str, Any], ctx: Ctx) -> Image.Image:
    layer = slide_override(layer, ctx)
    if not layer.get("present", True):
        return canvas
    w, h = canvas.size
    device_w = int(w * float(layer.get("width_fraction", 0.8)))
    bezel = int(device_w * float(layer.get("bezel_fraction", 0.035)))
    device = build_device(screenshot_for(ctx, layer), device_w, bezel,
                          int(device_w * float(layer.get("outer_radius_fraction", 0.14))),
                          int(device_w * float(layer.get("screen_radius_fraction", 0.11))),
                          hex_to_rgb(layer.get("color_hex", "#111111")))
    device = rotate(device, float(layer.get("tilt_deg", 0)))
    x_pct = float(layer.get("x_pct", 50))
    if layer.get("bottom_cropped"):
        # 기기 하단이 캔버스 밖: visible_fraction 만큼만 보이도록 top 좌표로 배치 (y_pct가 있으면 그 위치를 top으로)
        top = int(h * float(layer["y_pct"]) / 100) if "y_pct" in layer else h - int(device.height * float(layer.get("visible_fraction", 0.85)))
        out = canvas.convert("RGBA")
        out.alpha_composite(device, (int(w * x_pct / 100 - device.width / 2), top))
        return out.convert("RGB")
    return paste_anchored(canvas, device, layer.get("anchor", "center"), x_pct, float(layer.get("y_pct", 50)))


# ---------- ui_popout ----------

def build_card(content: Image.Image, padding_px: int, radius_px: int, bg: Color) -> Image.Image:
    card = Image.new("RGBA", (content.width + padding_px * 2, content.height + padding_px * 2), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle((0, 0, card.width - 1, card.height - 1), radius=radius_px, fill=(*bg, 255))
    inner_radius = max(0, radius_px - padding_px)
    card.paste(content, (padding_px, padding_px), rounded_mask(content.size, inner_radius))
    return card


def render_ui_popout(canvas: Image.Image, layer: Mapping[str, Any], ctx: Ctx) -> Image.Image:
    layer = slide_override(layer, ctx)
    if not layer.get("present", True):
        return canvas
    shot = screenshot_for(ctx, layer)
    x0, y0, x1, y1 = layer.get("crop", [0, 0, 1, 1])
    crop = shot.crop((int(shot.width * x0), int(shot.height * y0), int(shot.width * x1), int(shot.height * y1)))
    target_w = int(canvas.width * float(layer.get("width_fraction", 0.9)))
    crop = crop.resize((target_w, int(crop.height * target_w / crop.width)), Image.LANCZOS)
    style = layer.get("card_style", {})
    card = build_card(crop, int(style.get("padding_px", 0)), int(style.get("radius_px", 32)), hex_to_rgb(style.get("bg", "#FFFFFF")))
    card, _ = with_shadow(card, style.get("shadow", "tailwind_lg"), ctx.density)
    card = rotate(card, float(layer.get("tilt_deg", 0)))
    return paste_anchored(canvas, card, layer.get("anchor", "top_center"), float(layer.get("x_pct", 50)), float(layer.get("y_pct", 50)))


# ---------- screen (레이아웃 모델 기반 앱 화면 배치) ----------

def screen_names(slide: Mapping[str, Any]) -> list[str]:
    """slide.screen: 이름 하나 또는 이름 목록(최대 2개, 나란히 배치)."""
    ref = slide.get("screen")
    return [] if ref is None else ([ref] if isinstance(ref, str) else list(ref))


def screen_entry(screens: Mapping[str, Any], name: str) -> Mapping[str, Any]:
    if name not in screens:
        raise KeyError(f"screens 에 {name!r} 없음. 등록된 이름: {sorted(screens)}")
    return screens[name]


def crop_px(entry: Mapping[str, Any], shot_size: tuple[int, int]) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = entry.get("crop", [0, 0, 1, 1])
    w, h = shot_size
    return int(w * x0), int(h * y0), int(w * x1), int(h * y1)


def plan_for_slide(canvas_size: tuple[int, int], layer: Mapping[str, Any], slide: Mapping[str, Any],
                   screens: Mapping[str, Any], layout: Mapping[str, Any],
                   shot_sizes: Sequence[tuple[int, int]], limit_fn: Any = None, trim_fn: Any = None,
                   focus_fn: Any = None) -> list[Placement]:
    """순수 함수: 렌더와 검증(render.measure_slide)이 공유한다."""
    boxes = resolve_boxes(canvas_size, layer, slide, screens, layout, shot_sizes, limit_fn, trim_fn, focus_fn)
    return _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1]) for b in boxes])


def shot_trim_fn(shots: Sequence[Path], card_bg: str = "#FFFFFF"):
    """resolve_boxes 의 trim_fn: 앱 배경색 띠가 SIDE_MARGIN_MAX_PCT 를 넘을 때만 걷어낸다."""
    def trim(i: int, box: tuple[int, int, int, int], seen: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
        if seen[3] <= seen[1] or side_margin_pct(str(shots[i]), seen, card_bg) <= SIDE_MARGIN_MAX_PCT:
            return box
        x0, x1 = side_bounds(str(shots[i]), seen, card_bg)
        return (x0, box[1], x1, box[3])
    return trim


def shot_focus_fn(shots: Sequence[Path]):
    """resolve_boxes 의 focus_fn: shot 번호 -> 초점 사각형(원본 px) 또는 None (사이드카 JSON).
    .window(shot, y_lo, y_hi, h): 큰 초점 안에서 내용이 가장 많은 창의 위 끝."""
    def fn(i: int):
        return load_focus(str(shots[i]))
    fn.window = lambda i, lo, hi, h: best_window_px(str(shots[i]), int(lo), int(hi), int(h))
    return fn


def shot_limit_fn(shots: Sequence[Path]):
    """resolve_boxes 의 limit_fn: (shot 번호, 크롭 끝 px) -> 연장 한계 px."""
    return lambda i, start: extend_limit_px(str(shots[i]), int(start))


def resolve_boxes(canvas_size: tuple[int, int], layer: Mapping[str, Any], slide: Mapping[str, Any],
                  screens: Mapping[str, Any], layout: Mapping[str, Any],
                  shot_sizes: Sequence[tuple[int, int]],
                  limit_fn: Any = None, trim_fn: Any = None, focus_fn: Any = None) -> list[tuple[int, int, int, int]]:
    """화면별 실제 크롭 상자 (원본 px). 렌더와 검증이 공유하는 순수 단계의 합성이다.
      1. 프로필 크롭
      2. 맞춤 보정 (_fit_adjust: contain 배율 하한 6회차 / crop_top 아래 연장 4·5회차)
      3. 좌우 여백 줄이기 (7회차, trim_fn): 실제로 보이는 부분 기준. 줄였으면 폭이 바뀌므로 2를 한 번 더.
      4. 초점 맞추기 (8회차, focus_fn): 통합 테스트가 남긴 핵심 위젯이 보이는 영역 밖이면 크롭 높이를 유지한 채 세로로 옮긴다."""
    entries = [screen_entry(screens, n) for n in screen_names(slide)]
    zoom = _zoom_boxes(entries, slide, shot_sizes, focus_fn)
    if zoom:
        # 9회차: 같은 화면을 다시 쓰는 장은 초점 영역을 확대해 보여 준다. 높이는 화면 영역을 채우는 만큼,
        # 초점이 세로 가운데 오도록 잡는다 (아래 연장·좌우 줄이기 없음)
        b = zoom[0]
        p = _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1])])[0]
        need = math.ceil((canvas_size[1] - p.pos[1]) / max(p.scale, 1e-6))
        h_shot = shot_sizes[entries[0]["shot"]][1]
        cy = (b[1] + b[3]) // 2
        y0 = max(0, min(h_shot - need, cy - need // 2))
        return [(b[0], y0, b[2], min(h_shot, y0 + max(need, b[3] - b[1])))]
    boxes = _fit_adjust(canvas_size, layer, layout, entries, [crop_px(e, shot_sizes[e["shot"]]) for e in entries],
                        shot_sizes, limit_fn)
    if trim_fn and layer.get("trim_sides", True):
        boxes = _trim(canvas_size, layer, layout, entries, boxes, shot_sizes, limit_fn, trim_fn)
    if focus_fn:
        boxes = _focus(canvas_size, layer, layout, entries, boxes, shot_sizes, focus_fn)
    return boxes


def _zoom_boxes(entries, slide, shot_sizes, focus_fn):
    """반복 장(slide.repeat > 0)이고 화면이 1개이며 초점이 있으면: 초점 사각형 + 위아래 FOCUS_PAD_FRAC*3 여유, 좌우는 초점 폭."""
    if not focus_fn or int(slide.get("repeat") or 0) <= 0 or len(entries) != 1:
        return None
    f = focus_fn(entries[0]["shot"])
    if not f:
        return None
    w, h = shot_sizes[entries[0]["shot"]]
    pad = round(h * FOCUS_PAD_FRAC * 3)
    return [(max(0, f[0] - pad), max(0, f[1] - pad), min(w, f[2] + pad), min(h, f[3] + pad))]


def _focus(canvas_size, layer, layout, entries, boxes, shot_sizes, focus_fn):
    plans = _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1]) for b in boxes])
    out = []
    for e, b, p in zip(entries, boxes, plans):
        f = focus_fn(e["shot"])
        if f and (f[0] < b[0] or f[2] > b[2]):
            # 가로: 초점이 좌우 줄이기(7회차)로 잘렸으면 초점 폭까지 되돌린다 (초점 우선)
            b = (min(b[0], f[0]), b[1], max(b[2], f[2]), b[3])
            p = _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1])])[0] if len(boxes) == 1 else p
        seen = visible_region(b, p, layout)
        if not f or (f[1] >= seen[1] and f[3] <= seen[3]):
            out.append(b)
            continue
        pad = round(shot_sizes[e["shot"]][1] * FOCUS_PAD_FRAC)
        vis_h, box_h = seen[3] - seen[1], b[3] - b[1]
        if f[3] - f[1] + 2 * pad > vis_h and hasattr(focus_fn, "window"):
            # 초점이 보이는 높이보다 크면 초점 안에서 내용이 가장 많은 창을 보인다 (10회차)
            y0 = focus_fn.window(e["shot"], f[1], f[3], vis_h)
            out.append((b[0], y0, b[2], min(shot_sizes[e["shot"]][1], y0 + box_h)))
            continue
        # 보이는 높이 안에 초점을 넣는다: 위가 잘리면 초점 위로, 아래가 잘리면 초점 아래 끝이 보이는 끝에 오게
        y0 = f[1] - pad if f[1] < seen[1] or f[3] - f[1] + 2 * pad > vis_h else f[3] + pad - vis_h
        # 높이는 유지하되 스크린샷 끝에 닿으면 아래를 넘지 않게 짧아진다 (초점 우선)
        y0 = max(0, min(f[1] - pad, y0))
        out.append((b[0], y0, b[2], min(shot_sizes[e["shot"]][1], y0 + box_h)))
    return out


def _trim(canvas_size, layer, layout, entries, boxes, shot_sizes, limit_fn, trim_fn):
    plans = _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1]) for b in boxes])
    trimmed = [trim_fn(e["shot"], b, visible_region(b, p, layout)) for e, b, p in zip(entries, boxes, plans)]
    # (7회차 단계)
    if trimmed == boxes:
        return boxes
    return _fit_adjust(canvas_size, layer, layout, entries, trimmed, shot_sizes, limit_fn)


def visible_region(box: tuple[int, int, int, int], p: Placement, layout: Mapping[str, Any]) -> tuple[int, int, int, int]:
    """크롭 상자 중 캔버스에 실제로 보이는 원본 영역 (캡션 위: 위쪽부터, 아래: 아래쪽부터)."""
    h = int((box[3] - box[1]) * min(1.0, p.visible.h / max(1, p.size[1])))
    if layout.get("caption_position", "top") == "top":
        return (box[0], box[1], box[2], box[1] + h)
    return (box[0], box[3] - h, box[2], box[3])


def _fit_adjust(canvas_size, layer, layout, entries, boxes, shot_sizes, limit_fn) -> list[tuple[int, int, int, int]]:
    if layer.get("fit", "contain") == "contain" and layout.get("min_screen_scale") is not None:
        # 6회차: contain 배율이 하한 미만이면, 하한 배율로 영역 높이를 채우는 만큼만 위에서부터 남긴다.
        s_min = float(layout["min_screen_scale"])
        plans = _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1]) for b in boxes])
        cand = [(b[0], b[1], b[2], min(b[3], b[1] + max(1, math.floor(p.size[1] / s_min)))) if p.scale < s_min else b
                for b, p in zip(boxes, plans)]
        new_plans = _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1]) for b in cand])
        # 잘라서 배율이 실제로 올라간 화면만 채택 (판정식 대신 재계산으로 결정)
        return [c if np.scale > p.scale + 1e-6 else b for b, c, p, np in zip(boxes, cand, plans, new_plans)]
    if layer.get("fit", "contain") != "crop_top" or not layer.get("extend_crop", True) \
            or layout.get("caption_position", "top") != "top":
        return list(boxes)
    # 4·5회차: 짧은 크롭은 아래로 연장 (한도: 큰 빈 구간 직전)
    plans = _plan(canvas_size, layer, layout, [(b[2] - b[0], b[3] - b[1]) for b in boxes])
    out = []
    for e, b, p in zip(entries, boxes, plans):
        need_src = math.ceil((canvas_size[1] - p.pos[1]) / max(p.scale, 1e-6))
        limit = limit_fn(e["shot"], b[3]) if limit_fn else shot_sizes[e["shot"]][1]
        out.append((b[0], b[1], b[2], max(b[3], min(limit, b[1] + need_src))))
    return out


def _plan(canvas_size: tuple[int, int], layer: Mapping[str, Any], layout: Mapping[str, Any],
          sources: Sequence[tuple[int, int]]) -> list[Placement]:
    return plan_screens(canvas_size, sources,
                        caption_area_pct=float(layout.get("caption_area_pct", 30)),
                        caption_position=layout.get("caption_position", "top"),
                        margin_pct=float(layout.get("margin_pct", 4)),
                        fit=layer.get("fit", "contain"),
                        max_width_fraction=float(layer.get("max_width_fraction", 0.9)),
                        gap_px=int(layer.get("gap_px", 24)),
                        arrange=layer.get("arrange", "row"), stack=layer.get("stack"),
                        tilts=layer.get("tilts", ()), tilt_deg=float(layer.get("tilt_deg", 0)),
                        shift_x_pct=float(layer.get("shift_x_pct", 0)), poses=layer.get("poses", ()))


def render_screen(canvas: Image.Image, layer: Mapping[str, Any], ctx: Ctx) -> Image.Image:
    layer = slide_override(layer, ctx)
    names = screen_names(ctx.slide)
    if not layer.get("present", True) or not names:
        return canvas
    shot_sizes = [Image.open(p).size for p in ctx.shots]
    bottoms = shot_limit_fn(ctx.shots)
    trims = shot_trim_fn(ctx.shots, (layer.get("card_style") or {}).get("bg", "#FFFFFF"))
    focus = shot_focus_fn(ctx.shots)
    plans = plan_for_slide(canvas.size, layer, ctx.slide, ctx.screens, ctx.layout, shot_sizes, bottoms, trims, focus)
    style = layer.get("card_style", {})
    out = canvas.convert("RGBA")
    boxes = resolve_boxes(canvas.size, layer, ctx.slide, ctx.screens, ctx.layout, shot_sizes, bottoms, trims, focus)
    for name, plan, box in zip(names, plans, boxes):
        entry = screen_entry(ctx.screens, name)
        shot = Image.open(ctx.shots[entry["shot"]]).convert("RGB")
        content = shot.crop(box).resize(plan.size, Image.LANCZOS)
        card = build_card(content, int(style.get("padding_px", 0)), int(style.get("radius_px", 36)), hex_to_rgb(style.get("bg", "#FFFFFF")))
        if plan.yaw or plan.pitch:
            # 3D: 캔버스 밖으로 걸치는 긴 카드는 보이는 부분 근처만 남겨 회전 중심을 보이는 쪽으로 옮긴다
            keep = int(plan.visible.h * 1.35)
            if card.height > keep:
                card = card.crop((0, 0, card.width, keep))
            warped, (cx, cy) = warp_card(card, plan.yaw, plan.pitch, plan.tilt)
            img, (pad_x, pad_y) = shadow_behind(warped, style.get("shadow", "tailwind_lg"), ctx.density)
            center = (plan.pos[0] + card.width / 2, plan.pos[1] + card.height / 2)
            out.alpha_composite(*_clip_for_composite(img, (int(center[0] - cx - pad_x), int(center[1] - cy - pad_y)), out.size))
            continue
        card, (pad_x, pad_y) = with_shadow(card, style.get("shadow", "tailwind_lg"), ctx.density)
        tilt = plan.tilt
        if tilt:
            cx, cy = plan.pos[0] + plan.size[0] / 2, plan.pos[1] + plan.size[1] / 2
            card = rotate(card, tilt)
            dest = (int(cx - card.width / 2), int(cy - card.height / 2))
        else:
            dest = (plan.pos[0] - pad_x, plan.pos[1] - pad_y)
        out.alpha_composite(*_clip_for_composite(card, dest, out.size))
    return out.convert("RGB")


def _clip_for_composite(item: Image.Image, dest: tuple[int, int], canvas_size: tuple[int, int]) -> tuple[Image.Image, tuple[int, int]]:
    """alpha_composite 는 캔버스 밖 좌표를 받지 않으므로 겹치는 부분만 잘라 돌려준다."""
    x, y = dest
    left, top = max(0, -x), max(0, -y)
    right, bottom = min(item.width, canvas_size[0] - x), min(item.height, canvas_size[1] - y)
    if right <= left or bottom <= top:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0)), (0, 0)
    return item.crop((left, top, right, bottom)), (x + left, y + top)


# ---------- brand ----------

def applies_to_slide(rule: str, ctx: Ctx) -> bool:
    return {"all": True, "first": ctx.index == 0, "last": ctx.index == ctx.count - 1}.get(rule, False)


def render_brand(canvas: Image.Image, layer: Mapping[str, Any], ctx: Ctx) -> Image.Image:
    layer = slide_override(layer, ctx)
    out = canvas.copy()
    d = ImageDraw.Draw(out)
    w, h = out.size
    pn = layer.get("page_number", {})
    if pn.get("present"):
        text = pn.get("format", "n/N").replace("N", str(ctx.count)).replace("n", str(ctx.index + 1))
        font = load_font(ctx.typography["families"]["body"], int(pn.get("weight", 500)), int(pn.get("size_px", 32)))
        m = int(w * float(pn.get("margin_pct", 6)) / 100)
        pos = {"top_left": (m, m), "top_right": (w - m - font.getlength(text), m), "bottom_left": (m, h - m - font.size), "bottom_right": (w - m - font.getlength(text), h - m - font.size)}[pn.get("position", "top_left")]
        d.text(pos, text, font=font, fill=hex_to_rgb(pn.get("color", "#6B6B6B")))
    logo = layer.get("logo", {})
    if logo.get("present") and applies_to_slide(logo.get("slides", "all"), ctx):
        img = Image.open(ctx.assets_dir / logo["file"]).convert("RGBA")
        size = int(logo.get("size_px", 96))
        img = img.resize((size, size), Image.LANCZOS)
        if logo.get("radius_px"):
            img.putalpha(rounded_mask(img.size, int(logo["radius_px"])))
        m = int(w * float(logo.get("margin_pct", 6)) / 100)
        pos = {"corner_tr": (w - m - size, m), "corner_tl": (m, m), "corner_bl": (m, h - m - size), "corner_br": (w - m - size, h - m - size), "center": ((w - size) // 2, (h - size) // 2)}[logo.get("position", "corner_tr")]
        rgba = out.convert("RGBA")
        rgba.alpha_composite(img, pos)
        out = rgba.convert("RGB")
    return out


def render_decoration(canvas: Image.Image, layer: Mapping[str, Any], ctx: Ctx) -> Image.Image:
    if layer.get("kind", "none") != "none":
        raise ValueError(f"decoration.kind={layer['kind']} 미구현 (라이선스 확인된 에셋 없음)")
    return canvas


RENDERERS: dict[str, Callable[[Image.Image, Mapping[str, Any], Ctx], Image.Image]] = {
    "background": render_background,
    "caption": render_caption,
    "device_frame": render_device_frame,
    "ui_popout": render_ui_popout,
    "screen": render_screen,
    "brand": render_brand,
    "decoration": render_decoration,
}
