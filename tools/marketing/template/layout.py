"""화면 배치 계산 (순수 함수, 이미지 I/O 없음).

캔버스를 캡션 영역과 화면(visual) 영역으로 나누고, 앱 화면을 화면 영역 안에 맞춘다.
렌더(layers.render_screen)와 검증(render.measure_slide)이 같은 함수를 쓰므로
"그려진 것"과 "검증한 것"이 어긋나지 않는다.

fit 모드
  contain  : 화면 전체(크롭 후)가 영역 안에 들어오도록 비율 유지 축소. 잘림 없음.
  crop_top : 폭을 영역 폭에 맞추고, 아래가 캔버스 밖으로 잘리게 둔다(의도된 걸침). 위쪽부터 보인다.
"""
from __future__ import annotations

from dataclasses import dataclass, replace
from typing import Sequence, Mapping, Any


@dataclass(frozen=True)
class Box:
    x: int
    y: int
    w: int
    h: int


@dataclass(frozen=True)
class Placement:
    pos: tuple[int, int]        # 화면 이미지 좌상단 (캔버스 좌표, 캔버스 밖일 수 있음)
    size: tuple[int, int]       # 크롭 후 화면을 리사이즈한 크기
    visible: Box                # 캔버스와 겹치는 부분
    scale: float = 1.0          # 원본 대비 배율 (글자 가독성 지표)
    tilt: float = 0.0           # 면 안 회전각 roll (도). 양수 = 반시계 (PIL 기준)
    yaw: float = 0.0            # 세로축 회전 (도). 3D 원근 (perspective.py)
    pitch: float = 0.0          # 가로축 회전 (도)


FIT_MODES = ("contain", "crop_top")


def split_regions(canvas: tuple[int, int], caption_area_pct: float, caption_position: str = "top",
                  margin_pct: float = 4.0) -> tuple[Box, Box]:
    """(캡션 영역, 화면 영역). 화면 영역은 캔버스 가장자리까지 이어진다(걸침 허용), 좌우만 margin."""
    w, h = canvas
    cap_h = round(h * caption_area_pct / 100)
    m = round(w * margin_pct / 100)
    if caption_position == "bottom":
        return Box(0, h - cap_h, w, cap_h), Box(m, 0, w - 2 * m, h - cap_h)
    return Box(0, 0, w, cap_h), Box(m, cap_h, w - 2 * m, h - cap_h)


def inset_far_edge(box: Box, canvas: tuple[int, int], caption_position: str, margin_px: int) -> Box:
    """contain 은 캔버스 가장자리에 붙지 않도록 가장자리 쪽에 여백을 둔다."""
    if caption_position == "bottom":
        return Box(box.x, box.y + margin_px, box.w, box.h - margin_px)
    return Box(box.x, box.y, box.w, box.h - margin_px)


def split_cells(box: Box, count: int, max_width_fraction: float, gap_px: int) -> list[Box]:
    """영역 폭의 max_width_fraction 만큼을 가운데 정렬해 count 칸으로 나눈다."""
    group_w = round(box.w * max_width_fraction)
    cell_w = (group_w - gap_px * (count - 1)) // count
    x0 = box.x + (box.w - group_w) // 2
    return [Box(x0 + i * (cell_w + gap_px), box.y, cell_w, box.h) for i in range(count)]


def clip(box: Box, canvas: tuple[int, int]) -> Box:
    x0, y0 = max(box.x, 0), max(box.y, 0)
    x1, y1 = min(box.x + box.w, canvas[0]), min(box.y + box.h, canvas[1])
    return Box(x0, y0, max(0, x1 - x0), max(0, y1 - y0))


def fit_placement(src: tuple[int, int], cell: Box, mode: str, canvas: tuple[int, int],
                  caption_position: str = "top", margin_px: int = 0) -> Placement:
    if mode not in FIT_MODES:
        raise ValueError(f"fit={mode!r} 는 {FIT_MODES} 중 하나여야 한다")
    sw, sh = src
    if mode == "contain":
        inner = inset_far_edge(cell, canvas, caption_position, margin_px)
        scale = min(inner.w / sw, inner.h / sh)
        size = (round(sw * scale), round(sh * scale))
        pos = (inner.x + (inner.w - size[0]) // 2, inner.y + (inner.h - size[1]) // 2)
    else:
        scale = cell.w / sw
        size = (round(sw * scale), round(sh * scale))
        y = cell.y + cell.h - size[1] if caption_position == "bottom" else cell.y
        pos = (cell.x + (cell.w - size[0]) // 2, y)
    return Placement(pos, size, clip(Box(pos[0], pos[1], size[0], size[1]), canvas), size[0] / sw)


def resolve_tilts(tilts: Sequence[float], fallback: float, n: int) -> list[float]:
    """카드별 기울기. tilts 는 뒤 -> 앞 순서이며 끝에서 n개를 쓴다. 비어 있으면 fallback 을 모두에 적용."""
    if not tilts:
        return [float(fallback)] * n
    picked = [float(t) for t in tilts][-n:]
    return [0.0] * (n - len(picked)) + picked


def resolve_poses(poses: Sequence[Mapping[str, float]], tilts: Sequence[float], fallback: float, n: int) -> list[tuple[float, float, float]]:
    """카드별 (roll, yaw, pitch). poses 는 뒤 -> 앞 순서 dict 목록({roll, yaw, pitch}, 생략 키는 0)이며 끝에서 n개를 쓴다.
    poses 가 비어 있으면 기존 tilts/tilt_deg 를 roll 로만 쓴다."""
    if not poses:
        return [(t, 0.0, 0.0) for t in resolve_tilts(tilts, fallback, n)]
    picked = [dict(x or {}) for x in poses][-n:]
    picked = [{}] * (n - len(picked)) + picked
    return [(float(x.get("roll", 0)), float(x.get("yaw", 0)), float(x.get("pitch", 0))) for x in picked]


def plan_stack(canvas: tuple[int, int], sources: Sequence[tuple[int, int]], *, caption_area_pct: float,
               caption_position: str, margin_pct: float, fit: str, max_width_fraction: float,
               dx_pct: float, dy_pct: float, scale_step: float, side: str, shift_x_pct: float) -> list[Placement]:
    """겹쳐 쌓기: sources 는 뒤 -> 앞 순서. 앞 카드가 가장 크고, 뒤 카드는 scale_step 배씩 작아지며
    side 쪽으로 dx 만큼, 아래로 dy 만큼 어긋나 앞 카드 뒤로 삐져나온다. shift_x_pct 로 묶음 전체를 옆으로 밀어
    캔버스 가장자리 밖으로 걸치게 할 수 있다."""
    _, visual = split_regions(canvas, caption_area_pct, caption_position, margin_pct)
    margin_px = round(canvas[0] * margin_pct / 100)
    n = len(sources)
    dx, dy = round(visual.w * dx_pct / 100), round(canvas[1] * dy_pct / 100)
    sign = -1 if side == "left" else 1
    front_w = max(1, round(visual.w * max_width_fraction) - (n - 1) * dx)
    span = front_w + (n - 1) * dx
    left0 = visual.x + (visual.w - span) // 2 + round(canvas[0] * shift_x_pct / 100)
    front_cx = left0 + ((n - 1) * dx if side == "left" else 0) + front_w // 2
    out = []
    for i, src in enumerate(sources):
        k = n - 1 - i
        w = round(front_w * scale_step ** k)
        cell = Box(front_cx + sign * k * dx - w // 2, visual.y + k * dy, w, visual.h - k * dy)
        out.append(fit_placement(src, cell, fit, canvas, caption_position, margin_px))
    return out


def plan_screens(canvas: tuple[int, int], sources: Sequence[tuple[int, int]], *, caption_area_pct: float,
                 caption_position: str = "top", margin_pct: float = 4.0, fit: str = "contain",
                 max_width_fraction: float = 0.9, gap_px: int = 24, arrange: str = "row",
                 stack: Mapping[str, Any] | None = None, tilts: Sequence[float] = (), tilt_deg: float = 0.0,
                 shift_x_pct: float = 0.0, poses: Sequence[Mapping[str, float]] = ()) -> list[Placement]:
    """한 장에 들어가는 화면 배치. sources = 크롭 후 화면 원본 크기 목록 (stack 은 뒤 -> 앞 순서).

    arrange: row   = 나란히 (최대 2개)
             stack = 겹쳐 쌓기 (최대 3개, stack: {dx_pct, dy_pct, scale_step, side})
    """
    if arrange not in ("row", "stack"):
        raise ValueError(f"arrange={arrange!r} 는 row | stack 이어야 한다")
    if arrange == "stack":
        st = stack or {}
        placements = plan_stack(canvas, sources, caption_area_pct=caption_area_pct, caption_position=caption_position,
                                margin_pct=margin_pct, fit=fit, max_width_fraction=max_width_fraction,
                                dx_pct=float(st.get("dx_pct", 10)), dy_pct=float(st.get("dy_pct", 5)),
                                scale_step=float(st.get("scale_step", 0.92)), side=st.get("side", "left"),
                                shift_x_pct=shift_x_pct)
    else:
        _, visual = split_regions(canvas, caption_area_pct, caption_position, margin_pct)
        margin_px = round(canvas[0] * margin_pct / 100)
        cells = split_cells(visual, len(sources), max_width_fraction, gap_px)
        shifted = [Box(c.x + round(canvas[0] * shift_x_pct / 100), c.y, c.w, c.h) for c in cells]
        placements = [fit_placement(src, cell, fit, canvas, caption_position, margin_px) for src, cell in zip(sources, shifted)]
    return [replace(p, tilt=r, yaw=y, pitch=pi)
            for p, (r, y, pi) in zip(placements, resolve_poses(poses, tilts, tilt_deg, len(placements)))]


def coverage(canvas: tuple[int, int], placements: Sequence[Placement]) -> dict[str, float]:
    """노출 지표: 가장 큰 화면의 노출 높이 비율, 노출 면적 합 비율(캔버스 대비, %)."""
    ch_total = canvas[0] * canvas[1]
    return {
        "visible_height_pct": round(max((p.visible.h for p in placements), default=0) / canvas[1] * 100, 1),
        "visible_area_pct": round(sum(p.visible.w * p.visible.h for p in placements) / ch_total * 100, 1),
        "min_screen_scale": round(min((p.scale for p in placements), default=1.0), 2),
        # 좌우로 캔버스 밖에 나간 정도 (회전 무시, 외접 사각형 기준)
        "min_visible_width_pct": round(min((p.visible.w / p.size[0] * 100 for p in placements), default=100.0), 1),
    }
