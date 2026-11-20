"""카드 이미지의 3D 원근 변환 (순수 함수 + PIL 변환).

카드를 평면으로 보고 yaw(세로축 회전), pitch(가로축 회전), roll(면 안 회전)을 준 뒤
카메라 거리 D 의 원근 투영으로 네 모서리를 옮긴다. 그 네 점으로 PIL PERSPECTIVE 계수를 풀어 변환한다.
Apple 베젤 에셋은 쓰지 않는다 (generic 카드만 변환).
"""
from __future__ import annotations

import math
from typing import Sequence

from PIL import Image

Point = tuple[float, float]

# 카메라 거리 = 카드 긴 변 x 이 값. 작을수록 원근이 강하다 (우리 설정, 관측 근거 없음).
CAMERA_FACTOR = 1.8
SUPERSAMPLE = 2


def rotation(yaw_deg: float, pitch_deg: float, roll_deg: float) -> list[list[float]]:
    """R = Rx(pitch) @ Ry(yaw) @ Rz(roll). 각도는 도."""
    y, p, r = (math.radians(a) for a in (yaw_deg, pitch_deg, roll_deg))
    rz = [[math.cos(r), -math.sin(r), 0], [math.sin(r), math.cos(r), 0], [0, 0, 1]]
    ry = [[math.cos(y), 0, math.sin(y)], [0, 1, 0], [-math.sin(y), 0, math.cos(y)]]
    rx = [[1, 0, 0], [0, math.cos(p), -math.sin(p)], [0, math.sin(p), math.cos(p)]]
    mul = lambda a, b: [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]  # noqa: E731
    return mul(rx, mul(ry, rz))


def project_corners(w: float, h: float, yaw: float, pitch: float, roll: float,
                    camera_factor: float = CAMERA_FACTOR) -> list[Point]:
    """카드 네 모서리(좌상, 우상, 우하, 좌하)를 회전·투영한 좌표 (카드 중심이 원점)."""
    dist = camera_factor * max(w, h)
    rot = rotation(yaw, pitch, roll)
    pts = []
    for x, y in ((-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)):
        vx, vy, vz = (rot[i][0] * x + rot[i][1] * y for i in range(3))  # z 입력은 0
        scale = dist / (dist - vz)                                        # vz > 0 이면 카메라 쪽, 커 보임
        pts.append((vx * scale, vy * scale))
    return pts


def solve_linear(a: list[list[float]], b: list[float]) -> list[float]:
    """가우스 소거법 (8x8 정도의 작은 계). 특이하면 ValueError."""
    n = len(b)
    m = [row[:] + [b[i]] for i, row in enumerate(a)]
    for col in range(n):
        pivot = max(range(col, n), key=lambda r: abs(m[r][col]))
        if abs(m[pivot][col]) < 1e-12:
            raise ValueError("원근 변환 계수를 풀 수 없다 (모서리가 일직선)")
        m[col], m[pivot] = m[pivot], m[col]
        for r in range(n):
            if r != col:
                f = m[r][col] / m[col][col]
                m[r] = [x - f * y for x, y in zip(m[r], m[col])]
    return [m[i][n] / m[i][i] for i in range(n)]


def perspective_coeffs(dst: Sequence[Point], src: Sequence[Point]) -> list[float]:
    """PIL Image.transform(PERSPECTIVE) 계수: 출력 좌표 dst 한 점마다 입력 좌표 src 를 찾는다."""
    a, b = [], []
    for (x, y), (sx, sy) in zip(dst, src):
        a.append([x, y, 1, 0, 0, 0, -sx * x, -sx * y]); b.append(sx)
        a.append([0, 0, 0, x, y, 1, -sy * x, -sy * y]); b.append(sy)
    return solve_linear(a, b)


def warp_card(card: Image.Image, yaw: float, pitch: float, roll: float) -> tuple[Image.Image, tuple[float, float]]:
    """RGBA 카드를 3D 자세로 변환. (결과 RGBA, 카드 중심이 결과 이미지 안에서 놓인 좌표)를 돌려준다."""
    ss = SUPERSAMPLE
    big = card.resize((card.width * ss, card.height * ss), Image.LANCZOS)
    pts = project_corners(big.width, big.height, yaw, pitch, roll)
    min_x, min_y = min(p[0] for p in pts), min(p[1] for p in pts)
    dst = [(x - min_x, y - min_y) for x, y in pts]
    out_w, out_h = math.ceil(max(p[0] for p in dst)), math.ceil(max(p[1] for p in dst))
    src = [(0, 0), (big.width, 0), (big.width, big.height), (0, big.height)]
    warped = big.transform((out_w, out_h), Image.PERSPECTIVE, perspective_coeffs(dst, src), Image.BICUBIC)
    small = warped.resize((max(1, out_w // ss), max(1, out_h // ss)), Image.LANCZOS)
    return small, (-min_x / ss, -min_y / ss)
