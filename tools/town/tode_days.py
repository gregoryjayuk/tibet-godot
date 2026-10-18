#!/usr/bin/env python3
"""Tödé's people (M3 sprint 4, step 6; plan chapter 05, 3.1's Tödé households, DS-03, A-06, A-44, A-45, A-47, NPC-10 and
NPC-38; chapter 02, TOD-02, TOD-05 and 06, TOD-10, TOD-11 to 14, R-24): who of Tödé's households (data/population.json)
is out of doors when, and where, each from their own door along the field paths (data/tode.json `ways`, a tree whose
root is the Tödé Stair's top: the way between two places runs down one to where it meets the other and up that), as acts
with their minutes for world/tode_people.gd:
- the Bön circuit (A-06, 05:30-06:30): Yungdrung Gyaltsen (NPC-38) of H-TOD-045 and a woman of another Bön household
  round their chapel TOD-02 anticlockwise on R-24 (data/tode_things.json `circuit`), turning the wheels in its niches as
  they pass; at 16:00 he goes to light its lamps (his day, chapter 05);
- threshing (A-44, 08:30-15:00): six at each of the floors TOD-11 to 14 in a line abreast across it (the kit's FLAIL
  sockets), three men and three women from the households whose way there is shortest, neighbours striking alternately; the
  men's tea at 13:30; the women winnowing from 13:00 (A-45) to 16:00; Chödrön (NPC-10) of H-TOD-001 at TOD-13 by her day
  (threshing 08:30-13:30, winnowing 14:00-16:00, on her roof facing the monastery 17:05-17:30), Gyaltsen at his nearest;
- on the roofs (A-44's "Tödé roofs"): two women threshing face to face on each of ROOFS rammed-earth houses' roofs, up
  through the hatch, then gathering the grain;
- the millers at TOD-05's and TOD-06's doors and inside by the stones, 07:00-17:30;
- the water carriers (A-47's hours; the leat TOD-10 is Tödé's water, chapter 02): from their doors to the leat where their
  way crosses it at a culvert (data/tode_leat.json), a barrel filled, home laden, morning and afternoon;
- down to Shöl and back: traders and porters down the Tödé Stair to its foot in the morning, up again in the afternoon;
- in the fields: two stooping over the stubble near their houses.
Each act is {"go": [[x, y, z]] (the town grid), "ts": the game minute at each point, "kind": its pace (PACE), "side",
"kora": turning the wheels it passes} or {"stay": [x, y, z], "facing" (a bearing), "clip", "t0", "t1", "flail" (a flail in
the hands), "phase" (seconds into its clip: neighbours alternate)}; a person with `full_moon` is not out after that minute
on the full moon (Chödrön, with her son at the Lookout: world/gorge_people.gd).
Run: tools/py tools/town/tode_days.py   Writes data/tode_people.json and docs/town/tode-people-report.md (tools/terrain/
build.sh runs it after tools/town/tode_things.py).
"""
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
from terrain_site import Site  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
KIT = os.path.join(ROOT, "assets", "generated", "kit", "types")
DATA = os.path.join(ROOT, "data")
OUT = os.path.join(DATA, "tode_people.json")
REPORT = os.path.join(ROOT, "docs", "town", "tode-people-report.md")

PER_MIN = 10.0  # real seconds a game minute at the play rate (autoload/world_clock.gd; world/gorge_people.gd)
STEEP = 0.25  # a segment rising or falling more than this in a metre is a flight
PACE = {"man": (0.46, 0.66, 0.95), "woman": (0.42, 0.6, 0.85), "elder": (0.32, 0.48, 0.65), "laden": (0.28, 0.42, 0.7),
        "kora": (0.3, 0.45, 0.52)}  # m/s up a flight, down one, on the level; `kora` the circuit's unhurried walk
CHOP = 0.9583  # seconds: the flail's swing (people2/body.py TODE_CLIPS' Chop_Tree), neighbours half of it apart
FILL = 1.2  # game minutes a barrel takes at the leat (world/gorge_people.gd FILL)
NEAR = 320.0  # metres by the paths: the farthest a thresher walks to a floor (else someone nearer, or one's own roof)
MEN = ["tode_man", "tode_man_b", "tode_man_c"]  # the threshers' bodies (people2/body.py: Tödé's, with the work's clips)
WOMEN = ["tode_woman", "tode_woman_b", "tode_woman_c", "tode_woman_d"]
WORK = {"farmer", "herder", "labourer", "spinner", "weaver"}  # who threshes (chapter 05's TM and TW at A-44)
FLOORS = ["TOD-13", "TOD-14", "TOD-11", "TOD-12"]  # (Chödrön's first: her day at TOD-13)
ROOFS = 3  # rammed-earth roofs with two women threshing
CARRIERS = ["water_woman_b", "water_woman_c", "water_woman_d", "water_girl_b"]  # barrels on their backs (people2/body.py)
TRIPS = [("porter", "m"), ("porter_woman", "f"), ("townsman_b", "m"), ("townswoman_b", "f")]  # down to Shöl and back
MILLERS = {"TOD-05": "house_man", "TOD-06": "elder_man"}
FIELD = ["tode_woman_b", "tode_man_c"]  # stooping over the stubble
TSOKCHEN = (540.0, 150.0)  # MON-01, which Chödrön faces from her roof at dusk (data/town.json)
FORECOURT = (-22.0, 257.0)  # the Tödé Stair's foot's forecourt by the Tödé chorten, where Shöl begins


def frame(facing):
    """A kit's +x and +y on the town grid (its front, -y, faces `facing`)."""
    f = math.radians(facing)
    return (-math.cos(f), math.sin(f)), (-math.sin(f), -math.cos(f))


def kit_to_town(at, facing, k):
    X, Y = frame(facing)
    return (at[0] + k[0] * X[0] + k[1] * Y[0], at[1] + k[0] * X[1] + k[1] * Y[1])


def bearing(a, b):
    return math.degrees(math.atan2(b[0] - a[0], b[1] - a[1])) % 360.0


def sidecar(kit):
    p = os.path.join(KIT, kit + ".json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None


def kit_file(h):
    """A Tödé house's kit file (world/town.gd kit_file)."""
    if h.get("kit"):
        return "%s_v%d" % (h["kit"], int(h.get("seed", 1)))
    if h["type"] == "A":
        return "log_house_%s_v%d" % (h["variant"].lower(), int(h["seed"]))
    if h["type"] == "E":
        return "poor_house_e1_v%d" % int(h["seed"])
    return ""


def timed(pts, t0, kind):
    """The game minute at each point of a walk from minute `t0` at `kind`'s pace."""
    up, down, flat = PACE[kind]
    ts = [t0]
    for a, b in zip(pts, pts[1:]):
        L = math.dist(a, b)
        v = flat
        if L > 1e-6 and abs(b[2] - a[2]) / L > STEEP:
            v = up if b[2] > a[2] else down
        ts.append(ts[-1] + L / v / PER_MIN)
    return [round(t, 3) for t in ts]


def length(pts):
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))


def junction(a, b):
    """From `a`'s first point to `b`'s first, both lists running to the Tödé Stair's top along the field paths: down `a`
    to where it meets `b`, up `b`."""
    idx = {}
    for j, p in enumerate(b):
        idx.setdefault((round(p[0], 1), round(p[1], 1)), j)
    for i, p in enumerate(a):
        j = idx.get((round(p[0], 1), round(p[1], 1)))
        if j is not None:
            return a[:i + 1] + b[:j][::-1]
    return a + b[::-1]


def clean(pts):
    out = []
    for p in pts:
        q = [round(float(p[0]), 2), round(float(p[1]), 2), round(float(p[2]), 2)]
        if not out or math.dist(out[-1], q) > 0.05:
            out.append(q)
    return out


class Plan:
    def __init__(self):
        self.td = json.load(open(os.path.join(DATA, "tode.json"), encoding="utf-8"))
        self.things = json.load(open(os.path.join(DATA, "tode_things.json"), encoding="utf-8"))
        self.leat = json.load(open(os.path.join(DATA, "tode_leat.json"), encoding="utf-8"))
        self.stair = json.load(open(os.path.join(DATA, "tode_stair.json"), encoding="utf-8"))
        pop = json.load(open(os.path.join(DATA, "population.json"), encoding="utf-8"))
        self.hh = {h["house"]: h for h in pop["households"] if h.get("community") == "tode" and not h.get("away")}
        self.houses = {h["id"]: h for h in self.td["houses"]}
        self.ways = self.td["ways"]
        site = Site.load()
        g = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
        self.Z = lambda x, y: float(g.z(np.asarray(x, float), np.asarray(y, float)) - site.shift)
        self.used = set()  # members out at work
        self.people = []

    # -------------------------------------------------------------------- places: each a list from it to the stair's top
    def home(self, hid):
        """From the house's ground-floor door (a D's through its yard's gate) out to its way and along it."""
        h = self.houses[hid]
        w = self.ways.get(hid)
        sc = sidecar(kit_file(h))
        if not w or sc is None:
            return None
        pos, rot, lv = h["pos"], h["rot_deg"], h["pos"][2]
        P = lambda k: list(kit_to_town(pos, rot, k)) + [lv]
        sp = sc["socket_pos"]
        doors = [v for k, v in sp.items() if k.startswith("SOCK_DOOR")]
        d = min(doors, key=lambda q: q[2]) if doors else [0.0, -h["footprint"][1] / 2, 0.0]
        pts = [P(d), P((d[0], d[1] - 1.2))]
        if h["type"] == "D" and "SOCK_GATE_1" in sp:
            gx, gy = sp["SOCK_GATE_1"][:2]
            s = 1.0 if gx > 0 else -1.0
            pts += [P((gx - s * 1.0, gy)), P((gx + s * 1.2, gy))]
        return clean(pts + w)

    def floor_spots(self, fid):
        t = [t for t in self.things["things"] if t["id"] == fid][0]
        sc = sidecar(t["kit"])
        spots = []
        for k in range(1, 7):
            q = sc["socket_pos"].get("SOCK_FLAIL_%d" % k)
            if q:
                x, y = kit_to_town(t["at"], t["facing"], q)
                spots.append([round(x, 2), round(y, 2), round(t["level"] + 0.05, 2)])
        u = (spots[-1][0] - spots[0][0], spots[-1][1] - spots[0][1])
        n = (-u[1], u[0])  # the line's left: the six face it, abreast
        return t, spots, math.degrees(math.atan2(n[0], n[1])) % 360.0

    def floor_place(self, fid, spot):
        """From a spot on the floor over its kerb to its way and along it."""
        t = [t for t in self.things["things"] if t["id"] == fid][0]
        w = self.ways[fid]
        c, r = t["at"], 6.0 if "_12_" in t["kit"] else 7.0
        dx, dy = w[0][0] - c[0], w[0][1] - c[1]
        L = math.hypot(dx, dy) or 1.0
        rim = [c[0] + dx / L * (r - 0.6), c[1] + dy / L * (r - 0.6), t["level"] + 0.05]
        out = [c[0] + dx / L * (r + 0.6), c[1] + dy / L * (r + 0.6), t["level"]]
        return clean([spot, rim, out] + w)

    def chapel_place(self, k=None):
        """From the circuit's point nearest the chapel's way (or point `k`) out to the way and along it."""
        w = self.ways["TOD-02"]
        circ = self.things["circuit"]
        if k is None:
            k = min(range(len(circ)), key=lambda i: math.dist(circ[i][:2], w[0][:2]))
        return clean([circ[k]] + w), k

    def mill_place(self, mid):
        m = [m for m in self.leat["mills"] if m["id"] == mid][0]
        sc = sidecar("ser05_mill_v1")
        d = sc["socket_pos"]["SOCK_DOOR_1"]
        mi = sc["socket_pos"]["SOCK_MILLER_1"]
        P = lambda k: list(kit_to_town(m["at"], m["facing"], k)) + [m["level"]]
        door_out, door_far, inside = P((d[0] - 0.6, d[1])), P((d[0] - 2.0, d[1])), P((mi[0], mi[1]))
        out_facing = bearing(P((0.0, d[1])), door_out)
        return m, door_out, inside, out_facing, clean([door_out, door_far] + self.ways[mid])

    # -------------------------------------------------------------------- people
    def members(self, hid, sexes=("m", "f"), lo=15, hi=58, works=WORK):
        hh = self.hh.get(hid)
        if not hh:
            return []
        return [m for m in hh["members"] if m["sex"] in sexes and lo <= m["age"] <= hi and m["work"] in works and m["id"] not in self.used
                and not m.get("named")]

    def go(self, acts, pts, t0, kind, side=0.0, kora=False):
        pts = clean(pts)
        ts = timed(pts, t0, kind)
        a = {"go": pts, "ts": ts, "kind": kind}
        if side:
            a["side"] = side
        if kora:
            a["kora"] = True
        acts.append(a)
        return ts[-1]

    def stay(self, acts, at, facing, clip, t0, t1, **k):
        a = {"stay": [round(at[0], 2), round(at[1], 2), round(at[2], 2)], "facing": round(facing % 360.0, 1), "clip": clip,
             "t0": round(t0, 3), "t1": round(t1, 3)}
        a.update(k)
        acts.append(a)
        return t1

    def add(self, key, member, hid, role, kind, acts, **k):
        rec = {"key": key, "who": member["id"] if member else "", "house": hid, "role": role, "kind": kind, "acts": acts}
        if member and member.get("name"):
            rec["name"] = member["name"]
        rec.update(k)
        if member:
            self.used.add(member["id"])
        self.people.append(rec)
        return rec

    def arrive(self, acts, pts, at_min, kind):
        """A walk timed to end at minute `at_min`."""
        d = timed(clean(pts), 0.0, kind)[-1]
        return self.go(acts, pts, at_min - d, kind)

    def plan(self):
        self.circuit()
        self.threshers()
        self.roofs()
        self.millers()
        self.carriers()
        self.trips()
        self.fields()

    # -------------------------------------------------------------------- the Bön circuit (A-06) and the chapel's lamps
    def circuit(self):
        circ = self.things.get("circuit") or []
        if not circ or "TOD-02" not in self.ways:
            return
        place, k0 = self.chapel_place()
        ring = circ[k0:] + circ[:k0]
        pairs = []
        g_hid = "H-TOD-045"
        gy = [m for m in self.hh[g_hid]["members"] if m.get("named") == "yungdrung_gyaltsen"]
        pairs.append(("yungdrung_gyaltsen", gy[0] if gy else None, g_hid, 332.0))  # 05:32
        best = None  # a woman of another Bön household, the one whose way to the chapel is shortest
        for hid in ("H-TOD-046", "H-TOD-047", "H-TOD-048"):
            hm = self.home(hid)
            if hm is None:
                continue
            L = length(junction(hm, place))
            for m in self.members(hid, sexes=("f",), lo=40, hi=70, works=WORK | {"elder"}):
                if best is None or L < best[0]:
                    best = (L, hid, m)
        if best:
            pairs.append(("tode_woman_b", best[2], best[1], 333.0))
        self.bon = {}
        for key, m, hid, start in pairs:
            hm = self.home(hid)
            to = junction(hm, place)
            acts = []
            self.arrive(acts, to, start, "elder")
            loop = [ring[i % len(ring)] for i in range(len(ring) * 8 + 1)]  # rounds until 06:28
            ts = timed(clean(loop), start, "kora")
            per = (ts[-1] - start) / 8.0
            n = max(1, int((388.0 - start) // per))
            end = self.go(acts, [ring[i % len(ring)] for i in range(len(ring) * n + 1)], start, "kora", kora=True)
            self.go(acts, to[::-1], end + 0.3, "elder")
            rec = self.add(key, m, hid, "the Bön circuit (A-06)", "elder", acts, rounds=n)
            self.bon[key] = rec
        g = self.bon.get("yungdrung_gyaltsen")
        if g:  # 16:00 the chapel's lamps: to its door, its leaves opened, back
            door = kit_to_town(self.td["named"]["TOD-02"]["at"], self.td["named"]["TOD-02"]["facing"], (0.0, -4.3))
            at = [door[0], door[1], self.td["named"]["TOD-02"]["level"]]
            hm = self.home(g_hid)
            to = junction(hm, place) + [at]
            t = self.arrive(g["acts"], to, 959.0, "elder")
            t = self.stay(g["acts"], at, (self.td["named"]["TOD-02"]["facing"] + 180.0), "Interact", t, t + 12.0)
            self.go(g["acts"], to[::-1], t, "elder")  # (from the door: `to` ends there)

    # -------------------------------------------------------------------- threshing (A-44) and winnowing (A-45)
    def threshers(self):
        self.floors = {}
        chodron_hid = "H-TOD-001"
        g = self.bon.get("yungdrung_gyaltsen") if hasattr(self, "bon") else None
        g_floor = None
        if g:  # his nearest floor by the paths, if it is near (else his own roof: roofs)
            hm = self.home("H-TOD-045")
            near = []
            for f in FLOORS:
                if f in self.ways:
                    sp = self.floor_spots(f)[1][0]
                    L = length(junction(hm, self.floor_place(f, sp)))
                    if L <= min(3.0 * math.dist(hm[0][:2], sp[:2]) + 80.0, NEAR):
                        near.append((L, f))
            g_floor = min(near)[1] if near else None
        self.g_floor = g_floor
        for fid in FLOORS:
            if fid not in self.ways:
                continue
            t, spots, face = self.floor_spots(fid)
            crew = []  # [(key, member, hid, sex)]
            if fid == "TOD-13":
                ch = [m for m in self.hh.get(chodron_hid, {"members": []})["members"] if m.get("named") == "chodron_tode"]
                if ch:
                    crew.append(("chodron_tode", ch[0], chodron_hid, "f"))
            if fid == g_floor and g:
                crew.append(("yungdrung_gyaltsen", None, "H-TOD-045", "m"))
            cands = []
            for hid in self.hh:
                hm = self.home(hid)
                if hm is None:
                    continue
                L = length(junction(hm, self.floor_place(fid, spots[0])))
                straight = math.dist(hm[0][:2], spots[0][:2])
                if L > min(3.0 * straight + 80.0, NEAR):  # (a way round the long way, or far: someone nearer goes)
                    continue
                cands.append((L, hid))
            cands.sort()
            want = {"m": 3, "f": 3}
            for key, _, _, sex in crew:
                want[sex] -= 1
            for L, hid in cands:
                took = 0
                for m in sorted(self.members(hid), key=lambda m: m["age"]):
                    if want[m["sex"]] > 0 and took < 2:
                        crew.append((None, m, hid, m["sex"]))
                        want[m["sex"]] -= 1
                        took += 1
                        self.used.add(m["id"])
                if want["m"] <= 0 and want["f"] <= 0:
                    break
            # bodies: no two alike in a line; the line's places shuffled so men and women stand mixed, pairs alternate
            mk = FLOORS.index(fid)
            men = [k for k in MEN]
            women = [k for k in WOMEN if not any(c[0] == k for c in crew)]
            out = []
            mi = wi = 0
            for key, m, hid, sex in crew:
                if key is None:
                    if sex == "m":
                        key = men[(mi + mk) % len(men)]
                        mi += 1
                    else:
                        key = women[(wi + mk) % len(women)]
                        wi += 1
                out.append((key, m, hid, sex))
            men_c = [c for c in out if c[3] == "m"]
            wom_c = [c for c in out if c[3] == "f"]
            line = []
            while men_c or wom_c:  # a man and a woman by turns along the line
                if men_c:
                    line.append(men_c.pop(0))
                if wom_c:
                    line.append(wom_c.pop(0))
            self.floors[fid] = []
            for k, (key, m, hid, sex) in enumerate(line[:6]):
                spot = spots[k]
                place = self.floor_place(fid, spot)
                rec = None
                if key == "yungdrung_gyaltsen":
                    rec = self.bon["yungdrung_gyaltsen"]
                    acts = rec["acts"]
                else:
                    acts = []
                hm = self.home(hid)
                to = junction(hm, place)
                kind = "man" if sex == "m" else "woman"
                if key == "yungdrung_gyaltsen":
                    kind = "elder"
                t = self.arrive(acts, to, 504.0 + k * 0.7, kind)
                ph = round((k % 2) * CHOP / 2.0 + 0.11 * (k // 2), 3)
                if sex == "m":
                    t = self.stay(acts, spot, face, "Chop_Tree", t, 810.0, flail=True, phase=ph)
                    tea = [spot[0] + 0.0, spot[1], spot[2]]
                    t = self.stay(acts, tea, face + 180.0, "Sitting_Idle", 810.0, 830.0)
                    t = self.stay(acts, spot, face, "Chop_Tree", 830.0, 900.0 - k * 0.5, flail=True, phase=ph)
                else:
                    t = self.stay(acts, spot, face, "Chop_Tree", t, 780.0, flail=True, phase=ph)
                    if key == "chodron_tode":  # her day: threshing to 13:30, tea on the roof, winnowing 14:00-16:00
                        t = self.stay(acts, spot, face, "Chop_Tree", 780.0, 810.0, flail=True, phase=ph)
                        t = self.stay(acts, spot, face + 180.0, "Sitting_Idle", 810.0, 840.0)
                        t = self.stay(acts, spot, face + 90.0, "Farm_Harvest", 840.0, 960.0, phase=round(0.37 * k, 3))
                    else:
                        t = self.stay(acts, spot, face + 90.0, "Farm_Harvest", 780.0, 960.0 - k * 0.6, phase=round(0.37 * k, 3))
                self.go(acts, to[::-1], t, kind)
                if rec is None:
                    rec = self.add(key, m, hid, "threshing at %s (A-44)" % fid, kind, acts, floor=fid)
                    if key == "chodron_tode":
                        rec["full_moon"] = 810.0
                        self.chodron = rec
                else:
                    rec["floor"] = fid
                self.floors[fid].append(rec)
        if hasattr(self, "chodron"):  # 17:05-17:30 on her roof, facing the monastery (her day, chapter 05)
            h = self.houses[chodron_hid]
            sc = sidecar(kit_file(h))
            rf = (sc.get("roofs") or [None])[0]
            if rf and "SOCK_HATCH_1" in sc["socket_pos"]:
                x0, y0, x1, y1, z = rf[:5]
                k = ((x0 + x1) / 2 + 1.6, (y0 + y1) / 2 - 0.6)
                x, y = kit_to_town(h["pos"], h["rot_deg"], k)
                at = [x, y, h["pos"][2] + z]
                hatch = list(kit_to_town(h["pos"], h["rot_deg"], sc["socket_pos"]["SOCK_HATCH_1"][:2])) + [at[2]]
                t = self.go(self.chodron["acts"], [hatch, at], 1024.5, "woman")
                t = self.stay(self.chodron["acts"], at, bearing((x, y), TSOKCHEN), "Idle_FoldArms", t, 1050.0)
                self.go(self.chodron["acts"], [at, hatch], t, "woman")

    # -------------------------------------------------------------------- the roofs
    def roof_pair(self, h):
        """Two places 3.4 m apart on a rammed-earth roof, face to face, clear of its hatch, burner, fuel and corners, and
        its hatch."""
        sc = sidecar(kit_file(h))
        rf = (sc.get("roofs") or [None])[0] if sc else None
        if not rf or "SOCK_HATCH_1" not in sc["socket_pos"]:
            return None
        x0, y0, x1, y1, z = rf[:5]
        sp = sc["socket_pos"]
        keep = [sp[k][:2] for k in sp if k.startswith(("SOCK_HATCH", "SOCK_SANG", "SOCK_FUEL", "SOCK_PIER", "SOCK_CORNER", "SOCK_KITCHEN"))]
        rects = rf[6] if len(rf) > 6 else []  # the roof's obstacles: its piers, its gallery, its rack (../tibet-blender kit/tode.py)
        off = lambda q, r: math.hypot(max(r[0] - q[0], 0.0, q[0] - r[2]), max(r[1] - q[1], 0.0, q[1] - r[3]))
        ok = lambda q, d: all(math.dist(q, k) > d for k in keep) and all(off(q, r) > d - 0.4 for r in rects)
        best = None  # (the pair with the most room from the gallery and the rack, which stand 2.3 and 3.8 m tall)
        room = lambda q: min([off(q, r) for r in rects] + [9.0])
        for yy in np.arange(y0 + 1.2, y1 - 1.2, 0.25):
            for xa in np.arange(x0 + 1.2, x1 - 1.2 - 3.4, 0.25):
                a, b = (xa, yy), (xa + 3.4, yy)
                if ok(a, 1.4) and ok(b, 1.4) and ok(((a[0] + b[0]) / 2, yy), 1.2):
                    sc_ = min(room(a), room(b)) - 0.05 * (yy - y0)
                    if best is None or sc_ > best[2]:
                        best = (a, b, sc_)
        if best is None:
            return None
        lv = h["pos"][2] + z
        A = list(kit_to_town(h["pos"], h["rot_deg"], best[0])) + [lv]
        B = list(kit_to_town(h["pos"], h["rot_deg"], best[1])) + [lv]
        H = list(kit_to_town(h["pos"], h["rot_deg"], sp["SOCK_HATCH_1"][:2])) + [lv]
        return A, B, H

    def roofs(self):
        """Two threshing face to face on ROOFS rammed-earth roofs near the tower (V-12 looks over them), each up through the
        hatch to her place and down again; Gyaltsen on his own roof with a woman of his house when no floor is near him."""
        tower = self.td["named"].get("TOD-01", {"at": [-180.0, 430.0]})["at"]
        ds = sorted((h for h in self.td["houses"] if h["type"] == "D"), key=lambda h: math.dist(h["pos"][:2], tower))
        g = self.bon.get("yungdrung_gyaltsen") if getattr(self, "bon", None) and not getattr(self, "g_floor", None) else None
        if g:
            ds = [self.houses["H-TOD-045"]] + [h for h in ds if h["id"] != "H-TOD-045"]
        n = 0
        self.roof_pairs = []
        for h in ds:
            if n >= ROOFS + (1 if g else 0):
                break
            ws = self.members(h["id"], sexes=("f",), lo=15, hi=60)
            pair = self.roof_pair(h)
            if pair is None:
                continue
            bodies = [WOMEN[(2 * n + 1) % len(WOMEN)], WOMEN[(2 * n + 2) % len(WOMEN)]]
            if g and h["id"] == "H-TOD-045":
                if not ws:
                    continue
                crew = [("yungdrung_gyaltsen", None, g, 485.0, 840.0), (bodies[1], ws[0], None, 487.0, 870.0)]
            else:
                if len(ws) < 2:
                    continue
                crew = [(bodies[0], ws[0], None, 520.0 + 3.0 * n, 870.0), (bodies[1], ws[1], None, 520.8 + 3.0 * n, 870.0)]
            A, B, H = pair
            mid = [(A[0] + B[0]) / 2, (A[1] + B[1]) / 2, A[2]]
            for k, ((key, m, rec, t0, t1), at, other) in enumerate(zip(crew, (A, B), (B, A))):
                acts = rec["acts"] if rec else []
                kind = "elder" if key == "yungdrung_gyaltsen" else "woman"
                t = self.go(acts, [H, at], t0 - 0.4, kind)
                t = self.stay(acts, at, bearing(at, other), "Chop_Tree", t, t1, flail=True, phase=round(k * CHOP / 2.0, 3))
                if key != "yungdrung_gyaltsen":
                    side = [mid[0] + (at[0] - mid[0]) * 0.25, mid[1] + (at[1] - mid[1]) * 0.25, mid[2]]
                    t = self.go(acts, [at, side], t, kind)
                    t = self.stay(acts, side, bearing(at, other) + 90.0 * (1 if k else -1), "Farm_Harvest", t, 925.0 + 2.0 * k, phase=round(0.6 * k, 3))
                    self.go(acts, [side, H], t, kind)
                    self.add(key, m, h["id"], "threshing on the roof (A-44)", "woman", acts, roof=True)
                else:
                    self.go(acts, [at, H], t, kind)
                    rec["roof"] = True
            self.roof_pairs.append(h["id"])
            n += 1

    # -------------------------------------------------------------------- the millers
    def millers(self):
        self.mill_men = {}
        for mid, key in MILLERS.items():
            if mid not in self.ways:
                continue
            m, door_out, inside, out_facing, place = self.mill_place(mid)
            best = None
            for hid in self.hh:
                hm = self.home(hid)
                if hm is None:
                    continue
                ms = self.members(hid, sexes=("m",), lo=30, hi=66, works=WORK | {"elder"})
                if not ms:
                    continue
                L = length(junction(hm, place))
                if best is None or L < best[0]:
                    best = (L, hid, ms[-1])
            if best is None:
                continue
            L, hid, mem = best
            to = junction(self.home(hid), place)
            acts = []
            t = self.arrive(acts, to, 420.0, "man")  # 07:00
            while t < 1050.0 - 1.0:  # by turns in the doorway and inside by the stones until 17:30, walking between
                t = self.stay(acts, door_out, out_facing, "Idle_FoldArms" if int(t // 40) % 2 else "Idle_A", t, min(1050.0, t + 18.0))
                if t >= 1050.0 - 1.0:
                    break
                t = self.go(acts, [door_out, inside], t, "man")
                t = self.stay(acts, inside, out_facing + 180.0, "Interact", t, min(1050.0, t + 24.0))
                t = self.go(acts, [inside, door_out], t, "man")
            self.go(acts, to[::-1], t, "man")
            self.add(key, mem, hid, "the miller at %s" % mid, "man", acts, mill=mid)
            self.mill_men[mid] = hid

    # -------------------------------------------------------------------- the water carriers (the leat)
    def carriers(self):
        culs = self.leat.get("culverts", [])
        taken = []
        n = 0
        for hid in sorted(self.hh, key=lambda h: h):
            if n >= len(CARRIERS):
                break
            hm = self.home(hid)
            if hm is None:
                continue
            hit = None
            for ci, c in enumerate(culs):
                if ci in taken:
                    continue
                for i in range(len(hm) - 1):
                    a, b = hm[i], hm[i + 1]
                    ab = (b[0] - a[0], b[1] - a[1])
                    L2 = ab[0] ** 2 + ab[1] ** 2
                    if L2 < 1e-6:
                        continue
                    f = max(0.0, min(1.0, ((c["at"][0] - a[0]) * ab[0] + (c["at"][1] - a[1]) * ab[1]) / L2))
                    q = (a[0] + ab[0] * f, a[1] + ab[1] * f)
                    if math.dist(q, c["at"]) < 1.2 and i >= 2:
                        hit = (ci, i, q)
                        break
                if hit:
                    break
            if not hit:
                continue
            ms = [m for m in self.hh[hid]["members"] if m["work"] == "water carrier" and m["id"] not in self.used] or \
                self.members(hid, sexes=("f",), lo=12, hi=55)
            if not ms:
                continue
            ci, i, q = hit
            c = culs[ci]
            ld = c["leat_dir"]
            fill = [c["at"][0] - ld[0] * 0.75, c["at"][1] - ld[1] * 0.75, c["road"]]
            to = hm[:i + 1] + [[q[0], q[1], c["road"]], fill]
            acts = []
            for t0 in (412.0 + 9.0 * n, 952.0 + 7.0 * n):  # about 07:00 and 16:00
                t = self.go(acts, to, t0, "woman")
                t = self.stay(acts, fill, bearing(c["at"], (c["at"][0] - ld[0], c["at"][1] - ld[1])), "Crouch_Idle", t, t + FILL)
                self.go(acts, to[::-1], t, "laden")
            self.add(CARRIERS[n], ms[0], hid, "water from the leat (A-47)", "woman", acts, culvert=ci)
            taken.append(ci)
            n += 1

    # -------------------------------------------------------------------- down to Shöl and back
    def trips(self):
        walk = self.stair["walk"]  # (the foot up to the top)
        down = walk[::-1] + [[FORECOURT[0], FORECOURT[1], walk[0][2]]]
        n = 0
        works = {"trader", "porter", "carpenter"}
        for hid in sorted(self.hh, key=lambda h: length(self.ways[h]) if h in self.ways else 1e9):  # (the nearest the stair's top)
            if n >= len(TRIPS):
                break
            key, sex = TRIPS[n]
            ms = self.members(hid, sexes=(sex,), lo=18, hi=55, works=works)
            hm = self.home(hid)
            if not ms or hm is None:
                continue
            to = hm + down[1:]
            acts = []
            self.go(acts, to, 462.0 + 23.0 * n, "laden" if key.startswith("porter") else ("man" if sex == "m" else "woman"))
            self.go(acts, to[::-1], 905.0 + 27.0 * n, "laden" if key.startswith("porter") else ("man" if sex == "m" else "woman"))
            self.add(key, ms[0], hid, "down to Shöl and back", "man" if sex == "m" else "woman", acts)
            n += 1

    # -------------------------------------------------------------------- in the fields
    def fields(self):
        pads = [(h["pad"], h["rot_deg"]) for h in self.td["houses"]]
        pads += [((n.get("pad") or [n["at"][0], n["at"][1]] + n["footprint"]), n["facing"]) for n in self.td["named"].values()]
        lanes = self.td["lanes"]

        def clear(x, y):
            for (px, py, pw, pd), rot in pads:
                th = math.radians(rot)
                u = (math.sin(th), math.cos(th))
                r = (x - px, y - py)
                if abs(r[0] * u[0] + r[1] * u[1]) < pd / 2 + 4.0 and abs(-r[0] * u[1] + r[1] * u[0]) < pw / 2 + 4.0:
                    return False
            for ln in lanes:
                fx, fy = ln["from"]
                dx, dy = ln["dir"]
                s = (x - fx) * dx + (y - fy) * dy
                if -2.0 <= s <= ln["length"] + 2.0 and abs(-(x - fx) * dy + (y - fy) * dx) < ln["width"] / 2 + 2.5:
                    return False
            return True

        n = 0
        for hid in sorted(self.hh):
            if n >= len(FIELD):
                break
            hm = self.home(hid)
            ms = self.members(hid, sexes=("f",) if FIELD[n].startswith("tode_woman") else ("m",), lo=18, hi=60)
            if hm is None or not ms or len(hm) < 8:
                continue
            spot = None
            for i in range(3, min(len(hm) - 1, 12)):
                a, b = hm[i], hm[i + 1]
                L = math.dist(a[:2], b[:2])
                if L < 1.0:
                    continue
                ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
                for off in (5.0, -5.0, 7.0, -7.0):
                    x, y = (a[0] + b[0]) / 2 - uy * off, (a[1] + b[1]) / 2 + ux * off
                    z = self.Z(x, y)
                    sl = math.hypot(self.Z(x + 1, y) - self.Z(x - 1, y), self.Z(x, y + 1) - self.Z(x, y - 1)) / 2.0
                    if sl < 0.45 and clear(x, y) and abs(z - (a[2] + b[2]) / 2) < 2.5:
                        spot = (i, [x, y, z])
                        break
                if spot:
                    break
            if not spot:
                continue
            i, s = spot
            mid = [(hm[i][0] + hm[i + 1][0]) / 2, (hm[i][1] + hm[i + 1][1]) / 2, (hm[i][2] + hm[i + 1][2]) / 2]
            to = hm[:i + 1] + [mid, s]
            acts = []
            key = FIELD[n]
            t = self.go(acts, to, 565.0 + 11.0 * n, "woman" if key.startswith("tode_woman") else "man")
            t = self.stay(acts, s, bearing(s, mid) + 120.0, "Farm_Harvest", t, 750.0, phase=round(0.8 * n, 3))
            self.go(acts, to[::-1], t, "woman" if key.startswith("tode_woman") else "man")
            self.add(key, ms[0], hid, "in the fields", "woman" if key.startswith("tode_woman") else "man", acts)
            n += 1


def out_at(p, m):
    for a in p["acts"]:
        if "go" in a and a["ts"][0] <= m < a["ts"][-1]:
            return True
        if "stay" in a and a["t0"] <= m < a["t1"]:
            return True
    return False


def main():
    pl = Plan()
    pl.plan()
    people = pl.people
    for p in people:  # no one in two places at once
        spans = sorted([(a["ts"][0], a["ts"][-1]) if "go" in a else (a["t0"], a["t1"]) for a in p["acts"]])
        for (a0, a1), (b0, b1) in zip(spans, spans[1:]):
            if b0 < a1 - 0.01:
                print("tode_days: WARNING: %s (%s) at %02d:%02d is still in an act ending %02d:%02d" % (p.get("name") or p["who"], p["role"], int(b0 // 60), int(b0 % 60),
                                                                                                   int(a1 // 60), int(a1 % 60)))
    json.dump({"about": "Tödé's people (tools/town/tode_days.py; M3 sprint 4, step 6): each {key (its body: assets/generated/people/<key>.glb), who (data/population.json's member), name, house, role, kind (its pace), acts}, an act {go: points [x, y, z] in the town grid, ts: the game minute at each, kind, side, kora: turning the wheels it passes} or {stay: [x, y, z], facing (a bearing), clip, t0, t1, flail: a flail in the hands, phase: seconds into its clip}; `full_moon`: not out after that minute on the full moon. Drawn by world/tode_people.gd. Regenerated with the terrain.",
               "people": people}, open(OUT, "w", encoding="utf-8"), indent=0)
    by_role = {}
    for p in people:
        r = p["role"].split(" at ")[0] if p["role"].startswith("threshing at") else p["role"]
        by_role[r] = by_role.get(r, 0) + 1
    rep = ["# Tödé's people", "",
           "_Written by `tools/town/tode_days.py` (M3 sprint 4, step 6) from `data/population.json`'s Tödé households, the field paths' ways (`data/tode.json`), the threshing floors and R-24 (`data/tode_things.json`), the leat's culverts and mills (`data/tode_leat.json`) and the Tödé Stair (`data/tode_stair.json`); drawn by `world/tode_people.gd`._", "",
           "- %d people out of doors in the day: %s." % (len(people), ", ".join("%s %d" % kv for kv in by_role.items())),
           "- The Bön circuit (A-06): %s." % ", ".join("%s of %s, %d rounds from %02d:%02d" % (p.get("name") or p["key"], p["house"], p.get("rounds", 0), int(p["acts"][1]["ts"][0] // 60), int(p["acts"][1]["ts"][0] % 60))
                                                for p in people if p["role"].startswith("the Bön circuit")),
           "- The threshing floors (A-44, A-45): %s." % "; ".join("%s: %s" % (f, ", ".join("%s (%s)" % (r.get("name") or r["key"], r["house"]) for r in rs)) for f, rs in pl.floors.items()),
           "- On the roofs: %s; the millers: %s; the water carriers' culverts: %s." % (
               ", ".join(pl.roof_pairs), ", ".join("%s from %s" % kv for kv in pl.mill_men.items()),
               ", ".join("%d" % p["culvert"] for p in people if "culvert" in p)), "",
           "Out of doors by the hour:", "", "| Hour | " + " | ".join("%02d" % h for h in range(5, 20)) + " |", "|---|" + "---|" * 15,
           "| Out | " + " | ".join("%d" % sum(1 for p in people if out_at(p, h * 60 + 30)) for h in range(5, 20)) + " |", "",
           "| Who | Body | House | Role | Out | Way (m) |", "|---|---|---|---|---|---|"]
    for p in people:
        ws = [a for a in p["acts"] if "go" in a]
        first = min([a["ts"][0] for a in ws] + [a["t0"] for a in p["acts"] if "stay" in a])
        last = max([a["ts"][-1] for a in ws] + [a["t1"] for a in p["acts"] if "stay" in a])
        rep.append("| %s | %s | %s | %s | %02d:%02d-%02d:%02d | %.0f |" % (p.get("name") or p["who"], p["key"], p["house"], p["role"], int(first // 60), int(first % 60),
                                                                       int(last // 60), int(last % 60), max([length(a["go"]) for a in ws] or [0.0])))
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("tode_days: %d people (%s) -> %s" % (len(people), ", ".join("%s %d" % kv for kv in by_role.items()), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
