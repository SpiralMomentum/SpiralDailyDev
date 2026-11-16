"""템플릿과 문구의 분리.

템플릿(프리셋 yaml)에는 문구도, 특정 앱의 값도 쓰지 않고 자리표시자만 둔다.
  "{{app.brand.primary}}"  앱 프로필(apps/<이름>.yaml)의 값. 점으로 경로를 쓴다 (app.name, app.font, app.brand.logo ...)
  "{{headline}}"   필수. 카피에 키가 없으면 오류
  "{{body?}}"      선택. 카피에 키가 없으면 빈 문자열
값 전체가 자리표시자 하나이면 카피 값을 그대로(리스트·딕셔너리 포함) 넣고, 문장 속에 섞여 있으면 문자열로 치환한다.
카피는 장 순서대로의 딕셔너리 목록이다 (copy/*.yaml 의 voices.<이름>).
"""
from __future__ import annotations

import re
from typing import Any, Mapping, Sequence

PLACEHOLDER = re.compile(r"\{\{\s*([\w.]+)(\?)?\s*\}\}")


def fill_value(value: Any, slide_copy: Mapping[str, Any], where: str) -> Any:
    if isinstance(value, dict):
        return {k: fill_value(v, slide_copy, f"{where}.{k}") for k, v in value.items()}
    if isinstance(value, list):
        return [fill_value(v, slide_copy, where) for v in value]
    if not isinstance(value, str):
        return value

    def resolve(key: str, optional: str | None) -> Any:
        if key in slide_copy:
            return slide_copy[key]
        if optional:
            return ""
        raise ValueError(f"{where}: 카피에 '{key}' 가 없다")

    whole = PLACEHOLDER.fullmatch(value.strip())
    if whole:
        return resolve(*whole.groups())
    return PLACEHOLDER.sub(lambda m: str(resolve(m.group(1), m.group(2))), value)


def fill_copy(preset: Mapping[str, Any], copy_slides: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    """템플릿 장 수와 카피 장 수가 같아야 한다 (조용한 누락 방지)."""
    slides = preset.get("slides") or []
    if len(slides) != len(copy_slides):
        raise ValueError(f"템플릿 {len(slides)}장, 카피 {len(copy_slides)}장: 장 수가 같아야 한다")
    return {**preset, "slides": [fill_value(s, c, f"slides[{i}]") for i, (s, c) in enumerate(zip(slides, copy_slides))]}


def placeholders(preset: Mapping[str, Any]) -> dict[str, bool]:
    """템플릿이 요구하는 키 -> 필수 여부 (필수가 한 번이라도 있으면 True). app.* 키와 카피 키가 함께 나온다."""
    found: dict[str, bool] = {}

    def walk(v: Any) -> None:
        if isinstance(v, dict):
            [walk(x) for x in v.values()]
        elif isinstance(v, list):
            [walk(x) for x in v]
        elif isinstance(v, str):
            for key, opt in PLACEHOLDER.findall(v):
                found[key] = found.get(key, False) or not opt

    walk(preset)
    return found


def lookup(profile: Mapping[str, Any], dotted: str) -> Any:
    cur: Any = profile
    for part in dotted.split("."):
        if not isinstance(cur, Mapping) or part not in cur:
            raise KeyError(dotted)
        cur = cur[part]
    return cur


def fill_app(preset: Any, profile: Mapping[str, Any]) -> Any:
    """{{app.x.y}} 를 앱 프로필 값으로 치환한다 (프리셋 전체). app. 으로 시작하지 않는 키는 그대로 둔다."""
    if isinstance(preset, dict):
        return {k: fill_app(v, profile) for k, v in preset.items()}
    if isinstance(preset, list):
        return [fill_app(v, profile) for v in preset]
    if not isinstance(preset, str):
        return preset

    def get(key: str, optional: str | None) -> Any:
        try:
            return lookup(profile, key[4:])
        except KeyError:
            if optional:
                return ""
            raise ValueError(f"앱 프로필에 '{key[4:]}' 가 없다 (템플릿이 {{{{{key}}}}} 를 요구)") from None

    whole = PLACEHOLDER.fullmatch(preset.strip())
    if whole and whole.group(1).startswith("app."):
        return get(*whole.groups())
    return PLACEHOLDER.sub(lambda m: str(get(m.group(1), m.group(2))) if m.group(1).startswith("app.") else m.group(0), preset)


def derive_screen(copy_slides: Sequence[Mapping[str, Any]], screens: Mapping[str, Any], *, stack: bool = False) -> list[dict[str, Any]]:
    """카피의 screen(이름 하나 또는 목록)/with 에서 템플릿이 쓰는 파생 키를 만든다.
    screens = 화면 이름 목록(stack 이면 with 가 앞에 붙는다), shot/crop = 마지막 화면의 스크린샷 번호와 크롭."""
    out = []
    for x in copy_slides:
        names = [x["screen"]] if isinstance(x["screen"], str) else list(x["screen"])
        missing = [n for n in [*names, *x.get("with", [])] if n not in screens]
        if missing:
            raise ValueError(f"앱 프로필 screens 에 없는 화면 이름: {missing}")
        entry = screens[names[-1]]
        out.append({**x, "screens": [*x.get("with", []), *names] if stack else names,
                    "shot": entry["shot"], "crop": entry.get("crop") or [0, 0, 1, 1]})
    return out


def compose(template: Mapping[str, Any], profile: Mapping[str, Any], copy_slides: Sequence[Mapping[str, Any]],
            *, stack: bool = False) -> dict[str, Any]:
    """템플릿 + 앱 프로필 + 카피 -> 렌더 가능한 프리셋. 앱 프로필의 screens 도 프리셋에 넣는다."""
    derived = derive_screen(copy_slides, profile.get("screens") or {}, stack=stack) if any("screen" in c for c in copy_slides) else list(copy_slides)
    filled = fill_app(fill_copy(fill_app(template, profile), derived), profile)
    filled = mark_repeats(filled)
    return {**filled, **({"screens": profile["screens"]} if "screens" in profile and "screens" not in filled else {})}


def mark_repeats(preset: Mapping[str, Any]) -> dict[str, Any]:
    """장마다 맨 앞 화면이 앞 장들에서 몇 번 쓰였는지 slide.repeat 로 적는다 (9회차, 반복이면 초점 확대)."""
    seen: dict[str, int] = {}
    slides = []
    for sl in preset.get("slides") or []:
        ref = sl.get("screen")
        names = [ref] if isinstance(ref, str) else list(ref or [])
        key = names[-1] if names else None
        n = seen.get(key, 0) if key else 0
        if key:
            seen[key] = n + 1
        slides.append({**sl, "repeat": n})
    return {**preset, "slides": slides}


def assert_filled(preset: Mapping[str, Any]) -> None:
    left = placeholders(preset)
    if left:
        raise ValueError(f"채워지지 않은 자리표시자: {sorted(left)}. --app(앱 프로필)과 --copy(카피)를 지정하세요")
