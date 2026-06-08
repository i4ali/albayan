#!/usr/bin/env python3
"""
Composite a real simulator screenshot into a Nano-Banana-generated chrome
image whose iPad screen region was rendered as a flat magenta key colour.

Detects the magenta region, builds a soft mask (preserves rounded corners),
fits the source screenshot to its bounding box, and pastes through the mask.
"""

import argparse
from pathlib import Path
from PIL import Image, ImageFilter


KEY_RGB = (255, 0, 255)  # pure magenta
TOLERANCE = 60           # per-channel tolerance for "magenta-ish" pixels


def build_key_mask(img: Image.Image) -> Image.Image:
    """Return an L-mode mask where 255 = key colour, 0 = not."""
    rgb = img.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    kr, kg, kb = KEY_RGB
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if (
                abs(r - kr) <= TOLERANCE
                and abs(g - kg) <= TOLERANCE
                and abs(b - kb) <= TOLERANCE
                and r > 150
                and b > 150
                and g < 120
            ):
                mp[x, y] = 255
    return mask


def bbox_of_mask(mask: Image.Image) -> tuple[int, int, int, int]:
    bbox = mask.getbbox()
    if bbox is None:
        raise SystemExit("No magenta key region found in chrome image")
    return bbox


def fit_source_to_bbox(
    source: Image.Image,
    bbox: tuple[int, int, int, int],
    vertical_anchor: str = "top",
) -> Image.Image:
    """Scale source to match the bbox aspect ratio (cover), then crop to bbox size.

    vertical_anchor: "top" preserves the top of the source (status bar / nav)
    and crops the bottom; "center" center-crops.
    """
    bx0, by0, bx1, by1 = bbox
    bw, bh = bx1 - bx0, by1 - by0
    sw, sh = source.size
    src_aspect = sw / sh
    box_aspect = bw / bh

    if src_aspect > box_aspect:
        # source is wider than bbox aspect — fit by height, crop sides
        new_h = bh
        new_w = round(bh * src_aspect)
    else:
        # source is taller than bbox aspect — fit by width, crop top/bottom
        new_w = bw
        new_h = round(bw / src_aspect)

    resized = source.resize((new_w, new_h), Image.LANCZOS)
    left = (new_w - bw) // 2
    if vertical_anchor == "top":
        top = 0
    else:
        top = (new_h - bh) // 2
    return resized.crop((left, top, left + bw, top + bh))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--chrome", required=True, help="Nano Banana output with magenta-key screen")
    ap.add_argument("--source", required=True, help="Real simulator screenshot")
    ap.add_argument("--output", required=True, help="Composited output path")
    ap.add_argument("--debug-mask", help="Optional path to dump the detected mask")
    args = ap.parse_args()

    chrome = Image.open(args.chrome).convert("RGBA")
    source = Image.open(args.source).convert("RGBA")

    mask = build_key_mask(chrome)
    if args.debug_mask:
        mask.save(args.debug_mask)

    bbox = bbox_of_mask(mask)
    print(f"key bbox: {bbox} (size {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]})")

    fitted = fit_source_to_bbox(source, bbox)

    # Soften mask edges very slightly so paste doesn't show a hard 1px seam
    soft_mask = mask.crop(bbox).filter(ImageFilter.GaussianBlur(0.6))

    out = chrome.copy()
    out.paste(fitted, (bbox[0], bbox[1]), soft_mask)
    out.convert("RGB").save(args.output)
    print(f"saved: {args.output}")


if __name__ == "__main__":
    main()
