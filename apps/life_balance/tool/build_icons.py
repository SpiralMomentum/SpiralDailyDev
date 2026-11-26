"""앱 아이콘(기우는 금화 + 모래시계 각인 + 금가루) 리소스 생성기.

한 벌의 도형 정의(elements)에서 Android VectorDrawable과 SVG를 같이 만든다.
PNG(레거시 mipmap, 스토어 512px)는 SVG를 headless Chrome으로 렌더링해 만든다.

기하: 108dp 적응형 아이콘 캔버스, 중심 (54,54), 보이는 영역은 가운데 72dp.
- 금화: 반지름 R 원에서 오른쪽 위 45도, 거리 D, 반지름 r 원을 베어낸다.
- 테두리 링: 금화 모양을 RIM_INSET만큼 안쪽으로 줄인 윤곽(큰 원 R-inset, 베인 원 r+inset).
- 모래시계: 먹색, 베인 가장자리와 겹치지 않도록 왼쪽 아래로 치우쳐 둔다.
- 금가루: 베인 가장자리에서 오른쪽 위로 흩어지는 작은 원.

실행 (앱 디렉터리에서): python3 tool/build_icons.py
"""
import math
import pathlib
import shutil
import subprocess
import tempfile

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
DESIGN = ROOT / "design"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

C = 54.0
R, r, D = 24.0, 30.0, 46.0  # 침범 깊이 R + r - D = 8
RIM_INSET, RIM_W, HL_W = 4.0, 1.6, 0.7

IVORY = "#F6F1E7"
GOLD_LIGHT, GOLD_DARK = "#E2C48C", "#967342"
GOLD_RIM, GOLD_HL = "#806034", "#ECD4A0"
INK = "#2B2B2B"
DUST = "#BE965A"
SHADOW = "#6B5530"  # 아이보리 위 33% 알파로 (200,186,160) 근사

BITE = (C + D * math.cos(math.radians(45)), C - D * math.sin(math.radians(45)))


def fmt(v):
    return f"{v:.3f}".rstrip("0").rstrip(".")


def coin_path(Ro=R, ro=r, dx=0.0, dy=0.0):
    ux, uy = math.cos(math.radians(45)), -math.sin(math.radians(45))
    vx, vy = -uy, ux
    a = (Ro * Ro - ro * ro + D * D) / (2 * D)
    h = math.sqrt(Ro * Ro - a * a)
    p1 = (C + a * ux - h * vx + dx, C + a * uy - h * vy + dy)
    p2 = (C + a * ux + h * vx + dx, C + a * uy + h * vy + dy)
    # 큰 원은 베인 쪽 반대로 긴 호, 베인 원은 금화 안쪽 짧은 호
    return (f"M{fmt(p1[0])},{fmt(p1[1])} A{fmt(Ro)},{fmt(Ro)} 0 1,0 {fmt(p2[0])},{fmt(p2[1])} "
            f"A{fmt(ro)},{fmt(ro)} 0 0,1 {fmt(p1[0])},{fmt(p1[1])} Z")


def circle_path(cx, cy, rad):
    return (f"M{fmt(cx - rad)},{fmt(cy)} a{fmt(rad)},{fmt(rad)} 0 1,0 {fmt(2 * rad)},0 "
            f"a{fmt(rad)},{fmt(rad)} 0 1,0 {fmt(-2 * rad)},0 Z")


def poly(points, close=True):
    d = "M" + " L".join(f"{fmt(x)},{fmt(y)}" for x, y in points)
    return d + (" Z" if close else "")


def hourglass():
    cx, cy, k = 51.0, 56.0, 0.95  # 중심을 왼쪽 아래로 (-3, +2), 크기 95%
    hw, hh, cap = 7.0 * k, 10.0 * k, 1.5 * k
    frame = poly([(cx - hw, cy - hh), (cx + hw, cy - hh), (cx + 0.9 * k, cy),
                  (cx + hw, cy + hh), (cx - hw, cy + hh), (cx - 0.9 * k, cy)])
    bars = (poly([(cx - hw - cap, cy - hh), (cx + hw + cap, cy - hh)], close=False) + " "
            + poly([(cx - hw - cap, cy + hh), (cx + hw + cap, cy + hh)], close=False))
    sand = (poly([(cx - hw + 1.6 * k, cy + hh - 1 * k), (cx + hw - 1.6 * k, cy + hh - 1 * k), (cx, cy + 3.5 * k)]) + " "
            + poly([(cx - 2.2 * k, cy - 3.2 * k), (cx + 2.2 * k, cy - 3.2 * k), (cx, cy - 0.6 * k)]))
    return [
        {"d": frame, "stroke": INK, "width": 1.4 * k, "join": "round"},
        {"d": bars, "stroke": INK, "width": 1.4 * k, "cap": "square"},
        {"d": sand, "fill": INK},
    ]


# 금가루: (중심에서 45도 방향 거리, 수직 방향 치우침, 반지름, 불투명도).
# 베인 가장자리(거리 D - r = 16) 바깥에서 시작해 안전 영역(반지름 33) 안에서 끝난다.
_U, _V = (math.cos(math.radians(45)), -math.sin(math.radians(45))), (math.sin(math.radians(45)), math.cos(math.radians(45)))
DUST_DOTS = [(C + t * _U[0] + s * _V[0], C + t * _U[1] + s * _V[1], rad, a) for t, s, rad, a in [
    (19.0, 0.5, 1.7, 1.0), (22.5, -2.0, 1.4, .85), (25.0, 2.2, 1.15, .7), (27.8, -0.8, 0.95, .55),
    (30.0, 2.8, 0.75, .45), (31.5, -3.0, 0.6, .35), (33.0, 0.8, 0.45, .25)]]
assert all(math.hypot(x - C, y - C) + rad <= 34 for x, y, rad, _ in DUST_DOTS)


def elements():
    coin = coin_path()
    hl_off = RIM_INSET + RIM_W / 2 + HL_W / 2
    els = [
        # 그림자: 아래오른쪽으로 비킨 금화, 가장자리로 갈수록 투명
        {"d": coin_path(R + 1.2, r - 1.2, dx=1.2, dy=2.0),
         "radial": (C + 1.2, C + 2.0, R + 1.2, [(0, SHADOW, .33), (.86, SHADOW, .33), (1, SHADOW, 0)])},
        {"d": coin, "radial": (42, 40, 44, [(0, GOLD_LIGHT, 1), (1, GOLD_DARK, 1)])},
        {"d": coin_path(R - RIM_INSET, r + RIM_INSET), "stroke": GOLD_RIM, "width": RIM_W, "clip": coin},
        {"d": coin_path(R - hl_off, r + hl_off), "stroke": GOLD_HL, "width": HL_W, "clip": coin},
        *hourglass(),
    ]
    for x, y, rad, a in DUST_DOTS:
        els.append({"d": circle_path(x, y, rad), "fill": DUST, "alpha": a})
    return els


def argb(hex_rgb, alpha=1.0):
    return f"#{round(alpha * 255):02X}{hex_rgb[1:]}"


def vd_element(e, indent="    "):
    attrs = [f'android:pathData="{e["d"]}"']
    if "fill" in e:
        attrs.append(f'android:fillColor="{argb(e["fill"], e.get("alpha", 1))}"')
    if "stroke" in e:
        attrs.append(f'android:strokeColor="{e["stroke"]}"')
        attrs.append(f'android:strokeWidth="{fmt(e["width"])}"')
        if "join" in e:
            attrs.append(f'android:strokeLineJoin="{e["join"]}"')
        if "cap" in e:
            attrs.append(f'android:strokeLineCap="{e["cap"]}"')
    sep = "\n" + indent + "    "
    if "radial" in e:
        cx, cy, rad, stops = e["radial"]
        items = "".join(
            f'{indent}            <item android:offset="{fmt(o)}" android:color="{argb(c, a)}" />\n' for o, c, a in stops)
        body = (f"{indent}<path{sep}{sep.join(attrs)}>\n"
                f'{indent}    <aapt:attr name="android:fillColor">\n'
                f'{indent}        <gradient android:type="radial" android:centerX="{fmt(cx)}" '
                f'android:centerY="{fmt(cy)}" android:gradientRadius="{fmt(rad)}">\n'
                f"{items}{indent}        </gradient>\n{indent}    </aapt:attr>\n{indent}</path>\n")
    else:
        body = f"{indent}<path{sep}{sep.join(attrs)} />\n"
    if "clip" in e:
        return (f"{indent}<group>\n{indent}    <clip-path android:pathData=\"{e['clip']}\" />\n"
                + "".join("    " + line + "\n" for line in body.rstrip("\n").split("\n"))
                + f"{indent}</group>\n")
    return body


def vector(size_dp, viewport, body):
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- tool/build_icons.py 생성 파일: 직접 고치지 말 것 -->\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    xmlns:aapt="http://schemas.android.com/aapt"\n'
        f'    android:width="{size_dp}dp"\n    android:height="{size_dp}dp"\n'
        f'    android:viewportWidth="{viewport}"\n    android:viewportHeight="{viewport}">\n'
        f"{body}</vector>\n"
    )


def svg_element(e, i):
    defs, attrs = "", [f'd="{e["d"]}"']
    if "radial" in e:
        cx, cy, rad, stops = e["radial"]
        st = "".join(f'<stop offset="{fmt(o)}" stop-color="{c}" stop-opacity="{fmt(a)}"/>' for o, c, a in stops)
        defs += (f'<radialGradient id="g{i}" gradientUnits="userSpaceOnUse" cx="{fmt(cx)}" cy="{fmt(cy)}" '
                 f'r="{fmt(rad)}">{st}</radialGradient>')
        attrs.append(f'fill="url(#g{i})"')
    elif "fill" in e:
        attrs.append(f'fill="{e["fill"]}"')
        if e.get("alpha", 1) != 1:
            attrs.append(f'fill-opacity="{fmt(e["alpha"])}"')
    else:
        attrs.append('fill="none"')
    if "stroke" in e:
        attrs += [f'stroke="{e["stroke"]}"', f'stroke-width="{fmt(e["width"])}"']
        if "join" in e:
            attrs.append(f'stroke-linejoin="{e["join"]}"')
        if "cap" in e:
            attrs.append(f'stroke-linecap="{e["cap"]}"')
    if "clip" in e:
        defs += f'<clipPath id="c{i}"><path d="{e["clip"]}"/></clipPath>'
        attrs.append(f'clip-path="url(#c{i})"')
    return defs, f'  <path {" ".join(attrs)}/>\n'


def svg(background=IVORY, round_mask=False, crop=0.0, px=512):
    """crop: 108 캔버스 가장자리에서 잘라낼 dp. 런처에 보이는 영역은 crop=18."""
    defs, body = "", ""
    for i, e in enumerate(elements()):
        d, b = svg_element(e, i)
        defs, body = defs + d, body + b
    lo, span = crop, 108 - 2 * crop
    clip = ""
    if round_mask:
        defs += f'<clipPath id="mask"><circle cx="{C}" cy="{C}" r="{fmt(span / 2)}"/></clipPath>'
        clip = ' clip-path="url(#mask)"'
    bg = f'  <rect x="0" y="0" width="108" height="108" fill="{background}"/>\n' if background else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{fmt(lo)} {fmt(lo)} {fmt(span)} {fmt(span)}" '
            f'width="{px}" height="{px}">\n<defs>{defs}</defs>\n<g{clip}>\n{bg}{body}</g>\n</svg>\n')


def render_png(svg_text, px, out):
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / "icon.svg"
        src.write_text(svg_text.replace('width="512" height="512"', f'width="{px}" height="{px}"'))
        shot = pathlib.Path(tmp) / "shot.png"
        subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                        "--default-background-color=00000000", f"--window-size={px},{px}",
                        f"--screenshot={shot}", src.as_uri()], check=True, capture_output=True)
        shutil.copy(shot, out)


def main():
    fg = "".join(vd_element(e) for e in elements())
    (RES / "drawable/ic_launcher_foreground.xml").write_text(vector(108, 108, fg))
    # 단색 테마 아이콘·알림 아이콘은 실루엣만 (각인은 단색에서 보이지 않는다)
    (RES / "drawable/ic_launcher_monochrome.xml").write_text(
        vector(108, 108, f'    <path android:fillColor="#FF000000" android:pathData="{coin_path()}" />\n'))
    (RES / "drawable/ic_stat_balance.xml").write_text(
        vector(24, 52, f'    <path android:fillColor="#FFFFFFFF" android:pathData="{coin_path(dx=-28, dy=-28)}" />\n'))

    DESIGN.mkdir(exist_ok=True)
    (DESIGN / "app_icon.svg").write_text(svg())
    store = DESIGN / "app_icon_512.png"
    render_png(svg(crop=18), 512, store)  # 스토어 등록용: 런처에 보이는 72dp 영역, 정사각
    big = DESIGN / ".legacy_round.png"
    render_png(svg(crop=18, round_mask=True, background=IVORY), 512, big)
    img = Image.open(big).convert("RGBA")
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        img.resize((px, px), Image.LANCZOS).save(RES / f"mipmap-{folder}/ic_launcher.png")
    big.unlink()
    print("ok")


if __name__ == "__main__":
    main()
