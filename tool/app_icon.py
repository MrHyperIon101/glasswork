#!/usr/bin/env python3
"""Makes every platform's app icon from one source image.

The source, assets/branding/app_icon_source.png, is the icon as drawn: a purple rounded
square on a pale background. The app's icon is a disc cut from inside that square, and
every platform gets the same disc, sized for how that platform lays icons out.

After changing the source, run this and commit what it writes:

    python3 tool/app_icon.py

Needs Pillow. The PNGs it writes are outputs: change the source, never them.
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/branding/app_icon_source.png"
MASTER = ROOT / "assets/branding/app_icon.png"
APP_ID = "dev.mrhyperion.glasswork"

MASTER_SIZE = 1024

# A pixel belongs to the square when it is at least this saturated, out of 255. The pale
# background, the soft shadow under the square and the white check are all far below it.
SQUARE_SATURATION = 110

# How far inside the square's edge the disc is cut, as a fraction of its half-width. Keeps
# the rim clear of the square's anti-aliased edge, so no background shows around it.
EDGE_CLEARANCE = 0.02

ANDROID_RES = ROOT / "android/app/src/main/res"
ANDROID_DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

LINUX_ICONS = ROOT / "linux/packaging/icons"
LINUX_SIZES = (16, 24, 32, 48, 64, 128, 256, 512)


def find_square(image):
    """The square's centre and half-width, in source pixels."""
    saturation = image.convert("RGB").convert("HSV").getchannel("S")
    box = saturation.point(lambda s: 255 if s >= SQUARE_SATURATION else 0).getbbox()
    if box is None:
        raise SystemExit(f"found no saturated square in {SOURCE}")
    left, top, right, bottom = box
    return (left + right) / 2, (top + bottom) / 2, min(right - left, bottom - top) / 2


def circle_mask(size, supersample=4):
    """An anti-aliased disc filling a size-pixel square: drawn large, then scaled down."""
    large = size * supersample
    mask = Image.new("L", (large, large), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, large - 1, large - 1), fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def make_master(source):
    """The disc, MASTER_SIZE pixels across, transparent outside it."""
    cx, cy, half = find_square(source)
    radius = half * (1 - EDGE_CLEARANCE)
    disc = source.convert("RGBA").resize(
        (MASTER_SIZE, MASTER_SIZE),
        Image.LANCZOS,
        box=(cx - radius, cy - radius, cx + radius, cy + radius),
    )
    disc.putalpha(ImageChops.multiply(disc.getchannel("A"), circle_mask(MASTER_SIZE)))
    return disc


def placed(master, canvas, diameter):
    """The disc at `diameter` pixels, centred on a transparent `canvas`-pixel square."""
    if (canvas - diameter) % 2:
        raise ValueError(f"a {diameter}px disc cannot sit centred on a {canvas}px canvas")
    offset = (canvas - diameter) // 2
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.alpha_composite(master.resize((diameter, diameter), Image.LANCZOS), (offset, offset))
    return out


def write(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def android(master):
    for density, scale in ANDROID_DENSITIES.items():
        folder = ANDROID_RES / f"mipmap-{density}"

        # Android 7: the icon as it is shown, a 44dp disc on the 48dp icon grid.
        legacy = placed(master, round(48 * scale), round(44 * scale))
        write(legacy, folder / "ic_launcher.png")
        write(legacy, folder / "ic_launcher_round.png")

        # Android 8 onwards: an adaptive icon's foreground. Launchers mask its 108dp layer
        # down to the middle 72dp, whatever shape they mask to, and the disc fills that.
        write(
            placed(master, round(108 * scale), round(72 * scale)),
            folder / "ic_launcher_foreground.png",
        )


def linux(master):
    for size in LINUX_SIZES:
        margin = max(1, round(size / 16))
        write(
            placed(master, size, size - 2 * margin),
            LINUX_ICONS / f"{size}x{size}" / "apps" / f"{APP_ID}.png",
        )


def main():
    master = make_master(Image.open(SOURCE))
    write(master, MASTER)
    android(master)
    linux(master)
    print(f"wrote {MASTER.relative_to(ROOT)}, the Android mipmaps and the Linux icons")


if __name__ == "__main__":
    main()
