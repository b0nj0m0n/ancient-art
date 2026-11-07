"""Generates the tileable textures the watercolour look is built from.

    python3 tools/make_textures.py

Writes to art/generated/. Seeded, so the output is the same every run.
- paper.png: rice-paper grain and fibres (greyscale, multiplied over the scene)
- wash_noise.png: three independent soft noises in R, G and B, used for
  pigment granulation, uneven washes and the hand-drawn "boil"
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = "art/generated/"
rng = np.random.default_rng(1584)


def periodic_noise(size: int, falloff: float) -> np.ndarray:
    """Tileable noise: white noise shaped in frequency space (wraps by construction)."""
    white = rng.standard_normal((size, size))
    fy = np.fft.fftfreq(size)[:, None]
    fx = np.fft.fftfreq(size)[None, :]
    f = np.sqrt(fx * fx + fy * fy)
    f[0, 0] = 1.0
    shaped = np.real(np.fft.ifft2(np.fft.fft2(white) / f ** falloff))
    shaped -= shaped.min()
    return shaped / shaped.max()


def paper(size: int = 512) -> Image.Image:
    base = 0.6 * periodic_noise(size, 0.9) + 0.4 * periodic_noise(size, 0.4)
    img = Image.fromarray((215 + base * 40).astype(np.uint8), "L")
    # Fibres: short curved strands, drawn with wrap-around so the tile stays seamless.
    fibres = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(fibres)
    for _ in range(900):
        x, y = rng.uniform(0, size, 2)
        ang = rng.uniform(0, np.pi * 2)
        pts = [(x, y)]
        for _ in range(4):
            ang += rng.uniform(-0.5, 0.5)
            step = rng.uniform(3, 9)
            pts.append((pts[-1][0] + np.cos(ang) * step, pts[-1][1] + np.sin(ang) * step))
        shade = int(rng.uniform(18, 45))
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(px + ox, py + oy) for px, py in pts], fill=shade, width=1)
    fibres = fibres.filter(ImageFilter.GaussianBlur(0.6))
    arr = np.asarray(img, np.int16) - np.asarray(fibres, np.int16) // 2
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "L")


def wash_noise(size: int = 256) -> Image.Image:
    channels = [periodic_noise(size, f) for f in (1.6, 1.1, 2.2)]
    rgb = np.stack([(c * 255).astype(np.uint8) for c in channels], axis=-1)
    return Image.fromarray(rgb, "RGB")


if __name__ == "__main__":
    paper().save(OUT + "paper.png")
    wash_noise().save(OUT + "wash_noise.png")
    print("wrote", OUT + "paper.png", OUT + "wash_noise.png")
