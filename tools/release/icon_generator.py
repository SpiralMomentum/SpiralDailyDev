from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from PIL import Image, ImageDraw, ImageFont


@dataclass
class IconSpec:
    output: Path
    background_color: str
    label: str
    label_color: str = "#FFFFFF"
    font_size: int = 360
    template: Optional[Path] = None


def _parse_color(value: str) -> tuple[int, int, int, int]:
    value = value.strip().lstrip("#")
    if len(value) == 6:
        value += "FF"
    if len(value) != 8:
        raise ValueError(f"Unsupported color format: {value}")
    r = int(value[0:2], 16)
    g = int(value[2:4], 16)
    b = int(value[4:6], 16)
    a = int(value[6:8], 16)
    return (r, g, b, a)


def generate_icon(spec: IconSpec) -> Path:
    """Generate a square PNG icon following the provided specification."""
    size = 1024
    canvas = Image.new("RGBA", (size, size), _parse_color(spec.background_color))
    draw = ImageDraw.Draw(canvas)

    if spec.template:
        template_path = Path(spec.template)
        if template_path.exists():
            template = Image.open(template_path).convert("RGBA").resize((size, size))
            canvas.alpha_composite(template)

    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", spec.font_size)
    except Exception:
        font = ImageFont.load_default()

    text = spec.label.strip()
    if text:
        text_bbox = draw.textbbox((0, 0), text, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]
        x = (size - text_width) / 2
        y = (size - text_height) / 2
        draw.text((x, y), text, font=font, fill=_parse_color(spec.label_color))

    spec.output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(spec.output, format="PNG")
    return spec.output


__all__ = ["IconSpec", "generate_icon"]
