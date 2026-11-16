"""폰트 로딩과 텍스트 줄바꿈 (순수 함수 위주).

Pillow는 자동 줄바꿈이 없으므로(doc/00_마케팅/01_소재_디자인_리서치/06 F-TL) 단어 단위로 직접 접는다.
한글 줄바꿈은 단어 단위를 기본으로 하고, 한 단어가 폭을 넘으면 글자 단위로 접는다 (W3C klreq).
강조 마크업: 텍스트 안의 `[[단어]]`는 emphasis 색으로 그린다 (Evernote 핵심 어구 색, raw/07).
`[[저장]]하면`처럼 단어 안에서도 쓸 수 있다 (공백 없이 이어 그린다).
"""
from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path
from typing import Sequence

from PIL import ImageFont

Segment = tuple[str, bool]          # (글자열, 강조 여부)
Word = tuple[Segment, ...]          # 공백 없이 이어지는 세그먼트 묶음
NEWLINE: Word = (("\n", False),)

# family 이름 -> 파일 경로. 시스템 폰트는 라이선스가 OS에 묶여 있으므로 배포용은 OFL 폰트(Pretendard 등)로 교체 가능.
FONT_FILES = {
    "system_sd_gothic": "/System/Library/Fonts/AppleSDGothicNeo.ttc",
    "pretendard": str(Path(__file__).resolve().parent.parent / "assets" / "fonts" / "PretendardVariable.ttf"),
}

# Apple SD Gothic Neo .ttc의 face index (2026-11-12 getname()으로 확인)
SD_GOTHIC_INDEX = {100: 10, 200: 12, 300: 8, 400: 0, 500: 2, 600: 4, 700: 6, 800: 14, 900: 16}

EMPHASIS_RE = re.compile(r"\[\[(.+?)\]\]")


def nearest_weight(weight: int, available: Sequence[int]) -> int:
    return min(available, key=lambda w: abs(w - weight))


@lru_cache(maxsize=None)
def load_font(family: str, weight: int, size_px: int) -> ImageFont.FreeTypeFont:
    path = FONT_FILES.get(family, family)
    if not Path(path).exists():
        raise FileNotFoundError(f"폰트 파일 없음: {family} -> {path}")
    if path.endswith(".ttc"):
        idx = SD_GOTHIC_INDEX[nearest_weight(weight, list(SD_GOTHIC_INDEX))]
        return ImageFont.truetype(path, size_px, index=idx)
    font = ImageFont.truetype(path, size_px)
    try:  # 가변 폰트(Pretendard Variable)는 축으로 굵기 지정
        font.set_variation_by_axes([weight])
    except OSError:
        pass
    return font


def parse_segments(text: str) -> list[Segment]:
    """'[[강조]] 일반' -> [('강조', True), (' 일반', False)] (공백·줄바꿈 보존)."""
    out: list[Segment] = []
    pos = 0
    for m in EMPHASIS_RE.finditer(text):
        out.append((text[pos:m.start()], False))
        out.append((m.group(1), True))
        pos = m.end()
    out.append((text[pos:], False))
    return [s for s in out if s[0]]


def tokenize(text: str) -> list[Word]:
    """세그먼트를 공백·줄바꿈 기준으로 단어로 묶는다. 줄바꿈은 NEWLINE 단어."""
    words: list[list[Segment]] = [[]]
    for seg_text, emph in parse_segments(text):
        for i, line in enumerate(seg_text.split("\n")):
            if i:
                words += [list(NEWLINE), []]
            for j, part in enumerate(line.split(" ")):
                if j:
                    words.append([])
                if part:
                    words[-1].append((part, emph))
    return [tuple(w) for w in words if w]


def word_text(word: Word) -> str:
    return "".join(s for s, _ in word)


def wrap_tokens(words: Sequence[Word], font: ImageFont.FreeTypeFont, max_width: float) -> list[list[Word]]:
    """단어를 max_width 안에 접는다. 단어 하나가 넘치면 글자 단위."""
    lines: list[list[Word]] = [[]]
    for word in words:
        if word == NEWLINE:
            lines.append([])
            continue
        for piece in _split_long(word, font, max_width):
            candidate = lines[-1] + [piece]
            if lines[-1] and line_width(candidate, font) > max_width:
                lines.append([piece])
            else:
                lines[-1] = candidate
    return [ln for ln in lines if ln] or [[]]


def _split_long(word: Word, font: ImageFont.FreeTypeFont, max_width: float) -> list[Word]:
    if font.getlength(word_text(word)) <= max_width:
        return [word]
    chars: list[Segment] = [(ch, emph) for s, emph in word for ch in s]
    pieces: list[list[Segment]] = [[]]
    for ch in chars:
        if pieces[-1] and font.getlength(word_text(tuple(pieces[-1] + [ch]))) > max_width:
            pieces.append([ch])
        else:
            pieces[-1].append(ch)
    return [merge_segments(p) for p in pieces if p]


def merge_segments(segments: Sequence[Segment]) -> Word:
    """같은 강조 여부가 이어지면 하나의 세그먼트로 합친다."""
    merged: list[Segment] = []
    for text, emph in segments:
        if merged and merged[-1][1] == emph:
            merged[-1] = (merged[-1][0] + text, emph)
        else:
            merged.append((text, emph))
    return tuple(merged)


def line_width(line: Sequence[Word], font: ImageFont.FreeTypeFont) -> float:
    return font.getlength(" ".join(word_text(w) for w in line))


def plain_text(words: Sequence[Word]) -> str:
    return " ".join(word_text(w) for w in words if w != NEWLINE)
