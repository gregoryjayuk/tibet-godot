#!/usr/bin/env python3
"""The sun tables (plan chapter 04, 8.5; the game's M3 sprint 5, step 4): for each opening an interior's shaft of sun
comes through (the Tsokchen's ten lantern windows, its kit type's SHAFT sockets; later the chapels' lantern windows and
the houses' smoke-holes), how much of it the sun can see and how far its shaft reaches inside, at 96 moments of the day
(every 15 minutes of local mean time from 00:00) on every seventh day of the season from 21 October 1903 (the game's
day 0, autoload/calendar.gd), by the sun of chapter 02, 2.8 (tools/calendar/sky.py, which the game's Calendar follows).
Lit: the sun's centre above the terrain's horizon along its own azimuth (tools/terrain/horizon.py's direct ray over the
padded ground, as the sun report checks the map), in front of the opening's wall, and not behind another building near
it (each a box from its kit type's bounds, standing where the town puts it: data/monastery.json's pads and houses), at
six points over its face, so a value is the share of it lit. Reach: from the opening's inner face along the sun's ray
through the building's rooms (its sidecar's `rooms`, the hollows Mass.add_room cut) to where it leaves them, a floor,
a wall or the gallery's floor. The game's shafts (world/shafts.gd) read both at the game's day and minute.
Writes data/sun_tables.json and docs/town/sun-table-report.md (when each window's sun comes and goes on 28 October, when
its shaft reaches the hall's floor, against chapter 04's card for the Tsokchen, 3.1).
Run: tools/py tools/town/sun_table.py   (about 20 s)
"""
import datetime
import json
import math
import os
import struct
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("VALLEY", "valley_padded_1m")  # the ground as built (tools/terrain/build.sh's horizon pass)
os.environ.setdefault("RING", "ring_shaped_30m")
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
sys.path.insert(0, os.path.join(ROOT, "tools", "calendar"))
import horizon  # noqa: E402
import sky  # noqa: E402
from terrain_site import Site  # noqa: E402

KIT = os.path.join(ROOT, "assets", "generated", "kit", "types")
OUT = os.path.join(ROOT, "data", "sun_tables.json")
REPORT = os.path.join(ROOT, "docs", "town", "sun-table-report.md")
DAY0 = datetime.date(1903, 10, 21)  # the game's day 0
DAYS, DAY_STEP = 18, 7  # 21 October 1903 to 17 February 1904
SAMPLES = 96  # a day's, every 15 minutes
NEAR = 300.0  # metres: the buildings that may stand in a window's sun
STEP = 0.1  # metres: the reach's march through the rooms
# The openings: [house (a pad of data/monastery.json), what they are, their width and height (the kit's)]
OPENINGS = [("MON-01", "the Tsokchen's lantern windows (tibet-blender kit/monastery.py tsokchen, interior)", 1.2, 1.6),
            ("MON-04", "the Jampa Lhakhang's lantern window, V-30's (kit/monastery.py lhakhang 'maitreya', interior)", 1.2, 1.4)]
REPORT_DAY = 7  # 28 October, the default day (chapter 02's table 2.8)
# What stands in a hall's rooms and stops a shaft before the rooms' walls, in the kit's frame (x0, x1, y0, y1, z0, z1): the
# Jampa Lhakhang's Maitreya, his head and body (the face's plane at y 3.3) and his throne (kit/jampa_rooms.py)
SOLIDS = {"MON-04": [(-1.3, 1.3, 3.3, 5.2, 2.4, 7.6), (-2.7, 2.7, 2.4, 5.2, 0.0, 2.6), (-1.0, 1.0, 1.6, 3.3, 2.4, 3.5)]}
# V-30 (chapter 08): the face's plane and its band from the chin to the brow, in the kit's frame
FACE = {"y": 3.3, "x": 0.5, "chin": 5.75, "brow": 6.85}


def glb_bounds(path):
    """A glb's bounds in the kit's frame (Blender's: z up), from its accessors' min and max (glTF is y up, -z north)."""
    with open(path, "rb") as f:
        f.read(12)
        n, kind = struct.unpack("<I4s", f.read(8))
        doc = json.loads(f.read(n))
    lo, hi = np.full(3, np.inf), np.full(3, -np.inf)
    for mesh in doc.get("meshes", []):
        for prim in mesh["primitives"]:
            a = doc["accessors"][prim["attributes"]["POSITION"]]
            lo = np.minimum(lo, a["min"])
            hi = np.maximum(hi, a["max"])
    return (lo[0], -hi[2], lo[1]), (hi[0], -lo[2], hi[1])  # (x, y, z) glTF -> (x, -z, y) Blender


def frame(facing):
    """The kit's +x and +y in the town grid for a building turned to `facing` (clockwise from north)."""
    f = math.radians(facing)
    return np.array([-math.cos(f), math.sin(f)]), np.array([-math.sin(f), -math.cos(f)])


class Boxes:
    """The buildings near a place as oriented boxes: centre, half sizes, axes, base and top, in the real ground's heights
    (the padded raster's: the design's plus the site's shift, data/terrain/site.json)."""

    def __init__(self, H, shift):
        mon = json.load(open(os.path.join(ROOT, "data", "monastery.json")))
        self.ids, rows = [], []
        cache = {}

        def add(bid, kit, at, facing, z0):
            path = os.path.join(KIT, kit + ".glb")
            if not os.path.exists(path):
                return
            if kit not in cache:
                cache[kit] = glb_bounds(path)
            lo, hi = cache[kit]
            ex, ey = frame(facing)
            c = np.array(at, float) + ex * (lo[0] + hi[0]) / 2 + ey * (lo[1] + hi[1]) / 2
            self.ids.append(bid)
            rows.append([c[0], c[1], (hi[0] - lo[0]) / 2, (hi[1] - lo[1]) / 2, ex[0], ex[1], ey[0], ey[1], z0 + lo[2], z0 + hi[2]])

        for pid, p in mon["pads"].items():
            if p.get("kit"):
                add(pid, p["kit"], p["at"], float(p.get("facing", 180.0)), float(p["level"]) + shift)
        for h in mon["houses"]:  # (their files as world/town.gd's kit_file names them)
            x, y = h["pos"][:2]
            z = float(H(np.array([x]), np.array([y]))[0])
            kit = h.get("kit") or "monk_house_%s" % h["type"].lower()
            add(h["id"], "%s_v%d" % (kit, int(h.get("seed", 1))), (x, y), float(h.get("rot_deg", 180.0)), z)
        self.a = np.array(rows, float)

    def blocked(self, p, d, skip):
        """Whether the ray from p (x, y, z) along the unit d meets a box (but `skip`'s): the slab test in each box's frame."""
        a = self.a
        keep = (np.hypot(a[:, 0] - p[0], a[:, 1] - p[1]) < NEAR) & (a[:, 9] > p[2]) & skip
        if not keep.any():
            return False
        b = a[keep]
        rx, ry = p[0] - b[:, 0], p[1] - b[:, 1]
        o = np.stack([rx * b[:, 4] + ry * b[:, 5], rx * b[:, 6] + ry * b[:, 7], p[2] - (b[:, 8] + b[:, 9]) / 2], 1)
        v = np.stack([d[0] * b[:, 4] + d[1] * b[:, 5], d[0] * b[:, 6] + d[1] * b[:, 7], np.full(len(b), d[2])], 1)
        half = np.stack([b[:, 2], b[:, 3], (b[:, 9] - b[:, 8]) / 2], 1)
        par = np.abs(v) < 1e-12  # (along a face's plane: inside its slab or never)
        with np.errstate(divide="ignore", invalid="ignore"):
            t1 = (-half - o) / np.where(par, 1.0, v)
            t2 = (half - o) / np.where(par, 1.0, v)
        inside = np.abs(o) <= half
        tn = np.where(par, np.where(inside, -np.inf, np.inf), np.minimum(t1, t2)).max(1)
        tf = np.where(par, np.where(inside, np.inf, -np.inf), np.maximum(t1, t2)).min(1)
        return bool(((tn <= tf) & (tf > 0.0)).any())


def sun(date, minute, lat, lon):
    """The sun's altitude and azimuth (degrees) and its unit direction in the town grid (x east, y north, z up)."""
    alt, az = sky.sun_alt_az(sky.lmt_to_jd(date, minute, lon), lat, lon)
    a, z = math.radians(alt), math.radians(az)
    return alt, az, np.array([math.sin(z) * math.cos(a), math.cos(z) * math.cos(a), math.sin(a)])


class Opening:
    """A window a shaft comes through: its centre on the wall's face (its SHAFT socket), its wall's way out, six points
    over its face, and its building's frame and rooms."""

    def __init__(self, house, pad, side, sock, w, h, shift=0.0):
        self.key, self.house, self.sock, self.w, self.h = "%s:%s" % (house, sock[5:]), house, sock, w, h
        self.at, self.level = np.array(pad["at"], float), float(pad["level"])
        self.ex, self.ey = frame(float(pad["facing"]))
        self.k = np.array(side["socket_pos"][sock], float)  # in the kit's frame
        yaw = math.radians(side["socket_yaw"][sock])
        self.in_k = np.array([math.cos(yaw), math.sin(yaw)])  # its +y, into the building
        self.rooms = np.array([r[:6] for r in side["rooms"]], float)  # x0, x1, y0, y1, z0, z1
        self.solids = np.array(SOLIDS.get(house, [(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)]), float)
        self.c = np.array([*(self.at + self.ex * self.k[0] + self.ey * self.k[1]), self.level + self.k[2]])
        inward = self.ex * self.in_k[0] + self.ey * self.in_k[1]
        self.out = -inward
        along = np.array([inward[1], -inward[0]])
        self.pts = [self.c + np.array([along[0] * u - inward[0] * 0.05, along[1] * u - inward[1] * 0.05, v + shift])
                    for u in (-w / 3, 0.0, w / 3) for v in (-h / 4, h / 4)]  # (in the raster's heights: the design's + the shift)

    def to_kit(self, d):
        """A direction of the town grid in the kit's frame."""
        return np.array([d[0] * self.ex[0] + d[1] * self.ex[1], d[0] * self.ey[0] + d[1] * self.ey[1], d[2]])

    def reach(self, d):
        """How far the sun's ray from this window's middle runs inside before it leaves the building's rooms, and where it
        ends (the kit's frame): from the inside of the wall (half a metre in) along -d."""
        s = -self.to_kit(d)
        p0 = self.k + np.array([self.in_k[0], self.in_k[1], 0.0]) * 0.5
        t = np.arange(0.0, 60.0, STEP)
        q = p0[None, :] + t[:, None] * s[None, :]
        r = self.rooms
        inside = ((q[:, None, 0] >= r[None, :, 0]) & (q[:, None, 0] <= r[None, :, 1]) & (q[:, None, 1] >= r[None, :, 2])
                  & (q[:, None, 1] <= r[None, :, 3]) & (q[:, None, 2] >= r[None, :, 4]) & (q[:, None, 2] <= r[None, :, 5])).any(1)
        o = self.solids
        inside &= ~((q[:, None, 0] > o[None, :, 0]) & (q[:, None, 0] < o[None, :, 1]) & (q[:, None, 1] > o[None, :, 2])
                    & (q[:, None, 1] < o[None, :, 3]) & (q[:, None, 2] > o[None, :, 4]) & (q[:, None, 2] < o[None, :, 5])).any(1)
        if not inside[0]:
            return 0.0, p0
        n = int(np.argmin(inside)) if not inside.all() else len(t)
        return float(t[n - 1]) + 0.5, q[n - 1]


def side_of(outward):
    b = math.degrees(math.atan2(outward[0], outward[1])) % 360.0
    return "east" if 45 <= b < 135 else ("south" if 135 <= b < 225 else ("west" if 225 <= b < 315 else "north"))


def hm(m):
    return "—" if m is None else "%02d:%02d" % (m // 60, m % 60)


def main():
    site = Site.load()
    lat, lon = site.lat, site.lon
    H = horizon.Heights(site)
    boxes = Boxes(H, site.shift)
    mon = json.load(open(os.path.join(ROOT, "data", "monastery.json")))
    ops = []
    for house, what, w, h in OPENINGS:
        pad = mon["pads"][house]
        side = json.load(open(os.path.join(KIT, pad["kit"] + ".json")))
        if not any(k.startswith("SOCK_SHAFT_") for k in side["socket_pos"]):  # (its carved variant, `<type>_in`)
            side = json.load(open(os.path.join(KIT, pad["kit"].replace("_v1", "_in_v1") + ".json")))
        for s in sorted((k for k in side["socket_pos"] if k.startswith("SOCK_SHAFT_")), key=lambda k: int(k.split("_")[-1])):
            ops.append(Opening(house, pad, side, s, w, h, site.shift))
    azs = np.arange(60.0, 300.01, 0.5)  # the sun's azimuths over the season, east to west by the south
    lit_of = {}
    for op in ops:
        skip = np.array([i != op.house for i in boxes.ids])
        hz = [np.array([horizon.direct(H, p[0], p[1], p[2], az) for az in azs]) for p in op.pts]

        def lit(date, minute, op=op, hz=hz, skip=skip):
            alt, az, d = sun(date, minute, lat, lon)
            if alt <= 0.0 or d[0] * op.out[0] + d[1] * op.out[1] <= 0.0:
                return 0.0, d
            n = sum(1 for p, hp in zip(op.pts, hz) if alt > np.interp(az, azs, hp) and not boxes.blocked(p, d, skip))
            return n / len(op.pts), d
        lit_of[op.key] = lit
        print("%s: facing %s" % (op.key, side_of(op.out)), flush=True)
    tables = {}
    for op in ops:
        rows, reach = [], []
        for k in range(DAYS):
            date = DAY0 + datetime.timedelta(days=k * DAY_STEP)
            row, rr = [], []
            for i in range(SAMPLES):
                v, d = lit_of[op.key](date, i * 1440.0 / SAMPLES)
                row.append(round(v, 2))
                rr.append(round(op.reach(d)[0], 1) if v > 0.0 else 0.0)
            rows.append(row)
            reach.append(rr)
        tables[op.key] = {"house": op.house, "socket": op.sock, "at": [round(float(v), 2) for v in op.c],
                          "out": round(math.degrees(math.atan2(op.out[0], op.out[1])) % 360.0, 1), "w": op.w, "h": op.h,
                          "lit": rows, "reach": reach}
    json.dump({"about": "The sun tables (plan chapter 04, 8.5): for each opening (house:socket), the share of it the sun "
                        "sees (lit) and how far its shaft runs inside from the window's face, metres (reach), at 96 moments "
                        "a day (minute = i x 15, local mean time) on the game's days 0, 7, 14, ... (day 0 = 21 October "
                        "1903); at, its centre in the town grid and above sea level; out, its wall's outward bearing; w, "
                        "h, its size. Written by tools/town/sun_table.py.",
               "samples": SAMPLES, "day0": str(DAY0), "day_step": DAY_STEP,
               "dates": [str(DAY0 + datetime.timedelta(days=k * DAY_STEP)) for k in range(DAYS)], "openings": tables},
              open(OUT, "w"), indent=None, separators=(",", ":"))
    report(ops, lit_of, lat, lon)
    print("sun tables: %s (%d openings, %d days x %d samples); %s" % (OUT, len(tables), DAYS, SAMPLES, REPORT))


def report(ops, lit_of, lat, lon):
    """The 28th's comings and goings to the minute, where the shafts end, and chapter 04's card beside them."""
    date = DAY0 + datetime.timedelta(days=REPORT_DAY)
    lines = ["# The sun tables: the Tsokchen's lantern windows",
             "",
             "_Written by `tools/town/sun_table.py` (plan chapter 04, 8.5; the game's M3 sprint 5, step 4). Each opening's sun "
             "through the day: the sun's centre over the terrain's horizon along its azimuth (`tools/terrain/horizon.py`'s "
             "direct ray over the padded ground), in front of the window's wall, and not behind another building within "
             "%d m (each a box from its kit type's bounds); its shaft followed from the window through the hall's rooms (the "
             "kit's hollows) to where it ends. Rerun it after a change to the ground, the hall or the monastery's "
             "buildings._" % NEAR,
             "",
             "## %s (the default day, chapter 02's table 2.8)" % date.strftime("%d %B %Y").lstrip("0"),
             "",
             "| window | faces | sun from | sun until | on the hall's floor | on the gallery's floor | on a wall, minutes |",
             "|---|---|---|---|---|---|---|"]
    first_side, floor_side = {}, {}
    last_any = None
    for op in ops:
        on, floor, gallery, wall = [], [], [], []
        for m in range(300, 1140):
            v, d = lit_of[op.key](date, float(m))
            if v <= 0.0:
                continue
            on.append(m)
            ln, end = op.reach(d)
            (floor if end[2] < 0.3 else (gallery if abs(end[2] - 7.2) < 0.3 else wall)).append(m)
        span = (lambda ms: "—" if not ms else "%s-%s" % (hm(ms[0]), hm(ms[-1])))
        sd = side_of(op.out)
        lines.append("| %s | %s | %s | %s | %s | %s | %d |" % (op.key, sd, hm(on[0] if on else None), hm(on[-1] if on else None),
                                                               span(floor), span(gallery), len(wall)))
        if on:
            first_side[sd] = min(first_side.get(sd, 9999), on[0])
            last_any = max(last_any or 0, on[-1])
        if floor:
            a, b = floor_side.get(sd, (9999, 0))
            floor_side[sd] = (min(a, floor[0]), max(b, floor[-1]))
    lines += ["", "## Against chapter 04's card (3.1)", "", "| the card | its time | the ground's |", "|---|---|---|",
              "| the first shaft through the east windows | 06:38 (the card); the gilded roofs' first sun 07:22 on the terrain (2.8) | %s |" % hm(first_side.get("east")),
              "| the east shafts slide down the west gallery but never reach the hall's floor | the morning | %s |" % (
                  "on the floor %s-%s" % (hm(floor_side["east"][0]), hm(floor_side["east"][1])) if "east" in floor_side else "never on the floor"),
              "| the south windows take over, their shaft on the aisle at noon | from about 10:30 | on the floor %s |" % (
                  "%s-%s" % (hm(floor_side["south"][0]), hm(floor_side["south"][1])) if "south" in floor_side else "never"),
              "| the west windows' shafts onto the east capitals | by 14:30 | lit from %s%s |" % (
                  hm(first_side.get("west")), "; on the floor %s-%s" % (hm(floor_side["west"][0]), hm(floor_side["west"][1])) if "west" in floor_side else ""),
              "| no sun after | 16:40 (the card); the gilded roofs' last sun 16:35 on the terrain | %s |" % hm(last_any)]
    for op in ops:  # the noon shaft: where the south windows' sun falls on the hall's floor
        if side_of(op.out) != "south":
            continue
        alt, az, d = sun(date, 720.0, lat, lon)
        ln, end = op.reach(d)
        lines += ["", "At noon the sun stands %.1f degrees up at %.1f degrees; through %s, %.1f m over the hall's floor, its shaft "
                  "runs %.1f m and ends at the hall's (%.1f, %.1f, %.1f) (the nave from the door at y -15.3 to the inner chapel's "
                  "wall at 6.6, the central aisle between x -1.5 and 1.5; chapter 04 wants it on the aisle about three-quarters of "
                  "the way to the chapel, where the tea is carried)." % (alt, az, op.key, op.k[2], ln, end[0], end[1], end[2])]
        break
    # V-30: the Jampa Lhakhang's lantern window, where its sun falls on the face through the season (chapter 08)
    for op in ops:
        if op.house != "MON-04":
            continue
        lines += ["", "## V-30: the Jampa Lhakhang's lantern window on Maitreya's face", "",
                  "Its sun at noon, where its ray from the window's middle crosses the face's plane (the face %.1f m across, its chin at %.2f m and its brow at %.2f m over the floor; chapter 08: the patch from chin to brow between 21 October and 11 November, across the face from 11:15 to 12:10):" % (2 * FACE["x"], FACE["chin"], FACE["brow"]),
                  "", "| day | time | lit | across (m) | up (m) | on the face |", "|---|---|---|---|---|---|"]
        for day in (datetime.date(1903, 10, 21), datetime.date(1903, 10, 28), datetime.date(1903, 11, 5), datetime.date(1903, 11, 11)):
            for m in (675.0, 700.0, 720.0, 730.0):
                v, d = lit_of[op.key](day, m)
                s = -op.to_kit(d)
                t = (FACE["y"] - op.k[1]) / s[1] if s[1] > 1e-6 else float("nan")
                hit = op.k + s * t
                on = v > 0.0 and abs(hit[0]) <= FACE["x"] and FACE["chin"] - 0.3 <= hit[2] <= FACE["brow"] + 0.3
                lines.append("| %s | %s | %.2f | %+.2f | %.2f | %s |" % (day.strftime("%d %b"), hm(int(m)), v, hit[0], hit[2], "yes" if on else "no"))
        break
    open(REPORT, "w").write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
