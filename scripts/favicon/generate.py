#!/usr/bin/env python3
"""Genera il kit favicon per costigiola.bitprepared.it.

Design: cipresso stilizzato monocromatico su tile arrotondato.
Due varianti: tile nero con albero bianco (quella del sito, scritta in
assets/img/favicon/) e tile bianco con albero nero (inverted/, qui accanto
allo script). Il profilo della chioma e' generato da un'unica funzione
di larghezza, riusata sia per il rendering PNG (Pillow) che per l'SVG,
cosi' i due restano coerenti.
"""
import json
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))
# la variante del sito va dritta negli asset: metalsmith-assets copia
# assets/ nella root della build, quindi img/favicon/ arriva in build
SITE = os.path.abspath(os.path.join(OUT, '..', '..', 'assets', 'img', 'favicon'))
S = 2048                              # dimensione master
INK = (17, 17, 17, 255)               # #111111, usato sia come "nero" che come albero
PAPER = (255, 255, 255, 255)

VARIANTS = [                          # (sottocartella, tile, albero, hex tema, destinazione)
    ("", INK, PAPER, "#111111", SITE),
    ("inverted", PAPER, INK, "#ffffff", OUT),
]


def half_width(t, w_max):
    """Larghezza della chioma a quota normalizzata t in [0,1].
    Picco verso il basso (t~0.61), punta acuta in alto: sagoma da cipresso."""
    v = (t ** 1.35) * ((1 - t) ** 0.85)
    return w_max * v / ((0.607 ** 1.35) * ((1 - 0.607) ** 0.85))


def canopy_points(cx, y_top, y_bot, w_max, steps=240):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        y = y_top + t * (y_bot - y_top)
        hw = half_width(t, w_max)
        pts.append((cx + hw, y))
    for i in range(steps + 1):
        t = 1 - i / steps
        y = y_top + t * (y_bot - y_top)
        hw = half_width(t, w_max)
        pts.append((cx - hw, y))
    return pts


def draw_tree(d, s, fg):
    """Disegna cipresso (chioma, tronco, linea di terra) centrato su canvas s."""
    cx = s / 2
    y_top, y_bot = s * 0.17, s * 0.72          # chioma snella, saglia bassa
    d.polygon(canopy_points(cx, y_top, y_bot, s * 0.10), fill=fg)
    tw = s * 0.028                              # tronco
    d.rounded_rectangle([cx - tw / 2, y_bot - s * 0.02, cx + tw / 2, s * 0.815],
                        radius=tw / 2, fill=fg)
    gw = s * 0.085                              # linea di terra
    d.rounded_rectangle([cx - gw, s * 0.815, cx + gw, s * 0.836],
                        radius=s * 0.010, fill=fg)


def draw_tile(canvas_size, bg, fg, rounded=True):
    """Tile con angoli arrotondati (o pieno, per Apple) e cipresso sopra."""
    s = canvas_size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        m = round(s * 0.03)
        d.rounded_rectangle([m, m, s - m, s - m], radius=round(s * 0.21), fill=bg)
    else:
        d.rectangle([0, 0, s - 1, s - 1], fill=bg)
    draw_tree(d, s, fg)
    return img


def svg(bg_hex, fg_hex):
    """Stesso identico disegno in forma vettoriale, viewBox 512."""
    vb = 512
    m = vb * 0.03
    r = vb * 0.21
    cx = vb / 2
    y_top, y_bot = vb * 0.17, vb * 0.72

    right, left = [], []
    steps = 60
    for i in range(steps + 1):
        t = i / steps
        y = y_top + t * (y_bot - y_top)
        hw = half_width(t, vb * 0.10)
        right.append((cx + hw, y))
        left.append((cx - hw, y))

    def fmt(p):
        return f"{p[0]:.1f},{p[1]:.1f}"

    path = "M" + " L".join(fmt(p) for p in right) \
           + " L" + " L".join(fmt(p) for p in reversed(left)) + " Z"

    tw = vb * 0.028
    gw = vb * 0.085
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vb} {vb}">
  <rect x="{m:.1f}" y="{m:.1f}" width="{vb - 2*m:.1f}" height="{vb - 2*m:.1f}"
        rx="{r:.1f}" fill="{bg_hex}"/>
  <path d="{path}" fill="{fg_hex}"/>
  <rect x="{cx - tw/2:.1f}" y="{y_bot - vb*0.02:.1f}" width="{tw:.1f}"
        height="{vb*0.815 - y_bot + vb*0.02:.1f}" rx="{tw/2:.1f}" fill="{fg_hex}"/>
  <rect x="{cx - gw:.1f}" y="{vb*0.815:.1f}" width="{gw*2:.1f}" height="{vb*0.021:.1f}"
        rx="{vb*0.010:.1f}" fill="{fg_hex}"/>
</svg>
'''


def build_variant(subdir, bg, fg, theme_hex, base):
    """Genera ICO + PNG + SVG + manifest di una variante nella sua cartella."""
    vd = os.path.join(base, subdir) if subdir else base
    os.makedirs(vd, exist_ok=True)

    master = draw_tile(S, bg, fg)
    apple = draw_tile(S, bg, fg, rounded=False)

    for name, size in [
        ("android-chrome-512x512.png", 512),
        ("android-chrome-192x192.png", 192),
        ("apple-touch-icon.png", 180),      # iOS arrotonda da solo: tile pieno
        ("favicon-32x32.png", 32),
        ("favicon-16x16.png", 16),
    ]:
        src = apple if name.startswith("apple") else master
        src.resize((size, size), Image.LANCZOS).save(os.path.join(vd, name))

    # ICO multirisoluzione (pre-dimensionate, cosi' il resample e' sempre LANCZOS)
    ico_frames = [master.resize((n, n), Image.LANCZOS) for n in (48, 32, 16)]
    ico_frames[0].save(os.path.join(vd, "favicon.ico"), format="ICO",
                       append_images=ico_frames[1:], sizes=[(48, 48), (32, 32), (16, 16)])

    with open(os.path.join(vd, "favicon.svg"), "w") as f:
        f.write(svg("#%02x%02x%02x" % bg[:3], "#%02x%02x%02x" % fg[:3]))

    prefix = "" if not subdir else "/" + subdir + "/"
    manifest = {
        "name": "Costigiola",
        "short_name": "Costigiola",
        "icons": [
            {"src": prefix + "android-chrome-192x192.png", "sizes": "192x192", "type": "image/png"},
            {"src": prefix + "android-chrome-512x512.png", "sizes": "512x512", "type": "image/png"},
        ],
        "theme_color": theme_hex,
        "background_color": theme_hex,
        "display": "standalone",
    }
    with open(os.path.join(vd, "site.webmanifest"), "w") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    return master


masters = {}
for subdir, bg, fg, theme_hex, base in VARIANTS:
    masters[subdir or "dark"] = build_variant(subdir, bg, fg, theme_hex, base)

# --- Variante trasparente (albero nero, per intestazioni chiare) ---
inv = Image.new("RGBA", (S, S), (0, 0, 0, 0))
draw_tree(ImageDraw.Draw(inv), S, INK)
inv.resize((512, 512), Image.LANCZOS).save(os.path.join(SITE, "icon-black-transparent.png"))

# --- Anteprima: variante nera su sfondo chiaro | variante bianca su sfondo scuro,
#     con ingrandimenti 4x di 64/32/16 px pixel-per-pixel ---
pw, ph = 1240, 800
prev = Image.new("RGB", (pw, ph), (245, 245, 245))
dd = ImageDraw.Draw(prev)
half = pw // 2
dd.rectangle([half, 0, pw, ph], fill=(24, 24, 24))
panels = [(0, masters["dark"]), (half, masters["inverted"])]
for hx, master in panels:
    big = master.resize((360, 360), Image.LANCZOS)
    prev.paste(big, (hx + half // 2 - 180, 40), big)
    zooms = [(n, master.resize((n, n), Image.LANCZOS).resize((n * 4, n * 4), Image.NEAREST))
             for n in (64, 32, 16)]
    row_w = sum(n * 4 for n, _ in zooms) + 60 * (len(zooms) - 1)
    x = hx + (half - row_w) // 2
    for n, zoom in zooms:
        w = n * 4
        y = 620 - w // 2
        dd.rounded_rectangle([x - 14, y - 14, x + w + 13, y + w + 13], radius=8,
                             fill=(228, 228, 228) if hx == 0 else (44, 44, 44))
        prev.paste(zoom, (x, y), zoom)
        x += w + 60
prev.save(os.path.join(OUT, "preview.png"))

print("Generato in", OUT)
for root, dirs, files in os.walk(OUT):
    dirs.sort()
    for fn in sorted(files):
        p = os.path.join(root, fn)
        print(f"  {os.path.relpath(p, OUT):44s} {os.path.getsize(p):>7d} B")
