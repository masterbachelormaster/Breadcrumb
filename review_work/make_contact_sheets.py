from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


parser = argparse.ArgumentParser()
parser.add_argument("input_dir", type=Path)
parser.add_argument("output_dir", type=Path)
args = parser.parse_args()

pages = sorted(
    args.input_dir.glob("page-*.png"),
    key=lambda path: int(path.stem.split("-")[1]),
)
args.output_dir.mkdir(parents=True, exist_ok=True)

for sheet_index, start in enumerate(range(0, len(pages), 4), start=1):
    group = pages[start : start + 4]
    opened = [Image.open(path).convert("RGB") for path in group]
    page_width = max(image.width for image in opened)
    page_height = max(image.height for image in opened)
    label_height = 36
    canvas = Image.new("RGB", (page_width * 2, (page_height + label_height) * 2), "#777777")
    draw = ImageDraw.Draw(canvas)
    for index, (path, image) in enumerate(zip(group, opened, strict=True)):
        column = index % 2
        row = index // 2
        x = column * page_width
        y = row * (page_height + label_height)
        draw.rectangle((x, y, x + page_width, y + label_height), fill="white")
        draw.text((x + 12, y + 10), path.stem, fill="black")
        canvas.paste(image, (x, y + label_height))
    canvas.save(args.output_dir / f"sheet-{sheet_index}.png")
