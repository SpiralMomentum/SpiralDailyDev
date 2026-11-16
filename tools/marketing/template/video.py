"""장(slide) 단위 이미지를 시간축 위에서 움직여 MP4 로 만든다.

같은 프리셋·카피를 그대로 쓴다. 장마다 (배경만) / (전체) 두 장을 렌더하고,
캡션 영역과 화면 영역을 나눠 등장·정지·퇴장 애니메이션을 합성한다.
시간 계산(ease, frame_state)은 순수 함수이고, 프레임 합성과 인코딩만 부수효과다.
"""
from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from PIL import Image

from template.copy import assert_filled
from template.render import render_slide

FPS = 30


@dataclass(frozen=True)
class Motion:
    """한 장의 시간 구성 (초, px). 값은 우리 설정이며 관측 근거가 없다."""
    duration: float = 3.2
    caption_in: tuple[float, float] = (0.0, 0.5)   # (시작, 길이)
    visual_in: tuple[float, float] = (0.25, 0.65)
    caption_rise_px: int = 36
    visual_rise_px: int = 220
    drift_px: int = 24          # 등장 뒤 화면이 위로 천천히 흐르는 거리
    exit_len: float = 0.25      # 마지막 몇 초 동안 배경으로 사라짐


def clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))


def ease_out(x: float) -> float:
    return 1 - (1 - clamp01(x)) ** 3


def progress(t: float, window: tuple[float, float]) -> float:
    start, length = window
    return clamp01((t - start) / length) if length > 0 else 1.0


def frame_state(t: float, m: Motion) -> dict[str, float]:
    """시각 t 의 캡션/화면 투명도·세로 오프셋·퇴장 비율."""
    c, v = ease_out(progress(t, m.caption_in)), ease_out(progress(t, m.visual_in))
    drift = clamp01((t - sum(m.visual_in)) / max(0.01, m.duration - sum(m.visual_in))) * m.drift_px
    return {"cap_alpha": c, "cap_dy": round((1 - c) * m.caption_rise_px),
            "vis_alpha": v, "vis_dy": round((1 - v) * m.visual_rise_px - drift),
            "exit": clamp01((t - (m.duration - m.exit_len)) / m.exit_len)}


def caption_height(preset: Mapping[str, Any]) -> int:
    pct = (preset.get("layout") or {}).get("caption_area_pct", 34)
    return round(int(preset["canvas"]["height_px"]) * pct / 100)


def render_pair(preset: Mapping[str, Any], index: int, shots: Sequence[Path], assets_dir: Path) -> tuple[Image.Image, Image.Image]:
    """(배경만, 전체) 렌더."""
    bg_only = {**preset, "layers": [l for l in preset["layers"] if l["type"] == "background"]}
    return render_slide(bg_only, index, shots, assets_dir), render_slide(preset, index, shots, assets_dir)


def compose(base: Image.Image, full: Image.Image, cap_h: int, s: Mapping[str, float]) -> Image.Image:
    w, h = full.size
    out = base.copy()
    for box, dy, alpha in (((0, 0, w, cap_h), s["cap_dy"], s["cap_alpha"]), ((0, cap_h, w, h), s["vis_dy"], s["vis_alpha"])):
        if alpha <= 0:
            continue
        part = full.crop(box)
        out.paste(part, (0, box[1] + dy), Image.new("L", part.size, round(255 * alpha)))
    return Image.blend(out, base, s["exit"]) if s["exit"] > 0 else out


def frames(preset: Mapping[str, Any], shots: Sequence[Path], assets_dir: Path, m: Motion):
    cap_h, n = caption_height(preset), int(m.duration * FPS)
    for i in range(len((preset.get("slides") or [{}]))):
        base, full = render_pair(preset, i, shots, assets_dir)
        for f in range(n):
            yield compose(base, full, cap_h, frame_state(f / FPS, m))


def encode(frame_iter, size: tuple[int, int], out: Path) -> None:
    import imageio_ffmpeg
    cmd = [imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
           "-s", f"{size[0]}x{size[1]}", "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-pix_fmt", "yuv420p",
           "-crf", "18", "-movflags", "+faststart", str(out)]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    try:
        for fr in frame_iter:
            p.stdin.write(fr.convert("RGB").tobytes())
    finally:
        p.stdin.close()
        if p.wait() != 0:
            raise RuntimeError("ffmpeg 인코딩 실패")


def render_video(preset: Mapping[str, Any], shots: Sequence[Path], assets_dir: Path, out: Path, m: Motion = Motion()) -> Path:
    assert_filled(preset)
    out.parent.mkdir(parents=True, exist_ok=True)
    size = (int(preset["canvas"]["width_px"]), int(preset["canvas"]["height_px"]))
    encode(frames(preset, shots, assets_dir, m), size, out)
    return out
