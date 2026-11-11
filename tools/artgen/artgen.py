"""artgen: build a rig-ready cut-paper figure from a written spec.

Phase 2 of the art pipeline (vector structure). Standard library only.

    python artgen.py specs/ashigaru_spearman.json out_dir

Writes, into out_dir:
    parts/<name>.svg       one file per body part, cropped to that part
    parts/<name>_edge.svg  white silhouette of the part, grown by the cut-paper edge width
    rig.json               parent, pivot, texture origin and draw order per part, plus poses and animations
    preview/assembled.svg  the figure in its rest pose
    preview/sheet.svg      exploded sheet: every part laid out separately (input for the surface pass)
    preview/sheet.json     where each part sits on the sheet
    preview/poses.svg      rest, walk and thrust poses side by side (proves the rig bends)

Coordinates: feet at (0, 0), facing right (+x), up is -y, 10 units = 1 game unit
(the same frame as scripts/view/soldier_figure.gd, ten times larger).
"""
from __future__ import annotations

import json
import math
import os
import sys

# ---------------------------------------------------------------- small SVG helpers


def f(v: float) -> str:
    return f"{v:.1f}".rstrip("0").rstrip(".")


def pts(points) -> str:
    return " ".join(f"{f(x)},{f(y)}" for x, y in points)


class Part:
    """A body part: SVG elements in rest-pose figure coordinates, plus rig data."""

    def __init__(self, name, parent, pivot, z, tint=None, white=None):
        # tint: which game colour multiplies this part at draw time ("side", "mon" or None).
        # white: the fill colour that is written as white in the part file, so the tint can colour it.
        self.name, self.parent, self.pivot, self.z, self.tint, self.white = name, parent, pivot, z, tint, white
        self.items = []  # (svg string, silhouette svg string or None)
        self.box = [1e9, 1e9, -1e9, -1e9]

    def _grow(self, points, pad):
        for x, y in points:
            self.box[0] = min(self.box[0], x - pad)
            self.box[1] = min(self.box[1], y - pad)
            self.box[2] = max(self.box[2], x + pad)
            self.box[3] = max(self.box[3], y + pad)

    def poly(self, points, fill, st, sil=True, close=True, sw=None):
        sw = st["line"] if sw is None else sw
        tag = "polygon" if close else "polyline"
        fill_attr = fill if close else "none"
        self.items.append((
            f'<{tag} points="{pts(points)}" fill="{fill_attr}" stroke="{st["ink"]}" '
            f'stroke-width="{f(sw)}" stroke-linejoin="round" stroke-linecap="round"/>',
            f'<polygon points="{pts(points)}"/>' if (sil and close) else None))
        self._grow(points, sw)

    def path(self, d, bounds, fill, st, sil=True, sw=None):
        sw = st["line"] if sw is None else sw
        self.items.append((
            f'<path d="{d}" fill="{fill}" stroke="{st["ink"]}" stroke-width="{f(sw)}" '
            f'stroke-linejoin="round" stroke-linecap="round"/>',
            f'<path d="{d}"/>' if sil else None))
        self._grow(bounds, sw)

    def circle(self, c, r, fill, st, sil=True, sw=None):
        sw = st["line"] if sw is None else sw
        self.items.append((
            f'<circle cx="{f(c[0])}" cy="{f(c[1])}" r="{f(r)}" fill="{fill}" stroke="{st["ink"]}" stroke-width="{f(sw)}"/>',
            f'<circle cx="{f(c[0])}" cy="{f(c[1])}" r="{f(r)}"/>' if sil else None))
        self._grow([(c[0] - r, c[1] - r), (c[0] + r, c[1] + r)], sw)

    def line(self, a, b, colour, width):
        self.items.append((
            f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke="{colour}" '
            f'stroke-width="{f(width)}" stroke-linecap="round"/>', None))
        self._grow([a, b], width)

    def dot(self, c, r, colour):
        self.items.append((f'<circle cx="{f(c[0])}" cy="{f(c[1])}" r="{f(r)}" fill="{colour}"/>', None))

    def body(self, export=False) -> str:
        out = "".join(i[0] for i in self.items)
        if export and self.white:
            out = out.replace(f'fill="{self.white}"', 'fill="#ffffff"')
        return out

    def silhouette(self) -> str:
        return "".join(i[1] for i in self.items if i[1])


def limb_points(a, b, wa, wb, n=7):
    """Tapered limb from joint a to joint b with rounded ends, as a polygon."""
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    out = []
    for i in range(n + 1):  # cap around a
        t = ang + math.pi / 2 + math.pi * i / n
        out.append((a[0] + math.cos(t) * wa / 2, a[1] + math.sin(t) * wa / 2))
    for i in range(n + 1):  # cap around b
        t = ang - math.pi / 2 + math.pi * i / n
        out.append((b[0] + math.cos(t) * wb / 2, b[1] + math.sin(t) * wb / 2))
    return out


def along(a, b, t, off=0.0):
    """Point a fraction t along a->b, shifted sideways by off."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dy) or 1.0
    return (a[0] + dx * t - dy / ln * off, a[1] + dy * t + dx / ln * off)


def dotted(part, a, b, wa, wb, colour, r=3.6, rows=(0.22, 0.5, 0.78)):
    """Scatter a small repeat motif down a limb (the print convention for patterned cloth)."""
    for i, t in enumerate(rows):
        w = wa + (wb - wa) * t
        for off in ((-0.22, 0.22) if i % 2 == 0 else (0.0,)):
            part.dot(along(a, b, t, off * w), r, colour)


def bands(part, a, b, wa, wb, colour, ts=(0.3, 0.55, 0.8), width=4.0):
    """Cross bands on a limb (lacing on arm and shin guards)."""
    for t in ts:
        w = (wa + (wb - wa) * t) * 0.5 - 3
        part.line(along(a, b, t, -w), along(a, b, t, w), colour, width)


# ---------------------------------------------------------------- template: light infantry


def light_infantry(spec: dict) -> list[Part]:
    """Side-view foot soldier: conical hat, body armour, spear, optional back banner."""
    c = spec["colours"]
    st = {"ink": c["ink"], "line": spec.get("line_width", 6.0)}
    P: list[Part] = []

    # joints (rest pose)
    hip_f, hip_b = (8, -178), (-12, -178)
    knee_f, knee_b = (30, -98), (-34, -100)
    ank_f, ank_b = (22, -22), (-46, -22)
    sh_f, sh_b = (22, -302), (-4, -302)
    el_f, el_b = (52, -246), (28, -242)
    lean = 0.0325  # spear leans forward as it rises
    spear_x = lambda y: 92 + (-y) * lean
    hand_f, hand_b = (spear_x(-262), -262), (spear_x(-218), -218)
    neck = (8, -320)
    waist = (-2, -186)

    def foot(part, ank):
        ax = ank[0]
        part.poly([(ax - 15, -24), (ax + 12, -26), (ax + 46, -9), (ax + 50, -5), (ax - 16, -5)], c["skin"], st)
        part.poly([(ax - 19, -6), (ax + 53, -6), (ax + 53, 0), (ax - 19, 0)], c["straw"], st, sw=3.5)
        part.line((ax + 8, -24), (ax + 26, -6), c["straw"], 4)

    # --- back banner (sashimono): pole, flag (tinted with the side's colour) and crest (tinted with its mon colour)
    if spec.get("banner", True):
        b = Part("banner_pole", "torso", (-34, -236), 0)
        b.poly(limb_points((-34, -222), (-50, -566), 8, 7, 3), c["wood"], st, sw=4)
        P.append(b)
        b = Part("banner_flag", "banner_pole", (-50, -560), 0.1, tint="side", white=c["flag"])
        b.poly([(-158, -562), (-50, -566), (-45, -412), (-153, -408)], c["flag"], st)
        P.append(b)
        b = Part("banner_mon", "banner_flag", (-102, -487), 0.2, tint="mon", white=c["paper"])
        b.circle((-102, -487), 31, c["paper"], st, sw=4)
        b.circle((-102, -487), 14, c["paper"], st, sil=False, sw=5)
        P.append(b)

    # --- back arm
    p = Part("arm_back_upper", "torso", sh_b, 1)
    p.poly(limb_points(sh_b, el_b, 40, 32), c["cloth_dark"], st)
    P.append(p)
    p = Part("arm_back_lower", "arm_back_upper", el_b, 2)
    p.poly(limb_points(el_b, hand_b, 30, 22), c["guard_dark"], st)
    p.circle(hand_b, 13, c["skin_dark"], st)
    P.append(p)

    # --- legs
    for side, hip, knee, ank, z in (("back", hip_b, knee_b, ank_b, 3), ("front", hip_f, knee_f, ank_f, 5)):
        cloth = c["cloth"] if side == "front" else c["cloth_dark"]
        guard = c["guard"] if side == "front" else c["guard_dark"]
        up = Part(f"leg_{side}_upper", "root", hip, z)
        up.poly(limb_points(hip, knee, 50, 38), cloth, st)
        if side == "front":
            dotted(up, hip, knee, 50, 38, c["motif"])
        P.append(up)
        lo = Part(f"leg_{side}_lower", f"leg_{side}_upper", knee, z + 1)
        foot(lo, ank)
        lo.poly(limb_points(knee, ank, 36, 25), guard, st)
        if side == "front":
            bands(lo, knee, ank, 36, 25, c["lacing_b"], ts=(0.25, 0.5, 0.75))
        lo.line(along(knee, ank, 0.06, -15), along(knee, ank, 0.06, 15), c["paper"], 5)  # knee tie
        P.append(lo)

    # --- skirt of armour panels (kusazuri)
    sk = Part("skirt", "root", waist, 7)
    for x0, x1, drop in ((-56, -19, 60), (-19, 20, 66), (20, 60, 58)):
        sk.poly([(x0 * 0.82, -190), (x1 * 0.82, -190), (x1, -190 + drop), (x0, -190 + drop)], c["lacquer"], st)
        for k, col in ((0.45, c["lacing_a"]), (0.78, c["lacing_b"])):
            y = -190 + drop * k
            xa = x0 * (0.82 + 0.18 * k) + 5
            xb = x1 * (0.82 + 0.18 * k) - 5
            sk.line((xa, y), (xb, y), col, 4.5)
    P.append(sk)

    # --- torso: jacket, cuirass (do), sash
    t = Part("torso", "root", waist, 8)
    t.poly([(-24, -324), (-50, -306), (-47, -186), (47, -186), (54, -262), (42, -312), (26, -324)], c["cloth"], st)
    t.poly([(-43, -290), (-42, -198), (44, -198), (51, -262), (38, -294), (10, -300), (-18, -298)], c["lacquer"], st)
    for i, y in enumerate((-276, -256, -236, -216)):
        t.line((-39, y), (43 + (4 if y > -270 else 0), y), c["lacing_a"] if i % 2 == 0 else c["lacing_b"], 4.5)
    t.poly([(-47, -204), (47, -204), (47, -184), (-47, -184)], c["sash"], st)
    t.poly([(30, -204), (44, -204), (50, -168), (34, -166)], c["sash"], st)  # sash knot tail
    t.poly([(-8, -336), (22, -336), (24, -316), (-10, -316)], c["skin"], st, sw=4)  # neck
    t.line((-14, -322), (6, -300), c["paper"], 5)  # collar
    t.line((26, -322), (6, -300), c["paper"], 5)
    P.append(t)

    # --- head
    h = Part("head", "torso", neck, 9)
    h.path("M -27,-368 a 41,45 0 1,0 82,0 a 41,45 0 1,0 -82,0 Z", [(-27, -413), (55, -323)], c["skin"], st)
    h.poly([(53, -374), (66, -360), (52, -353)], c["skin"], st, sw=4)  # nose
    h.poly([(-27, -372), (-24, -340), (-6, -327), (2, -350), (-6, -376)], c["hair"], st, sw=4)  # hair at the nape
    h.line((24, -386), (46, -380), c["ink"], 6)  # heavy brow
    h.line((30, -372), (43, -371), c["ink"], 5)  # eye
    h.line((36, -345), (48, -346), c["ink"], 4)  # mouth
    h.line((4, -398), (26, -326), c["paper"], 4)  # hat cord
    P.append(h)

    # --- conical hat (jingasa)
    hat = Part("hat", "head", (12, -398), 10, tint=None)
    hat.path("M -94,-388 L 12,-456 L 120,-382 Q 14,-364 -94,-388 Z", [(-94, -456), (120, -366)], c["lacquer"], st)
    hat.path("M -88,-389 Q 14,-369 114,-384", [(-88, -389), (114, -369)], "none", {"ink": c["lacing_b"], "line": 4}, sil=False)
    hat.circle((14, -412), 14, c["flag"], st, sil=False, sw=3)
    hat.circle((14, -412), 5, c["paper"], st, sil=False, sw=0)
    P.append(hat)

    # --- spear (yari), carried by the front hand
    sp = Part("spear", "arm_front_lower", hand_f, 11)
    top = (spear_x(-800), -800)
    sp.poly(limb_points((92, -2), top, 11, 9, 3), c["wood"], st, sw=4)
    sp.poly([(top[0] - 8, -798), (top[0] + 3, -886), (top[0] + 9, -798)], c["steel"], st, sw=4)
    sp.poly([(top[0] - 9, -806), (top[0] + 10, -806), (top[0] + 10, -790), (top[0] - 9, -790)], c["lacing_b"], st, sw=3)
    P.append(sp)

    # --- front arm
    p = Part("arm_front_upper", "torso", sh_f, 12)
    p.poly(limb_points(sh_f, el_f, 42, 33), c["cloth"], st)
    dotted(p, sh_f, el_f, 42, 33, c["motif"], rows=(0.3, 0.7))
    P.append(p)
    p = Part("arm_front_lower", "arm_front_upper", el_f, 13)
    p.poly(limb_points(el_f, hand_f, 31, 23), c["guard"], st)
    bands(p, el_f, hand_f, 31, 23, c["lacing_b"], ts=(0.3, 0.6))
    p.circle(hand_f, 14, c["skin"], st)
    P.append(p)
    return P


TEMPLATES = {"light_infantry": light_infantry}

# Rotation in degrees per part, clockwise on screen, relative to the rest pose.
# "root" turns the whole figure about its feet; "root_x" / "root_y" then shift it (figure units).
POSES = {
    "rest": {},
    "walk_a": {"torso": 3, "leg_front_upper": -24, "leg_front_lower": 12, "leg_back_upper": 16, "leg_back_lower": 16,
               "arm_front_upper": 6, "arm_back_upper": -4},
    "walk_b": {"torso": 3, "leg_front_upper": 20, "leg_front_lower": 22, "leg_back_upper": -24, "leg_back_lower": 8,
               "arm_front_upper": -4, "arm_back_upper": 6},
    "ready": {"torso": 8, "leg_front_upper": -18, "leg_front_lower": 16, "leg_back_upper": 14, "leg_back_lower": 10,
              "arm_front_upper": -30, "arm_front_lower": -30, "spear": 122, "arm_back_upper": -22, "arm_back_lower": -20},
    "thrust": {"torso": 14, "head": -8, "leg_front_upper": -34, "leg_front_lower": 30, "leg_back_upper": 22,
               "leg_back_lower": 6, "arm_front_upper": -52, "arm_front_lower": -24, "spear": 142,
               "arm_back_upper": -40, "arm_back_lower": -26, "banner_pole": -6},
    "recoil": {"torso": -12, "head": 12, "leg_front_upper": 12, "leg_front_lower": 8, "leg_back_upper": -6,
               "leg_back_lower": 14, "arm_front_upper": 14, "arm_front_lower": -20, "spear": -6,
               "arm_back_upper": 20, "banner_pole": 8},
    "down": {"root": 84, "root_y": -48, "head": 10, "leg_front_upper": 14, "leg_back_upper": -10,
             "arm_front_upper": -20, "arm_front_lower": -10, "spear": 30, "arm_back_upper": -30, "banner_pole": -20},
}

# Each step is [pose, seconds]: over that time the figure moves from this pose to the next one, looping.
ANIMATIONS = {
    "idle": [["rest", 1.0]],
    "walk": [["walk_a", 0.32], ["walk_b", 0.32]],
    "attack": [["ready", 0.35], ["thrust", 0.12], ["thrust", 0.1], ["ready", 0.3]],
    "demo": [["rest", 1.2], ["rest", 0.3], ["walk_a", 0.32], ["walk_b", 0.32], ["walk_a", 0.32], ["walk_b", 0.32],
             ["walk_a", 0.3], ["rest", 0.5], ["rest", 0.3], ["ready", 0.6], ["ready", 0.12], ["thrust", 0.2],
             ["thrust", 0.25], ["ready", 0.3], ["ready", 0.12], ["thrust", 0.2], ["thrust", 0.3], ["ready", 0.2],
             ["recoil", 0.5], ["recoil", 0.4], ["down", 1.4], ["down", 0.5]],
}

# ---------------------------------------------------------------- posing and output


def mat_mul(a, b):
    return (a[0] * b[0] + a[2] * b[1], a[1] * b[0] + a[3] * b[1], a[0] * b[2] + a[2] * b[3], a[1] * b[2] + a[3] * b[3],
            a[0] * b[4] + a[2] * b[5] + a[4], a[1] * b[4] + a[3] * b[5] + a[5])


def rot_about(p, deg):
    r = math.radians(deg)
    cs, sn = math.cos(r), math.sin(r)
    return (cs, sn, -sn, cs, p[0] - cs * p[0] + sn * p[1], p[1] - sn * p[0] - cs * p[1])


def world(parts, pose):
    by = {p.name: p for p in parts}
    r = rot_about((0, 0), pose.get("root", 0))
    cache = {"root": (r[0], r[1], r[2], r[3], r[4] + pose.get("root_x", 0), r[5] + pose.get("root_y", 0))}

    def get(name):
        if name not in cache:
            p = by[name]
            cache[name] = mat_mul(get(p.parent), rot_about(p.pivot, pose.get(name, 0)))
        return cache[name]
    return {p.name: get(p.name) for p in parts}


def figure_svg(parts, pose, st, edge=7.0, shadow=(14, 18)) -> str:
    """One posed figure: soft shadow, pale cut-paper edge round the whole silhouette, then the parts."""
    m = world(parts, pose)
    order = sorted(parts, key=lambda p: p.z)
    tf = lambda p: 'transform="matrix(%s)"' % ",".join(f"{v:.5f}" for v in m[p.name])
    sil = "".join(f"<g {tf(p)}>{p.silhouette()}</g>" for p in order)
    out = [f'<g opacity="0.18" transform="translate({shadow[0]},{shadow[1]})" fill="{st["shadow"]}" stroke="{st["shadow"]}" '
           f'stroke-width="{f(edge * 2)}" stroke-linejoin="round">{sil}</g>',
           f'<g fill="{st["edge"]}" stroke="{st["edge"]}" stroke-width="{f(edge * 2 + st["line"])}" stroke-linejoin="round">{sil}</g>']
    out += [f"<g {tf(p)}>{p.body()}</g>" for p in order]
    return "".join(out)


def svg_doc(inner, box, bg=None) -> str:
    x0, y0, x1, y1 = box
    rect = f'<rect x="{f(x0)}" y="{f(y0)}" width="{f(x1 - x0)}" height="{f(y1 - y0)}" fill="{bg}"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{f(x0)} {f(y0)} {f(x1 - x0)} {f(y1 - y0)}" '
            f'width="{f(x1 - x0)}" height="{f(y1 - y0)}">{rect}{inner}</svg>\n')


def build(spec: dict, out: str) -> dict:
    parts = TEMPLATES[spec["template"]](spec)
    c = spec["colours"]
    st = {"ink": c["ink"], "line": spec.get("line_width", 6.0), "edge": c["cut_edge"], "shadow": c["ink"]}
    os.makedirs(os.path.join(out, "parts"), exist_ok=True)
    edge = spec.get("cut_edge_width", 12.0)  # pale paper border round the silhouette, in figure units
    rig = {"unit": spec["name"], "template": spec["template"], "units_per_game_unit": 10, "facing": "right",
           "cut_edge_width": edge, "parts": [], "poses": POSES, "animations": ANIMATIONS}
    for p in sorted(parts, key=lambda q: q.z):
        # one box for both files, padded so the cut edge fits
        box = [math.floor(p.box[0] - edge), math.floor(p.box[1] - edge), math.ceil(p.box[2] + edge), math.ceil(p.box[3] + edge)]
        with open(os.path.join(out, "parts", p.name + ".svg"), "w", encoding="utf-8") as fh:
            fh.write(svg_doc(p.body(export=True), box))
        # white silhouette grown by the edge width: drawn under the part as the cut-paper border and as its shadow
        sil = (f'<g fill="#ffffff" stroke="#ffffff" stroke-width="{f(edge * 2 + st["line"])}" '
               f'stroke-linejoin="round">{p.silhouette()}</g>')
        with open(os.path.join(out, "parts", p.name + "_edge.svg"), "w", encoding="utf-8") as fh:
            fh.write(svg_doc(sil, box))
        rig["parts"].append({"name": p.name, "parent": p.parent, "z": p.z, "pivot": list(p.pivot),
                             "texture": f"parts/{p.name}.svg", "edge_texture": f"parts/{p.name}_edge.svg",
                             "texture_origin": box[:2], "size": [box[2] - box[0], box[3] - box[1]], "tint": p.tint})
    with open(os.path.join(out, "rig.json"), "w", encoding="utf-8") as fh:
        json.dump(rig, fh, indent=1)

    prev = os.path.join(out, "preview")
    os.makedirs(prev, exist_ok=True)
    open(os.path.join(prev, ".gdignore"), "w").close()  # keeps Godot from importing or exporting previews
    full = (-200, -920, 220, 40)
    with open(os.path.join(prev, "assembled.svg"), "w", encoding="utf-8") as fh:
        fh.write(svg_doc(figure_svg(parts, {}, st), full, c["paper_ground"]))

    # poses side by side
    step, inner = 560, []
    names = list(POSES)
    for i, n in enumerate(names):
        inner.append(f'<g transform="translate({i * step},0)">{figure_svg(parts, POSES[n], st)}</g>')
    with open(os.path.join(prev, "poses.svg"), "w", encoding="utf-8") as fh:
        fh.write(svg_doc("".join(inner), (-420, -920, step * (len(names) - 1) + 640, 60), c["paper_ground"]))

    # exploded sheet: tall parts (spear, banner) in a left strip, the rest shelf-packed beside them
    gap, inner, cells = 24, [], []
    def place(p, x, y):
        inner.append(f'<g transform="translate({f(x - p.box[0])},{f(y - p.box[1])})">{p.body()}</g>')
        cells.append({"name": p.name, "x": round(x, 1), "y": round(y, 1),
                      "w": round(p.box[2] - p.box[0], 1), "h": round(p.box[3] - p.box[1], 1)})
    size = lambda p: (p.box[2] - p.box[0], p.box[3] - p.box[1])
    tall = [p for p in parts if size(p)[1] > 400]
    rest = sorted((p for p in parts if size(p)[1] <= 400), key=lambda q: -size(q)[1])
    x = 0
    for p in tall:
        place(p, x, 0)
        x += size(p)[0] + gap
    left, max_w = x, x + 760
    y, row_h = 0, 0
    for p in rest:
        w, h = size(p)
        if x + w > max_w and x > left:
            x, y, row_h = left, y + row_h + gap, 0
        place(p, x, y)
        x, row_h = x + w + gap, max(row_h, h)
    sheet_h = max([y + row_h] + [size(p)[1] for p in tall])
    sheet_box = (-gap, -gap, max_w + gap, sheet_h + gap)
    with open(os.path.join(prev, "sheet.svg"), "w", encoding="utf-8") as fh:
        fh.write(svg_doc("".join(inner), sheet_box, c["paper_ground"]))
    with open(os.path.join(prev, "sheet.json"), "w", encoding="utf-8") as fh:
        json.dump({"box": sheet_box, "cells": cells}, fh, indent=1)
    return rig


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    with open(sys.argv[1], encoding="utf-8") as fh:
        rig = build(json.load(fh), sys.argv[2])
    print(f"{rig['unit']}: {len(rig['parts'])} parts written to {sys.argv[2]}")
