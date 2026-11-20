#!/usr/bin/env python3
"""마케팅 파이프라인 PoC: 스토어 스크린샷 1세트 -> 플랫폼별 변형 소재 렌더링 -> 규격 검증.

Usage: python render_and_validate.py <screenshot_dir> <store_listing.yaml> <out_dir>
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
import yaml
from PIL import Image, ImageDraw, ImageFont

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

# 플랫폼별 이미지 규격 (w, h, 최대 바이트, 허용 포맷)
IMAGE_SPECS = {
    "instagram_feed_4x5": dict(size=(1080, 1350), max_bytes=8 * 1024**2, fmt="JPEG"),
    "instagram_square": dict(size=(1080, 1080), max_bytes=8 * 1024**2, fmt="JPEG"),
    "threads_4x5": dict(size=(1080, 1350), max_bytes=8 * 1024**2, fmt="JPEG"),
    "x_16x9": dict(size=(1600, 900), max_bytes=5 * 1024**2, fmt="JPEG"),
    "facebook_photo": dict(size=(1080, 1350), max_bytes=4 * 1024**2, fmt="JPEG"),
    "linkedin_1x1": dict(size=(1200, 1200), max_bytes=5 * 1024**2, fmt="JPEG"),
    "pinterest_2x3": dict(size=(1000, 1500), max_bytes=20 * 1024**2, fmt="JPEG"),
    "bluesky_4x5": dict(size=(1080, 1350), max_bytes=1_000_000, fmt="JPEG"),
    "kakao_brand_2x1": dict(size=(800, 400), max_bytes=5 * 1024**2, fmt="JPEG"),
    "play_feature_graphic": dict(size=(1024, 500), max_bytes=15 * 1024**2, fmt="PNG", no_alpha=True),
}

# 영상 규격 (w, h, 길이 범위 초, 최대 fps, 최대 바이트)
VIDEO_SPECS = {
    "shorts_reels_tiktok_9x16": dict(size=(1080, 1920), dur=(3, 60), max_fps=60, max_bytes=287 * 1024**2),
    "app_preview_iphone": dict(size=(886, 1920), dur=(15, 30), max_fps=30, max_bytes=500 * 1024**2, min_kbps=9000),
    "x_video_9x16": dict(size=(720, 1280), dur=(0.5, 140), max_fps=60, max_bytes=512 * 1024**2),
}

BG = (18, 18, 24)
FG = (255, 255, 255)


def font(size: int) -> ImageFont.FreeTypeFont:
    for p in ["/System/Library/Fonts/AppleSDGothicNeo.ttc", "/System/Library/Fonts/Supplemental/AppleGothic.ttf"]:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def compose(shot: Path, size: tuple[int, int], caption: str) -> Image.Image:
    """캔버스 비율에 맞춰 스크린샷을 contain 배치 + 상단 캡션."""
    w, h = size
    canvas = Image.new("RGB", size, BG)
    cap_h = int(h * 0.16) if h >= w else 0
    img = Image.open(shot).convert("RGB")
    area = (int(w * 0.9), int((h - cap_h) * 0.92))
    img.thumbnail(area, Image.LANCZOS)
    x = (w - img.width) // 2 if cap_h else int(w * 0.55)
    y = cap_h + ((h - cap_h) - img.height) // 2
    canvas.paste(img, (x, y))
    d = ImageDraw.Draw(canvas)
    if cap_h:
        f = font(max(20, int(w * 0.055)))
        d.text((w // 2, cap_h // 2), caption, font=f, fill=FG, anchor="mm")
    else:  # 가로형: 좌측 텍스트, 우측 스크린샷
        f = font(max(20, int(h * 0.08)))
        d.text((int(w * 0.06), h // 2), caption, font=f, fill=FG, anchor="lm")
    return canvas


def render_images(shots: list[Path], caption: str, out: Path) -> list[Path]:
    paths = []
    for name, spec in IMAGE_SPECS.items():
        for i, shot in enumerate(shots[:1] if "feature" in name or "kakao" in name else shots):
            p = out / f"{name}_{i}.{'png' if spec['fmt'] == 'PNG' else 'jpg'}"
            img = compose(shot, spec["size"], caption)
            if spec["fmt"] == "PNG":
                img.save(p, "PNG")
            else:
                q = 90
                img.save(p, "JPEG", quality=q)
                while p.stat().st_size > spec["max_bytes"] and q > 40:  # 용량 상한 맞춤 (Bluesky 1MB 등)
                    q -= 10
                    img.save(p, "JPEG", quality=q)
            paths.append(p)
    return paths


def render_videos(shots: list[Path], caption: str, out: Path) -> list[Path]:
    paths = []
    for name, spec in VIDEO_SPECS.items():
        w, h = spec["size"]
        lo, hi = spec["dur"]
        target = max(lo, min(hi, 20.0))
        per = target / len(shots)
        frames = []
        for i, shot in enumerate(shots):
            fp = out / f"_{name}_frame{i}.png"
            compose(shot, (w, h), caption).save(fp)
            frames.append(fp)
        listfile = out / f"_{name}_list.txt"
        listfile.write_text("".join(f"file '{f.resolve()}'\nduration {per}\n" for f in frames) + f"file '{frames[-1].resolve()}'\n")  # concat은 목록 파일 기준으로 상대 경로를 해석하므로 절대 경로
        p = out / f"{name}.mp4"
        cmd = [FFMPEG, "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(listfile),
               "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
               "-vf", f"fps=30,{'noise=alls=6:allf=t,' if spec.get('min_kbps') else ''}format=yuv420p,scale={w}:{h}", "-c:v", "libx264", "-profile:v", "high",
               "-level", "4.0", *(["-b:v", "10M", "-minrate", "10M", "-maxrate", "12M", "-bufsize", "20M",
                                   "-x264-params", "nal-hrd=cbr"] if spec.get("min_kbps") else ["-b:v", "10M"]), "-c:a", "aac", "-b:a", "256k", "-shortest",
               "-t", str(target), "-movflags", "+faststart", str(p)]
        subprocess.run(cmd, check=True)
        paths.append(p)
    return paths


def probe(p: Path) -> dict:
    r = subprocess.run([FFMPEG, "-i", str(p)], capture_output=True, text=True)
    s = r.stderr
    dur = re.search(r"Duration: (\d+):(\d+):([\d.]+)", s)
    v = re.search(r"Video: (\w+).*?, (\d+)x(\d+).*?, ([\d.]+) fps", s)
    a = re.search(r"Audio: (\w+).*?, (\d+) Hz, (\w+)", s)
    return dict(
        duration=int(dur[1]) * 3600 + int(dur[2]) * 60 + float(dur[3]),
        vcodec=v[1], w=int(v[2]), h=int(v[3]), fps=float(v[4]),
        acodec=a[1] if a else None, sr=int(a[2]) if a else None, layout=a[3] if a else None,
        bytes=p.stat().st_size,
    )


def validate(images: list[Path], videos: list[Path]) -> list[dict]:
    rows = []
    for p in images:
        key = p.stem.rsplit("_", 1)[0]
        spec = IMAGE_SPECS[key]
        im = Image.open(p)
        errs = []
        if im.size != spec["size"]:
            errs.append(f"size {im.size}")
        if p.stat().st_size > spec["max_bytes"]:
            errs.append(f"bytes {p.stat().st_size}")
        if im.format != spec["fmt"]:
            errs.append(f"fmt {im.format}")
        if spec.get("no_alpha") and im.mode in ("RGBA", "LA", "P"):
            errs.append(f"alpha mode {im.mode}")
        rows.append(dict(file=p.name, ok=not errs, detail=f"{im.size[0]}x{im.size[1]} {im.format} {p.stat().st_size//1024}KB", errors=errs))
    for p in videos:
        spec = VIDEO_SPECS[p.stem]
        m = probe(p)
        errs = []
        if (m["w"], m["h"]) != spec["size"]:
            errs.append(f"size {m['w']}x{m['h']}")
        if not (spec["dur"][0] <= m["duration"] <= spec["dur"][1]):
            errs.append(f"duration {m['duration']}")
        if m["fps"] > spec["max_fps"]:
            errs.append(f"fps {m['fps']}")
        if m["bytes"] > spec["max_bytes"]:
            errs.append(f"bytes {m['bytes']}")
        kbps = m["bytes"] * 8 / 1000 / m["duration"]
        if spec.get("min_kbps") and kbps < spec["min_kbps"]:
            errs.append(f"bitrate {kbps:.0f}kbps")
        if m["vcodec"] != "h264" or m["acodec"] != "aac" or m["layout"] != "stereo":
            errs.append(f"codec {m['vcodec']}/{m['acodec']}/{m['layout']}")
        rows.append(dict(file=p.name, ok=not errs,
                         detail=f"{m['w']}x{m['h']} {m['duration']:.2f}s {m['fps']}fps {m['vcodec']}/{m['acodec']} {m['sr']}Hz {m['bytes']//1024}KB",
                         errors=errs))
    return rows


def main() -> int:
    shot_dir, listing, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)
    cfg = yaml.safe_load(listing.read_text(encoding="utf-8"))
    caption = cfg["name_ko"]
    shots = sorted(shot_dir.glob("*_APP_IPHONE_65_*.png"))
    if not shots:
        print("no screenshots"); return 2
    images = render_images(shots, caption, out)
    videos = render_videos(shots, caption, out)
    rows = validate(images, videos)
    for f in out.glob("_*"):
        f.unlink()
    for r in rows:
        print(("PASS" if r["ok"] else "FAIL"), r["file"], r["detail"], *r["errors"])
    print(json.dumps(dict(total=len(rows), passed=sum(r["ok"] for r in rows))))
    return 0 if all(r["ok"] for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
