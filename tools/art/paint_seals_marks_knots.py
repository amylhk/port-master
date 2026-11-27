"""Paint the cargo inspection sprites with Pillow; optionally make a contact sheet."""

import argparse
import math
from pathlib import Path
import random

from PIL import Image, ImageChops, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
S = 4
INK = "#2A1E17"
MARKS = {
    "lim_seng": "#8A8377",
    "khoja_ismail": "#9A6046",
    "sri_rangan": "#A27D58",
    "ki_jaya": "#987558",
    "encik_hamzah": "#AD5D47",
    "ong_kuan_ship": "#A8896B",
    "dawud_ship": "#8A8377",
    "khoja_ismail_forged": "#74503C",
    "": "#9C7A5B",
}
STATES = ("intact", "weathered", "tampered", "broken")
KNOTS = ("square", "lashing", "double_loop", "single_loop", "blue_thread_tie", "frayed_retie")


def rgb(color):
    return tuple(bytes.fromhex(color.lstrip("#")))


def tone(color, amount):
    return tuple(max(0, min(255, round(value + amount))) for value in color)


def xy(point):
    return tuple(round(value * S) for value in point)


def canvas(size, mode="RGBA"):
    return Image.new(mode, (size * S, size * S))


def stroke(draw, points, color, width):
    if len(points) < 2:
        return
    draw.line([xy(p) for p in points], fill=color, width=round(width * S), joint="curve")
    for x, y in (points[0], points[-1]):
        dot(draw, x, y, width / 2, color)


def dot(draw, x, y, r, color):
    draw.ellipse((*xy((x-r, y-r)), *xy((x+r, y+r))), fill=color)


def curve(points):
    padded = [points[0], *points, points[-1]]
    out = [points[0]]
    for a, b, c, d in zip(padded, padded[1:], padded[2:], padded[3:]):
        steps = max(6, int(math.dist(b, c) * 1.3))
        for step in range(1, steps + 1):
            t = step / steps
            out.append(tuple(
                0.5 * (2*j + (k-i)*t + (2*i-5*j+4*k-l)*t*t + (-i+3*j-3*k+l)*t**3)
                for i, j, k, l in zip(a, b, c, d)
            ))
    return out


def motif(image, name, size, color, dx=0, dy=0, width=1):
    draw = ImageDraw.Draw(image)
    unit = size / 64

    def path(points, weight=3.7, smooth=False):
        points = curve(points) if smooth else points
        stroke(draw, [(x*unit+dx, y*unit+dy) for x, y in points], color, weight*unit*width)

    def spot(x, y, r):
        dot(draw, x*unit+dx, y*unit+dy, r*unit*width, color)

    def shape(points):
        draw.polygon([xy((x*unit+dx, y*unit+dy)) for x, y in points], fill=color)

    if name == "lim_seng":
        path([(32, 13), (45, 18), (50, 32), (44, 46), (31, 51), (17, 45),
              (13, 32), (18, 19), (32, 13), (43, 17)], 4.2, True)
        path([(32, 7), (31, 27), (32, 46), (31, 57)], 4.1)
    elif name == "khoja_ismail":
        path([(17, 18), (21, 26), (32, 31), (44, 26), (48, 17)], 4.5, True)
        shape([(17, 18), (23, 25), (32, 28), (42, 24), (48, 17), (46, 27),
               (41, 32), (31, 35), (22, 32), (17, 27)])
        path([(16, 46), (33, 45), (49, 46)], 4.3)
    elif name == "khoja_ismail_forged":
        path([(15, 15), (18, 25), (27, 33), (39, 34), (46, 28), (48, 21)], 4.7, True)
        path([(17, 48), (25, 45), (36, 46), (47, 43)], 4.5)
    elif name == "sri_rangan":
        for x, y, r in ((32, 18, 5.3), (20, 43, 5.1), (44, 43, 5.4)):
            spot(x, y, r)
    elif name == "ki_jaya":
        for shift in (0, 15):
            path([(11, 25+shift), (19, 21+shift), (25, 22+shift), (33, 28+shift),
                  (40, 29+shift), (49, 23+shift), (53, 22+shift)], 4.2, True)
    elif name == "encik_hamzah":
        path([(9, 32), (17, 24), (28, 21), (39, 25), (46, 32), (39, 39),
              (28, 43), (17, 40), (9, 32), (15, 26)], 3.8, True)
        path([(46, 32), (55, 24), (55, 40), (46, 32)], 3.7)
        spot(19, 31, 2.5)
    elif name == "ong_kuan_ship":
        path([(13, 14), (41, 14), (41, 23), (50, 23), (50, 50), (13, 50), (13, 14), (23, 14)], 4.3)
    elif name == "dawud_ship":
        shape([(32 + r * math.sin(i*math.pi/5), 21 - r * math.cos(i*math.pi/5))
               for i, r in enumerate([11, 4.7] * 5)])
        path([(15, 34), (20, 43), (32, 48), (43, 44), (49, 34)], 4.5, True)
        shape([(15, 34), (23, 42), (32, 44), (41, 41), (49, 34), (45, 45),
               (39, 50), (31, 52), (22, 49), (17, 43)])


def rim(rng, radius, state):
    points = []
    for i in range(120):
        angle = i * math.tau / 120
        r = radius + 1.3*math.sin(4*angle + .5) + .8*math.sin(9*angle) + rng.uniform(-.4, .4)
        if state == "weathered":
            r -= max(0, 1-abs(i-84)/5)*7 + max(0, 1-abs(i-33)/4)*6
        points.append((48 + r*math.cos(angle), 48 + r*math.sin(angle)))
    return points


def seal(name, state):
    rng = random.Random(f"{name}/{state}")
    base = rgb(MARKS[name])
    image = canvas(96)
    draw = ImageDraw.Draw(image)
    edge = rim(random.Random(27), 40, state)
    draw.polygon([xy(p) for p in edge], fill=INK)
    draw.polygon([xy((x, y-1)) for x, y in rim(random.Random(27), 38.6, state)],
                 fill=tone(base, -38))
    face = rim(random.Random(27), 35.7, state)
    surface = canvas(96, "L")
    ImageDraw.Draw(surface).polygon([xy((x-.6, y-2.5)) for x, y in face], fill=255)
    clay = canvas(96)
    clay.putdata([
        tone(base, (360-x-y)/24 + 3*math.sin(x/31+y/41)
             + 2*math.sin(x/19-y/26) + rng.gauss(0, 2.6)) + (255,)
        for y in range(96*S) for x in range(96*S)
    ])
    image.paste(clay, (0, 0), surface)
    draw = ImageDraw.Draw(image)
    stroke(draw, [(x-.6, y-2.5) for x, y in face[67:100]], tone(base, 38), 1.35)
    stroke(draw, [(x-.6, y-2.5) for x, y in face[12:46]], tone(base, -26), 1.25)
    stroke(draw, curve([(20, 38), (23, 32), (28, 27), (35, 23)]), tone(base, 24), .7)
    for _ in range(145):
        x, y = rng.uniform(15, 80), rng.uniform(14, 80)
        if math.hypot(x-47, y-45) < 32:
            dot(draw, x, y, rng.uniform(.15, .52), tone(base, rng.choice((-17, -12, 17, 22))))

    if state == "tampered":
        stroke(draw, curve([(20, 22), (25, 29), (29, 44), (35, 51), (36, 64), (31, 76)]),
               tone(base, -34), 1.9)
        stroke(draw, curve([(21, 22), (26, 29), (30, 44), (36, 51), (37, 64), (32, 76)]),
               tone(base, 29), .85)
        motif(image, name, 47, tone(base, -26), 28, 20)
    motif(image, name, 47, tone(base, 30), 25.3, 23.9, 1.18)
    motif(image, name, 47, tone(base, -63), 24.3, 22.1)
    if state == "weathered":
        for fragment in ([(16, 60), (21, 58), (24, 60)], [(50, 17), (52, 22), (56, 24)],
                         [(73, 63), (71, 66), (72, 69)]):
            stroke(draw, fragment, tone(base, -32), 1.15)
    if state == "broken":
        silhouette = image.getchannel("A")
        crack = [(54, 3), (55, 16), (54, 27), (58, 34), (52, 46), (57, 50), (51, 63),
                 (55, 71), (51, 82), (55, 92)]
        stroke(draw, [(x+2, y) for x, y in crack[1:-1]], tone(base, 31), 3)
        stroke(draw, [(x-1, y) for x, y in crack], INK, 5.1)
        stroke(draw, crack, (0, 0, 0, 0), 2.9)
        stroke(draw, [(53, 63), (43, 67), (38, 75)], tone(base, -44), 1.45)
        image.putalpha(ImageChops.multiply(silhouette, image.getchannel("A")))
    return image


HEMP = rgb("#C8B088")
COIR = rgb("#7D5C3B")


def rope(draw, guides, width=12, color=HEMP, blue=False):
    points = curve(guides)
    stroke(draw, points, INK, width+1.8)
    stroke(draw, points, tone(color, -25), width)
    stroke(draw, [(x-.45, y-1.0) for x, y in points], color, width*.77)
    stroke(draw, [(x-.7, y-1.8) for x, y in points], tone(color, 31), width*.38)
    distance = 0
    for i, (p, q) in enumerate(zip(points, points[1:])):
        length = math.dist(p, q)
        distance += length
        if distance < 3.7 or length == 0 or i > len(points)-5:
            continue
        distance -= 3.7
        tx, ty = (q[0]-p[0])/length, (q[1]-p[1])/length
        nx, ny = -ty, tx
        x, y = p
        fiber = [(x-nx*width*.36-tx*1.4, y-ny*width*.36-ty*1.4),
                 (x, y), (x+nx*width*.36+tx*1.9, y+ny*width*.36+ty*1.9)]
        stroke(draw, fiber, tone(color, -31), .72)
        stroke(draw, [(u-tx*.92, v-ty*.92) for u, v in fiber], tone(color, 20), .56)
    if blue:
        thread = [(x+.4 + .85*math.sin(i*.13), y-1.5) for i, (x, y) in enumerate(points)]
        stroke(draw, thread, "#1C3557", 2.85)
        stroke(draw, [(x-.35, y-.5) for x, y in thread], "#6385AD", 1.25)


def knot(name):
    image = canvas(128)
    draw = ImageDraw.Draw(image)
    if name == "square":
        rope(draw, [(9, 71), (31, 67), (54, 49), (75, 46), (84, 54), (79, 67), (61, 78), (99, 80), (118, 84)])
        rope(draw, [(10, 85), (29, 82), (48, 73), (48, 63), (36, 54), (40, 46), (53, 46),
                    (69, 58), (88, 66), (117, 59)], color=rgb("#AE9067"))
        rope(draw, [(76, 50), (83, 55), (80, 65), (72, 71)], 11)
    elif name == "lashing":
        rattan = rgb("#B89458")
        rope(draw, [(23, 98), (45, 82), (67, 65), (87, 45), (103, 24)], 18, COIR)
        for j in (-14, 0, 14):
            rope(draw, [(43+j, 44+j), (53+j, 46+j), (68+j, 59+j),
                        (77+j, 74+j), (72+j, 82+j)], 9, rattan)
        rope(draw, [(32, 99), (55, 88), (78, 69), (95, 53), (113, 47)], 8, rattan)
    elif name == "double_loop":
        rope(draw, [(13, 103), (33, 89), (51, 73), (61, 53), (61, 30), (51, 16), (36, 20),
                    (30, 38), (38, 57), (58, 71), (77, 65), (94, 46), (98, 27), (89, 19), (77, 24),
                    (70, 42), (73, 66), (96, 87), (113, 99)], 10)
        rope(draw, [(46, 75), (50, 66), (63, 64), (76, 71), (73, 81), (59, 83), (49, 76)], 10)
    elif name == "single_loop":
        rope(draw, [(14, 98), (33, 91), (50, 77), (58, 59), (51, 43), (53, 26), (67, 16),
                    (84, 20), (97, 35), (96, 49), (86, 63), (65, 74), (62, 86),
                    (76, 95), (105, 103)], 12)
        rope(draw, [(45, 75), (48, 67), (57, 65), (67, 71), (65, 81), (56, 85), (48, 81)], 10)
    elif name == "blue_thread_tie":
        rope(draw, [(26, 107), (43, 92), (60, 66), (49, 54), (28, 47), (13, 50), (16, 62),
                    (33, 70), (57, 68), (77, 59), (98, 45), (111, 47), (111, 58),
                    (94, 68), (67, 69), (72, 86), (94, 110)], 10, COIR, True)
        rope(draw, [(56, 57), (63, 56), (70, 65), (68, 77), (62, 82)], 10, COIR, True)
    elif name == "frayed_retie":
        rope(draw, [(10, 86), (32, 80), (50, 64), (58, 42), (73, 35), (86, 44), (81, 61),
                    (66, 72), (51, 69), (45, 58), (48, 44), (56, 36), (54, 24)], 12, COIR)
        rope(draw, [(25, 103), (39, 92), (48, 75), (58, 60), (75, 57), (85, 66),
                    (76, 78), (68, 79), (79, 88), (99, 88)], 11)
        rng = random.Random(15)
        for x, y, ex, ey in ((54, 26, 47, 12), (96, 88, 114, 83), (25, 103, 17, 116)):
            for _ in range(8):
                a, b = rng.uniform(-4, 4), rng.uniform(-4, 4)
                c, d = rng.uniform(-6, 6), rng.uniform(-6, 6)
                stroke(draw, curve([(x+a, y+b), ((x+ex)/2+c, (y+ey)/2+d), (ex+c, ey+d)]),
                       tone(HEMP, rng.randint(-58, 14)), rng.uniform(.7, 1.45))
    return image


def save(image, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path)


def paint():
    art = ROOT / "assets/art"
    inspection = ROOT / "assets/inspection"
    for name in MARKS:
        if name:
            mark = canvas(64)
            motif(mark, name, 64, INK)
            save(mark, art / "marks" / f"mark_{name}.png", 64)
        for state in STATES:
            filename = f"seal_clay_{name+'_' if name else ''}{state}.png"
            image = seal(name, state)
            save(image, inspection / filename, 96)
            save(image, inspection / "manifest" / filename, 48)
    for name in KNOTS:
        save(knot(name), art / "knots" / f"knot_{name}.png", 128)


def contact_sheet(path):
    art = ROOT / "assets/art"
    inspection = ROOT / "assets/inspection"
    width, height = 2256, 2110
    desk = Image.open(art / "inspection/inspection_desk_bg.png").convert("RGBA")
    page = Image.new("RGBA", (width, height))
    for row, y in enumerate(range(0, height, desk.height)):
        for col, x in enumerate(range(0, width, desk.width)):
            tile = desk.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if col % 2 else desk
            page.paste(tile.transpose(Image.Transpose.FLIP_TOP_BOTTOM) if row % 2 else tile, (x, y))
    draw = ImageDraw.Draw(page)
    small, medium, large = [ImageFont.truetype("DejaVuSans.ttf", size) for size in (15, 23, 37)]

    def header(y, title):
        draw.rectangle((0, y, width, y+33), fill="#3B261A")
        draw.text((27, y+2), title, font=medium, fill="#F7E7C4")

    def label(x, y, title, font=small):
        draw.text((x, y), title, font=font, fill="#F7E7C4", anchor="mm", stroke_width=1, stroke_fill=INK)

    def asset(file, x, y, scale, ink=False):
        image = Image.open(file).convert("RGBA")
        side = image.width * scale
        if ink:
            draw.rounded_rectangle((x-side//2-4, y-side//2-4, x+side//2+4, y+side//2+4),
                                   radius=5, fill="#F7E7C4", outline="#3B261A", width=2)
        page.alpha_composite(image.resize((side, side), Image.Resampling.NEAREST),
                             (x-side//2, y-side//2))

    header(0, "PORT MASTER   /   CARGO INSPECTION ART")
    header(40, "REGISTERED MARKS & LOOKALIKE  ·  64 px  ·  1× and 2×")
    for i, name in enumerate(n for n in MARKS if n):
        x = 136 + 280*i
        file = art / "marks" / f"mark_{name}.png"
        asset(file, x-70, 150, 1, True)
        asset(file, x+46, 150, 2, True)
        label(x, 231, name)

    header(255, "CLAY CLOSURES  ·  96 px inspection / 48 px manifest  ·  both at 1× and 2×")
    draw.text((1130, 263), "Top: 96 px / 48 px at 1×    •    Center: 96 px at 2×    •    Bottom left: 48 px at 2×",
              font=small, fill="#F7E7C4")
    for i, name in enumerate(MARKS):
        x = 128 + 248*i
        label(x, 308, name or "generic / unmarked", medium)
        for j, state in enumerate(STATES):
            y = 350 + j*360
            file = f"seal_clay_{name+'_' if name else ''}{state}.png"
            asset(inspection / file, x-65, y+33, 1)
            asset(inspection / file, x+15, y+176, 2)
            asset(inspection / "manifest" / file, x+52, y+33, 1)
            asset(inspection / "manifest" / file, x-62, y+282, 2)
            label(x+42, y+294, state)

    header(1800, "CORDAGE  ·  128 px  ·  1× and 2×")
    for i, name in enumerate(KNOTS):
        x = 186 + 375*i
        file = art / "knots" / f"knot_{name}.png"
        asset(file, x-108, 1950, 1)
        asset(file, x+64, 1950, 2)
        label(x, 2087, name, medium)
    path.parent.mkdir(parents=True, exist_ok=True)
    page.convert("RGB").save(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contact-sheet", type=Path)
    args = parser.parse_args()
    paint()
    if args.contact_sheet:
        contact_sheet(args.contact_sheet)


if __name__ == "__main__":
    main()
