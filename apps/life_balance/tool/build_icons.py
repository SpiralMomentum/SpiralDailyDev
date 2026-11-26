"""앱 아이콘(조금 이지러진 금화) 벡터·래스터 리소스 생성기.

기하: 108dp 적응형 아이콘 캔버스, 중심 (54,54).
- 금화 원판 반지름 R, 오른쪽 위 45도 방향 거리 D에 반지름 r의 원으로 베어낸다.
- 테두리 링은 금화 모양으로 클리핑한 원 스트로크.
실행: python3 tool/build_icons.py  (앱 디렉터리에서)
"""
import math
import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
DESIGN = ROOT / "design"

C = 54.0  # 캔버스 중심
R = 24.0  # 금화 반지름
r = 30.0  # 베어낸 원 반지름 (금화보다 큰 원 → 완만하게 기우는 모양)
D = 46.0  # 중심 간 거리 (침범 깊이 R + r - D = 8)
RIM_INSET = 4.0  # 테두리 링이 금화 외곽에서 들어온 거리
RIM_W = 1.6

IVORY = "#F6F1E7"
INK_DARK = "#1E1B16"
GOLD = "#B08D57"
GOLD_RIM = "#8C6B3C"


def intersections(R=R, r=r):
    ux, uy = math.cos(math.radians(45)), -math.sin(math.radians(45))  # 오른쪽 위 (y 아래 방향 좌표)
    vx, vy = -uy, ux
    a = (R * R - r * r + D * D) / (2 * D)
    h = math.sqrt(R * R - a * a)
    p1 = (C + a * ux - h * vx, C + a * uy - h * vy)
    p2 = (C + a * ux + h * vx, C + a * uy + h * vy)
    bite = (C + D * ux, C + D * uy)
    return p1, p2, bite


def coin_path(dx=0.0, dy=0.0, R=R, r=r):
    p1, p2, _ = intersections(R, r)
    f = lambda p: f"{p[0] + dx:.3f},{p[1] + dy:.3f}"
    # 큰 원은 베인 쪽 반대로 긴 호(large=1, sweep=0), 베인 원은 안쪽 짧은 호(large=0, sweep=1)
    return f"M{f(p1)} A{R:g},{R:g} 0 1,0 {f(p2)} A{r:g},{r:g} 0 0,1 {f(p1)} Z"


def rim_path():
    # 금화 모양을 RIM_INSET만큼 안쪽으로 줄인 윤곽: 큰 원은 R-inset, 베어낸 원은 r+inset
    return coin_path(R=R - RIM_INSET, r=r + RIM_INSET)


def vector(size_dp, viewport, body):
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{size_dp}dp"\n    android:height="{size_dp}dp"\n'
        f'    android:viewportWidth="{viewport}"\n    android:viewportHeight="{viewport}">\n'
        f"{body}</vector>\n"
    )


def foreground_xml():
    path = coin_path()
    body = (
        f'    <path android:fillColor="{GOLD}" android:pathData="{path}" />\n'
        "    <group>\n"
        f'        <clip-path android:pathData="{path}" />\n'
        f'        <path android:strokeColor="{GOLD_RIM}" android:strokeWidth="{RIM_W}"\n'
        f'            android:pathData="{rim_path()}" />\n'
        "    </group>\n"
    )
    return vector(108, 108, body)


def monochrome_xml():
    return vector(108, 108, f'    <path android:fillColor="#FF000000" android:pathData="{coin_path()}" />\n')


def status_xml():
    # 24dp 알림 아이콘: 금화 외곽(30..78)을 52 뷰포트로 잘라 꽉 차게
    path = coin_path(dx=-28, dy=-28)
    return vector(24, 52, f'    <path android:fillColor="#FFFFFFFF" android:pathData="{path}" />\n')


def svg_master():
    path = coin_path()
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" width="512" height="512">\n'
        f'  <rect width="108" height="108" fill="{IVORY}"/>\n'
        f'  <clipPath id="coin"><path d="{path}"/></clipPath>\n'
        f'  <path d="{path}" fill="{GOLD}"/>\n'
        f'  <path d="{rim_path()}" fill="none" stroke="{GOLD_RIM}" stroke-width="{RIM_W}" clip-path="url(#coin)"/>\n'
        "</svg>\n"
    )


def raster(px, background, crop=18.0, round_mask=False):
    """crop: 108 캔버스에서 가장자리를 잘라낼 dp (적응형 아이콘의 보이는 72dp = 18 crop)."""
    ss = 4
    big = px * ss
    span = 108 - 2 * crop
    s = big / span
    t = lambda v: (v - crop) * s
    coin = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(coin)
    d.ellipse([t(C - R), t(C - R), t(C + R), t(C + R)], fill=255)
    _, _, b = intersections()
    d.ellipse([t(b[0] - r), t(b[1] - r), t(b[0] + r), t(b[1] + r)], fill=0)
    def shape(Ro, ro):
        m = Image.new("L", (big, big), 0)
        dm = ImageDraw.Draw(m)
        dm.ellipse([t(C - Ro), t(C - Ro), t(C + Ro), t(C + Ro)], fill=255)
        dm.ellipse([t(b[0] - ro), t(b[1] - ro), t(b[0] + ro), t(b[1] + ro)], fill=0)
        return m
    hw = RIM_W / 2
    outer = shape(R - RIM_INSET + hw, r + RIM_INSET - hw)
    inner = shape(R - RIM_INSET - hw, r + RIM_INSET + hw)
    from PIL import ImageChops
    rim = ImageChops.subtract(outer, inner)
    img = Image.new("RGBA", (big, big), background)
    img.paste(Image.new("RGBA", (big, big), GOLD), (0, 0), coin)
    img.paste(Image.new("RGBA", (big, big), GOLD_RIM), (0, 0), rim)
    if round_mask:
        m = Image.new("L", (big, big), 0)
        ImageDraw.Draw(m).ellipse([0, 0, big - 1, big - 1], fill=255)
        out = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        out.paste(img, (0, 0), m)
        img = out
    return img.resize((px, px), Image.LANCZOS)


def main():
    (RES / "drawable/ic_launcher_foreground.xml").write_text(foreground_xml())
    (RES / "drawable/ic_launcher_monochrome.xml").write_text(monochrome_xml())
    (RES / "drawable/ic_stat_balance.xml").write_text(status_xml())
    DESIGN.mkdir(exist_ok=True)
    (DESIGN / "app_icon.svg").write_text(svg_master())
    # minSdk 26이라 런처는 적응형 아이콘을 쓰지만, 레거시 PNG도 같은 그림으로 맞춘다
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        raster(px, IVORY, round_mask=True).save(RES / f"mipmap-{folder}/ic_launcher.png")
    raster(512, IVORY).save(DESIGN / "app_icon_512.png")  # 스토어 등록용 (정사각, 마스크 없음)
    print("ok", intersections())


if __name__ == "__main__":
    main()
