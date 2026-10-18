#!/usr/bin/env python3
"""The street graph (plan chapter 11, 12.3-12.4; M1 sprint 4, step 4) and the first walkers' routes on it, into
assets/generated/terrain/street_graph.json for TownSim (autoload/town_sim.gd), and docs/town/street-graph-report.md.

The graph, over the slice (Tsongra, Dechen-tsang, lower and upper Shöl, the Mani quarter, the Sky Stair to its top):
- the ground on a 1 m lattice of the Rooftop Way's model of the game's ground (tools/town/rooftop.py's Ground: 0.5 m
  cells on Terrain3D's whole-metre lattice, walkable off every building by the walker's 0.35 m, off the brink of a
  drop, 30 degrees at most cell to cell), each point joined to its eight neighbours; an edge's time is its length at
  the level pace (PACE) slowed or quickened by its slope (Tobler's hiking function), half as long again on open hillside
  (the town's ground is within 4.5 m of a building or in a lane) and twice on a facet steeper than 45 degrees;
- the flights, each one edge timed by its steps (0.75 s a step up, 0.5 s down: chapter 05, 9.7): the Sky Stair's, on
  its axis from its foot to its top by the kit's plan, its sides closed by its cheeks but for its foot (the talkers'
  steps up from Tsongra's upper level), its top and the gap in its east cheek onto the Mani Lhakhang's forecourt;
  Tsongra's steps between its two levels; the side lanes' flights;
- the Mani Lane's edges one way: east on the mani wall's north side, west on its south, north past its west end and
  south past its east (chapter 05, 9.4: a Buddhist walker never passes a holy thing on the left);
- the anchors: the doors of the houses (the kit's SOCK_DOOR a metre and a bit out, on the ground: a town house's is on
  its first floor, up an outside stair not yet walkable), the workshops' doors, the headman's and Dechen-tsang's gates,
  Tsongra's two levels, its basin and its fuel stalls, the Mani Lhakhang's door (and in, round the great wheel: WHEEL),
  the mani wall's west end (and round it: MANI), the Sky Stair's top.
The walkers (twenty, spike S5 for twenty): each a home and a default day (M1 sprint 6, step 1; chapter 05, 7.2 and
8.1; IMP-017): the places it is to be at by clock times and until when, doing what (standing, indoors, round the great
wheel, round the mani wall), drawn with a fixed seed and spaced by the fastest routes' times at its own pace and the
clock's 6:1 (TownSim works each departure back from its arrival, chapter 12's "schedules as arrival times"): the elders
to the barkor by lamplight, errands and the market in the morning, most home at midday, errands, the Mani Lhakhang and
the kora in the afternoon, home for the roof sang at dusk, some round the wall at the kora's busiest, supper, a few out
again after it, home for the night. Their routes are the fastest through the graph, string-pulled clear 0.3 m either
side (and the Mani Lane's way kept), and sampled every metre on the game's ground. Roofs, ladders and hatches are not in
it yet: the walkers are adults, who keep off strangers' roofs (chapter 05, 9.7).
The named eight (M1 sprint 6, step 3; chapter 05, 4.2): their days as written in data/named_days.json, walkers like the
twenty but for their own bodies (their kind is their key) and their seats: where at a place each one's feet go, which
way it faces and how it rests there (standing, sitting on a ledge, crouched), worked out here from the kit (the
talkers' steps' treads, Pasang's seat block, Dechen-tsang's gateway, a house's door, the fuel stalls' counters) and the
sitting clip's own shape (the seat about 0.45 m up and 0.3 m behind the feet), so the game only walks them there.
The twelve generic (sprint 6, step 4; data/generic_days.json) walk the same way, each with its own figure, a home near a
place (the nearest house door no other of them has) and seats also at a spot off a place's anchor.
Run: tools/py tools/town/graph.py   (tools/terrain/build.sh runs it after rooftop.py)
"""
import json
import math
import os
import random
import sys
import zlib

import numpy as np
from scipy.sparse import csr_matrix
from scipy.sparse.csgraph import connected_components, dijkstra

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
from terrain_site import Site  # noqa: E402
import builder as B  # noqa: E402  (rect)
import ladders as LD  # noqa: E402  (kit_file)
import pads as P  # noqa: E402  (BARKOR, lane_list)
import rooftop as R  # noqa: E402  (Ground, simplify)

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
KIT = os.path.join(ROOT, "assets", "generated", "kit", "types")
OUT = os.path.join(GEN, "street_graph.json")
REPORT = os.path.join(ROOT, "docs", "town", "street-graph-report.md")
BOX = (-150.0, -112.0, 80.0, 264.0)  # x0, y0, x1, y1 in the town grid: the slice (from -95 until sprint 6, step 5
# took in Samkha's north ramp below the Yak Gate), whose house doors the twenty walkers' homes are drawn from
GROUND_BOX = (-470.0, -150.0, 270.0, 264.0)  # the walkers' ground (M2 sprint 6, step 2; IMP-030): the slice, the west edge
# (SHL-37, round x -300), the ngakpa quarter round Pema Ö (SHL-36, to x 220) and the garden lane to the Gorge Rim
# Lookout on the gorge's rim (x 258; step 4); and Hejie inside its wall, River Street from gate to gate (M2 sprint 10,
# step 3: x -462 to -214, y -142 to 12)
HEJIE = os.path.join(ROOT, "data", "hejie.json")  # Hejie's houses and named buildings' kit types (tools/town/hejie.py)
RAMP_KIT = {"SAM-08": "sam08_stables_v1", "SAM-09": "sam09_ula_yard_v1"}  # the Castle Ramp's yards' kit types (world/town.gd NAMED)
MARKET = os.path.join(ROOT, "data", "market.json")  # Tsongra's market's stalls, keepers and hours (tools/town/market.py; step 4)
STALL_SIZE = {"stall_sh03": (2.0, 1.9), "stall_sh04": (2.7, 2.2)}  # a stall's ground, across and deep, with its keeper behind
STALL_KEEPER = {"stall_sh03": 0.85, "stall_sh04": 0.7}  # its keeper's place behind it (the kit's STALL socket)
MARKET_PLACES = []  # the stalls' fronts on the graph, for the buyers' "market" errand (set by main)
MARKET_UNTIL = 11.6 * 60  # no one goes to buy after the market packs up (11:43)
PEOPLE = os.path.join(ROOT, "assets", "generated", "people")  # the bodies' VAT bakes: which clips a figure has


def keeping(keeper_of, who, kind, keeps):
    """A keeper's stall, its seat and the market's hours for TownSim's day, or None: behind a ground stall (SH-03) it
    sits cross-legged where its figure has the sit baked (people2/body.py), else it stands (M2 sprint 10, step 4)."""
    if who not in keeper_of:
        return None
    place, seat, kit = keeper_of[who]
    vat = os.path.join(PEOPLE, kind + "_vat.json")
    if kit == "stall_sh03" and os.path.exists(vat) and "Sitting_Cross" in json.load(open(vat))["clips"]:
        seat = dict(seat, pose="cross")
    return (place, seat) + tuple(k_ * 60.0 for k_ in keeps)
HEJIE_PLACES = {  # Hejie's places on River Street (the town grid) and its named buildings' doors used as places
    "east_gate_in": (-223.0, -80.9), "water_gate_in": (-451.0, -94.5), "river_street": (-338.0, -88.5), "hejie_square": (-232.0, -79.0),
    "east_gate_out": (-205.0, -80.0)}
HEJIE_STAY = {"HEJ-14": ((20, 60), "inside"), "HEJ-08": ((10, 30), "stand"), "HEJ-05": ((20, 60), "stand"), "HEJ-13": ((15, 40), "inside"),
              "HEJ-10": ((10, 30), "stand"), "river_street": ((15, 45), "stand"), "hejie_square": ((10, 40), "stand"),
              "water_gate_in": ((10, 30), "stand"), "east_gate_in": ((10, 30), "stand")}
HEJIE_DAY = {  # Hejie's own drawn by archetype (chapter 05, 7.2: the dawn drum and the gates at 05:30, shop boards down, incense
    # at the shop gods at 06:00, market day on River Street, the teahouse full at noon, the gates shut at the first watch,
    # 19:00, the storyteller at the teahouse from 19:30): first out, home by, the errands' weights, home at noon, the
    # stay at home's door (a shopkeeper at his counter), out in the evening
    "HM": {"out": (5.4, 6.0), "back": (18.6, 19.2), "w": {"HEJ-14": 2.0, "HEJ-08": 1.0, "river_street": 2.0, "HEJ-05": 0.5, "hejie_square": 1.0, "water_gate_in": 0.5},
           "noon": 0.3, "door": 0.6, "eve": 0.3},
    "HP": {"out": (5.6, 6.2), "back": (17.6, 18.6), "w": {"water_gate_in": 3.0, "east_gate_in": 2.0, "HEJ-10": 2.0, "HEJ-13": 1.0, "river_street": 1.0, "HEJ-14": 1.0},
           "noon": 0.4, "door": 0.1, "eve": 0.2},
    "HW": {"out": (6.0, 7.0), "back": (17.2, 18.0), "w": {"river_street": 3.0, "water_gate_in": 2.0, "HEJ-08": 0.5, "hejie_square": 1.0},
           "noon": 0.8, "door": 0.3, "eve": 0.05},
    "HC": {"out": (6.5, 7.5), "back": (17.4, 18.2), "w": {"river_street": 3.0, "hejie_square": 2.0, "water_gate_in": 2.0, "east_gate_in": 1.0},
           "noon": 0.7, "door": 0.1, "eve": 0.05},
    "QS": {"out": (5.4, 6.0), "back": (18.8, 19.2), "w": {"east_gate_in": 3.0, "water_gate_in": 3.0, "HEJ-05": 2.0, "HEJ-14": 1.0},
           "noon": 0.3, "door": 0.0, "eve": 0.2},
    "HU": {"out": (5.6, 6.4), "back": (17.0, 17.4), "w": {"river_street": 2.0, "hejie_square": 1.0, "water_gate_in": 1.0},
           "noon": 0.8, "door": 0.6, "eve": 0.0},
}
# Samkha's places (M2 sprint 11, step 5; the town grid): the castle's ward between its tower and its north wall, outside
# its gate, the Castle Ramp's head, Castle Lane, before the poor houses under the ward's wall, the ula yard, the ramp's
# first switchback
SAMKHA_PLACES = {"samkha_ward": (-126.0, -72.5), "castle_gate": (-107.0, -71.0), "ramp_head": (-109.5, -60.5),
                 "castle_lane": (-130.5, -33.3), "samkha_poor": (-135.0, -58.5), "ula_yard": (-178.0, 3.0), "ramp_landing1": (-205.5, -6.0),
                 "castle_door": (-130.0, -75.6), "court_wait": (-135.5, -75.0)}  # (the foot of the steps up into the castle's
# passage, where its people go in and the court's parties go up to the hall; the parties' waiting place beside them,
# under the hall's west window)
SAMKHA_STAY = {"samkha_ward": ((20, 60), "stand"), "castle_gate": ((10, 30), "stand"), "ramp_head": ((5, 15), "stand"),
               "castle_door": ((20, 60), "inside"), "court_wait": ((10, 40), "stand"),
               "castle_lane": ((10, 35), "stand"), "samkha_poor": ((10, 30), "stand"), "ula_yard": ((20, 60), "stand"),
               "ramp_landing1": ((5, 15), "stand"), "east_gate_out": ((10, 25), "stand"), "yak_gate": ((10, 25), "stand")}
SAMKHA_DAY = {  # Samkha's own drawn by archetype (chapter 02, D04: the castle household's retainers, grooms and servants;
    # chapter 05, 8.1: 12 outdoors at 11:00): first out, home by, the errands' weights (the retainers at the castle's
    # service in its ward and at its gate, the grooms at the ula yard, down the ramp to Hejie or out by the Yak Gate on an
    # errand; the women in Castle Lane and to the castle's kitchens; the children about the lane and the yard), home at
    # noon, the stay at their door, out in the evening
    "TM": {"out": (6.0, 6.8), "back": (18.0, 19.0), "w": {"samkha_ward": 3.0, "ula_yard": 2.0, "castle_gate": 1.5, "castle_lane": 1.0,
           "ramp_head": 0.5, "east_gate_out": 0.5, "yak_gate": 0.5}, "noon": 0.5, "door": 0.3, "eve": 0.1},
    "TW": {"out": (6.0, 7.0), "back": (17.5, 18.5), "w": {"castle_lane": 2.0, "samkha_ward": 1.5, "castle_gate": 1.0, "samkha_poor": 0.5,
           "ula_yard": 0.3}, "noon": 0.8, "door": 0.5, "eve": 0.05},
    "TE": {"out": (7.0, 8.0), "back": (16.5, 17.5), "w": {"castle_lane": 2.0, "samkha_ward": 1.0, "castle_gate": 1.0},
           "noon": 0.8, "door": 0.7, "eve": 0.0},
    "TB": {"out": (7.0, 8.0), "back": (17.0, 18.0), "w": {"castle_lane": 2.0, "ramp_head": 1.0, "ula_yard": 1.0, "samkha_ward": 0.5,
           "ramp_landing1": 0.5}, "noon": 0.7, "door": 0.2, "eve": 0.0},
}
SAMKHA_DAY["TG"] = SAMKHA_DAY["TB"]
CELL = R.CELL
PACE = 1.1  # m/s on the level, the reference (chapter 05, 9.4: adults 0.9-1.2)
UP, DOWN = 0.75, 0.5  # seconds a step (chapter 05, 9.7), the reference
OPEN, STEEP = 1.5, 2.0  # time factors: open hillside, a facet over 45 degrees
STAIR_Z = 2665.0  # world/town.gd SKY_STAIR: the stair's foot
STAIR_OPEN = 82.0  # along the stair, the middle of the gap in its east cheek (../tibet-blender export_types.py: 81-83)
TALKERS = (6.4, 3.0, 15, 20.0)  # the talkers' steps (world/town.gd IN_STAIR_FRAME): run to the stair's foot, rise, steps, width
TSONGRA = ((0.0, -3.4), 2660.0, 3.4, 2.0, 10, 12.0)  # Tsongra's steps (world/town.gd TSONGRA_STEPS): foot, z, run, rise, steps, width
OPEN_TYPES = ("square", "covered passage", "covered bridge", "pitch", "stalls", "steps", "flagpole", "lookout")  # not in the
# way (the Gorge Rim Lookout's terrace is open ground, its footprint at chapter 02's point across the garden lane: M2 sprint 6)
WALKERS = 20
SEED = 1903
RATE = 0.1  # game minutes a real second at the clock's 6:1 (autoload/world_clock.gd RATE_PLAY)
DAY = {  # the default day's errands (chapter 05, 7.2): weights in the morning, the afternoon and the evening; the stay
    # (game minutes); how: standing, indoors, round the great wheel, round the mani wall (loops of it)
    "basin": ((3.0, 0.5, 0.0), (6, 16), "stand"), "stalls": ((2.0, 1.0, 0.0), (10, 30), "stand"),
    "tsongra": ((4.0, 2.0, 2.0), (20, 70), "stand"), "tsongra_lower": ((2.0, 1.0, 0.5), (15, 45), "stand"),
    "turner": ((1.0, 1.5, 0.0), (15, 50), "stand"), "saddler": ((1.0, 1.5, 0.0), (15, 50), "stand"),
    "tailor": ((1.0, 1.5, 0.0), (15, 50), "stand"), "headman": ((0.5, 0.5, 0.2), (30, 90), "inside"),
    "dechen": ((1.0, 1.0, 1.0), (30, 120), "inside"), "lhakhang": ((1.0, 2.0, 0.5), (1, 4), "wheel"),
    "mani": ((0.5, 2.0, 2.0), (1, 3), "mani"), "stair_top": ((0.5, 1.5, 0.5), (10, 30), "stand"),
    "visit": ((1.0, 1.5, 3.0), (30, 100), "inside"),
}
WHEEL_MIN = 5.0  # in at the Mani Lhakhang's door, twice round the great wheel and out, about 50 s: game minutes
NAMED_DAYS = os.path.join(ROOT, "data", "named_days.json")  # the named eight's days (sprint 6, step 3)
ROSTER = os.path.join(ROOT, "data", "roster.json")  # the day's drawn (tools/town/roster.py; M2 sprint 10, step 2)
UNDRAWN = ("TT", "NU")  # a toddler is carried (drawn as part of its carrier: chapter 05, 2.3); a nun has no figure yet
VISITED = 30  # the drawn's visits, readings and calls go to this many of their houses, not every door (the routes' count)
BODIES = {  # the day's drawn walkers' figures by archetype and sex (people2/body.py's bodies with a VAT bake): several a kind
    ("TM", "m"): ["townsman", "townsman_b", "porter", "stall_man", "house_man"],
    ("TW", "f"): ["townswoman", "townswoman_b", "porter_woman", "stall_woman", "water_woman", "water_woman_b", "water_woman_c", "water_woman_d", "house_mother"],
    ("TE", "m"): ["elder_man"], ("TE", "f"): ["elder_woman", "house_grandmother", "lookout_woman"],
    ("TB", "m"): ["boy"], ("TG", "f"): ["girl", "water_girl", "water_girl_b"], ("NG", "m"): ["ngakpa_man", "ngakpa_man_b"],
    ("MK", "m"): ["monk"], ("MN", "m"): ["novice", "novice_b"], ("MP", "m"): ["pema_monk", "pema_monk_b"],
    ("HM", "m"): ["han_man", "hejie_trader"], ("HP", "m"): ["pieman", "han_man"], ("HW", "f"): ["townswoman", "townswoman_b"],
    ("HC", "m"): ["boy"], ("HC", "f"): ["girl"], ("QS", "m"): ["post_soldier", "post_soldier_b"], ("HU", "m"): ["han_man"],
    ("CV", "m"): ["drover", "drover_b"], ("CV", "f"): ["nomad_woman", "porter_woman"], ("NM", "m"): ["drover", "drover_b"],
    ("NW", "f"): ["nomad_woman"], ("PL", "m"): ["elder_man"], ("PL", "f"): ["elder_woman"], ("BP", "m"): ["elder_man", "porter"],
    ("BP", "f"): ["elder_woman", "poor_grandmother"],
    ("TM", "f"): ["townswoman"], ("TW", "m"): ["townsman"], ("TB", "f"): ["girl"], ("TG", "m"): ["boy"], ("HW", "m"): ["han_man"],
}
TOWN_FOUR = ("townsman", "townswoman", "townsman_b", "townswoman_b")  # people2/body.py TOWN: the town's clips, no cross-legged sit
VISITS = {  # those who come into Shöl (tools/town/roster.py): (out at, back by, in hours; the errands' weights)
    "market": ((7.0, 9.6), (14.4, 16.0), {"tsongra": 2.0, "market": 8.0, "stalls": 2.0, "tsongra_lower": 2.0, "basin": 1.0, "dechen": 2.0, "turner": 1.0,
                                           "saddler": 1.0, "tailor": 1.0, "lhakhang": 1.0, "mani": 1.0, "chang": 0.8, "visit": 2.0, "river_street": 1.0}),
    "lodger": ((5.4, 6.6), (17.4, 19.5), {"dechen": 3.0, "tsongra": 3.0, "turner": 1.0, "saddler": 1.5, "tailor": 1.0, "stalls": 1.0, "chang": 1.5,
                                          "headman": 0.5, "lhakhang": 0.5}),
    "monk": ((8.4, 9.5), (15.6, 16.6), {"visit": 4.0, "lhakhang": 1.0, "mani": 1.0, "tsongra": 0.5}),
    "pilgrim": ((5.8, 7.5), (18.0, 18.6), {"mani": 4.0, "lhakhang": 3.0, "stair_top": 1.0, "pema_o": 1.0, "tsongra": 0.5}),
    "beggar": ((6.5, 8.0), (17.8, 18.4), {"tsongra": 3.0, "stalls": 2.0, "mani": 2.0, "basin": 1.0, "dechen": 1.0}),
    "nomad": ((7.5, 9.0), (14.8, 15.8), {"tsongra": 3.0, "market": 2.0, "stalls": 3.0, "dechen": 1.5, "mani": 1.0, "lhakhang": 0.5}),
}
GENERIC_DAYS = os.path.join(ROOT, "data", "generic_days.json")  # the twelve generic's (sprint 6, step 4)
ENTER_TOWN = {"SHL-24": ("chang", 2)}  # the gazetteer's buildings to enter: their place's name and their carved B2's seed (world/town.gd's, from its hash of the id; test_chang.gd checks it)
CROSS_HIPS = 0.40  # the cross-legged sit (the bodies' Sitting_Cross, the library's Meditate; ISS-088): its hips 0.4 m
# behind its root, 5 cm over it: on a bench's SEAT (its front edge) the root at the edge puts the hips 0.4 m in
SIT_BACK, SIT_DROP = 0.30, 0.43  # the sitting clip: its seat 0.3 m behind the feet and about 0.45 m over them (Sitting_Idle
# on the MPFB bodies, hips 0.9 m: measured 26 Sep 2026); dropped 2 cm less, so a 0.4 m ledge leaves the soles 2 cm in the
# step below and the seat 3 cm over its own


def plan_day(rng, wk, homes, trav, loop_min):
    """One walker's default day: [place, arrive, leave, how, loops] in game minutes from midnight, spaced by `trav(a, b)`
    (game minutes at its pace, or None). Home until it wakes (the elders before dawn to the barkor by lamplight), the
    morning's errands until about 11:00 (a monk reads in a lay house, R-04), home at midday for most, the afternoon's
    until dusk, home for the roof sang at 17:00-17:45 and supper, the kora at its busiest round 17:42 for some, a few out
    again after supper, home for the night (chapter 05, 7.2; its outdoor counts, 8.1, drawn roughly)."""
    home, old = wk["home"], wk["old"]
    t = rng.uniform(280.0, 320.0) if old else rng.uniform(345.0, 430.0)
    stops = [[home, 0.0, round(t, 2), "inside", 0]]
    at = [home]

    def go(to, lo, hi, how, loops=0, until=None):
        nonlocal t
        if to == at[0] and how == stops[-1][3]:  # already there: it stays on
            t = max(t, until if until is not None else t + rng.uniform(lo, hi))
            stops[-1][2] = round(t, 2)
            return True
        tr = trav(at[0], to)
        if tr is None:
            return False
        arrive = t + tr + rng.uniform(0.0, 3.0)
        if until is not None:
            leave = max(arrive + 1.0, until)
        elif how == "wheel":
            leave = arrive + WHEEL_MIN + rng.uniform(1.0, 4.0)
        elif how == "mani":
            leave = arrive + loops * loop_min + rng.uniform(0.5, 2.0)
        else:
            leave = arrive + rng.uniform(lo, hi)
        stops.append([to, round(arrive, 2), round(leave, 2), how, loops])
        t = leave
        at[0] = to
        return True

    def errand(phase):
        names = [k for k, v in DAY.items() if v[0][phase] > 0 and k != at[0]]
        e = rng.choices(names, [DAY[k][0][phase] for k in names])[0]
        to = rng.choice([h for h in homes if h not in (home, at[0])]) if e == "visit" else e
        _, (lo, hi), how = DAY[e]
        return go(to, lo, hi, how, rng.randint(1, 3) if how == "mani" else 0)

    if old:  # the first old people set out with lamps for the barkor (04:30), and home for tea
        go("mani", 0, 0, "mani", rng.randint(2, 3))
        go(home, 40, 90, "inside")
    if wk["kind"] == "monk":  # down the 1,080 steps to read in a lay house (09:00; R-04)
        go(rng.choice([h for h in homes if h != home]), 90, 150, "inside")
    while t < 10.9 * 60 and errand(0):
        pass
    if rng.random() < 0.6:  # midday tea at home (11:43, solar noon)
        go(home, 45, 85, "inside")
    dusk = rng.uniform(16.75, 17.2) * 60
    while t < dusk - 40 and errand(1):
        pass
    go(home, 0, 0, "inside", until=rng.uniform(17.4, 17.7) * 60)  # the roof sang, 17:00-17:45
    if rng.random() < (0.6 if old else 0.3):  # the kora at its busiest, 17:42
        go("mani", 0, 0, "mani", rng.randint(1, 2))
    go(home, 0, 0, "inside", until=rng.uniform(19.0, 19.5) * 60)  # supper, 18:30
    r = rng.random()
    if r < 0.3:  # out again: Tsongra's talkers, a neighbour's, Dechen-tsang's yard (the bard from 21:00)
        keep = (t, list(at), len(stops))
        errand(2)
        if r < 0.1 and t < 21.0 * 60:
            errand(2)
        back = t + (trav(at[0], home) or 0.0) + 1.0
        if back > 22.75 * 60:  # home by about 22:30, or not out at all
            t, at[:], stops[keep[2]:] = keep[0], keep[1], []
    if at[0] == home:
        night(stops, home)
    else:
        stops.append([home, round(t + (trav(at[0], home) or 0.0) + 1.0, 2), 1440.0, "inside", 0])
    return stops


ROLE_DAY = {  # Shöl's own drawn by archetype (M2 sprint 10, step 3; chapter 05, 7.2 and 8.1): first out (hours), the dawn's
    # outings (place, chance), the errands' weights in the morning and the afternoon, the chances of home at noon, home for
    # the roof sang (17:00-17:45, on the roof: indoors to TownSim), the kora at dusk, out after supper, and to the bard
    "TW": {"wake": (5.6, 6.6), "dawn": [("basin", 0.55), ("spring", 0.3)],
           "am": {"stalls": 2.0, "market": 6.0, "tsongra": 2.0, "tsongra_lower": 1.5, "basin": 1.5, "visit": 1.5, "lhakhang": 1.0, "mani": 1.0, "dechen": 0.5, "river_street": 0.5},
           "noon": 0.7, "pm": {"tsongra": 2.0, "stalls": 1.0, "visit": 2.0, "basin": 1.0, "lhakhang": 1.0, "mani": 1.5},
           "sang": 0.9, "kora": 0.4, "eve": 0.35, "bard": 0.15},
    "TM": {"wake": (5.4, 6.8), "dawn": [("dechen", 0.35)],
           "am": {"tsongra": 2.0, "market": 3.0, "dechen": 2.0, "talkers": 2.0, "saddler": 1.0, "turner": 1.0, "tailor": 1.0, "headman": 1.0, "visit": 1.0, "tsongra_lower": 1.0, "river_street": 0.6},
           "noon": 0.6, "pm": {"tsongra": 2.0, "talkers": 2.5, "dechen": 1.5, "visit": 1.5, "lhakhang": 0.5, "mani": 1.0},
           "sang": 0.7, "kora": 0.3, "eve": 0.55, "bard": 0.3},
    "TE": {"wake": (4.4, 5.2), "dawn": [("mani", 0.9)],
           "am": {"mani": 3.0, "lhakhang": 3.0, "talkers": 2.0, "tsongra": 1.0, "visit": 1.0},
           "noon": 0.8, "pm": {"mani": 2.0, "lhakhang": 2.0, "talkers": 3.0, "visit": 1.0},
           "sang": 0.8, "kora": 0.7, "eve": 0.15, "bard": 0.1},
    "TB": {"wake": (6.6, 7.6), "dawn": [],
           "am": {"tsongra": 3.0, "talkers": 3.0, "basin": 1.0, "stalls": 1.0, "mani": 0.5, "stair_top": 0.5},
           "noon": 0.7, "pm": {"tsongra": 3.0, "talkers": 2.0, "basin": 1.0, "lhakhang": 1.0, "stair_top": 0.5},
           "sang": 0.6, "kora": 0.3, "eve": 0.2, "bard": 0.2},
    "TG": {"wake": (6.4, 7.4), "dawn": [("basin", 0.3)],
           "am": {"tsongra": 3.0, "talkers": 2.0, "stalls": 2.0, "basin": 1.5, "mani": 0.5},
           "noon": 0.7, "pm": {"tsongra": 2.5, "talkers": 2.0, "basin": 1.0, "lhakhang": 1.0, "stalls": 1.0},
           "sang": 0.7, "kora": 0.3, "eve": 0.15, "bard": 0.15},
    "NG": {"wake": (6.0, 7.0), "dawn": [("pema_o", 0.7)],
           "am": {"visit": 4.0, "pema_o": 2.0, "tsongra": 1.0, "conch_terrace": 1.0},
           "noon": 0.8, "pm": {"visit": 2.0, "pema_o": 2.0, "talkers": 1.0},
           "sang": 0.9, "kora": 0.3, "eve": 0.2, "bard": 0.1},
}
EVENING = {"m": {"chang": 3.0, "talkers": 2.0, "tsongra": 1.0, "visit": 1.0}, "f": {"visit": 3.0, "talkers": 1.0, "tsongra": 1.0, "chang": 0.5}}
PRESENCE = {4.5: 10, 6.0: 70, 7.0: 98, 9.0: 112, 11.0: 120, 13.0: 104, 15.0: 98, 17.0: 102, 19.0: 52, 21.0: 24, 0.0: 6}  # chapter 05,
# 8.1: Shöl's people outdoors and visible by the hour (the 17:00's on the roofs, which TownSim's walkers are not)
PRESENCE_HEJIE = {4.5: 2, 6.0: 16, 7.0: 30, 9.0: 40, 11.0: 46, 13.0: 44, 15.0: 36, 17.0: 44, 19.0: 24, 21.0: 14, 0.0: 3}  # and Hejie's
PRESENCE_SAMKHA = {4.5: 0, 6.0: 4, 7.0: 8, 9.0: 12, 11.0: 12, 13.0: 14, 15.0: 12, 17.0: 10, 19.0: 4, 21.0: 2, 0.0: 0}  # and Samkha's
# (the court's parties, the toll's traffic and the ula yard's among them: world/samkha_people.gd and world/ula_yard.gd draw
# those, the walkers are Samkha's own and the parties in the ward)


def day_places():
    """Every place the archetypes' days, the visitors' and Hejie's own go to (the dawn's outings, the errands, the evening's)."""
    out = set()
    for R in ROLE_DAY.values():
        out |= {p for p, _ in R["dawn"]} | set(R["am"]) | set(R["pm"])
    for w in EVENING.values():
        out |= set(w)
    for _o, _b, w in VISITS.values():
        out |= set(w)
    for H in list(HEJIE_DAY.values()) + list(SAMKHA_DAY.values()):
        out |= set(H["w"])
    return sorted(out - {"visit", "market"})


def archetype_day(rng, wk, homes, trav, loop_min, role, sex, keep=None):
    """One of Shöl's own drawn's day by its archetype, 04:00 to 04:00 (ROLE_DAY; chapter 05, 7.2): home until it is
    first out (the old with lamps to the barkor at 04:30, the women for water and the men loading the caravans at the
    trading houses from 05:30), home for its tea, the morning's errands to about 11:15, home at noon for most, the
    afternoon's until the shadow, home for the roof sang (17:00-17:45), the kora at its busiest for some, supper, out
    again after it for a few (the chang house, the talkers' steps, a neighbour's, the bard in Dechen-tsang's yard from
    21:00), home for the night. [place, arrive, leave, how, loops] as plan_day's."""
    R = ROLE_DAY.get(role) or ROLE_DAY["TM" if sex == "m" else "TW"]
    home = wk["home"]
    t = rng.uniform(*R["wake"]) * 60.0
    stops = [[home, 0.0, round(t, 2), "inside", 0]]
    at = [home]

    def go(to, lo, hi, how, loops=0, until=None):
        nonlocal t
        if to == at[0] and how == stops[-1][3]:
            t = max(t, until if until is not None else t + rng.uniform(lo, hi))
            stops[-1][2] = round(t, 2)
            return True
        tr = trav(at[0], to)
        if tr is None:
            return False
        arrive = t + tr + rng.uniform(0.0, 3.0)
        if until is not None:
            leave = max(arrive + 1.0, until)
        elif how == "wheel":
            leave = arrive + WHEEL_MIN + rng.uniform(1.0, 4.0)
        elif how == "mani":
            leave = arrive + loops * loop_min + rng.uniform(0.5, 2.0)
        else:
            leave = arrive + rng.uniform(lo, hi)
        stops.append([to, round(arrive, 2), round(leave, 2), how, loops])
        t = leave
        at[0] = to
        return True

    def errand(weights):
        names = [k for k in weights if k != at[0] and (k in ("visit", "market") or trav(at[0], k) is not None)]
        if t > MARKET_UNTIL or not MARKET_PLACES:
            names = [k for k in names if k != "market"]
        if not names:
            return False
        e = rng.choices(names, [weights[k] for k in names])[0]
        to = rng.choice([h for h in homes if h not in (home, at[0])]) if e == "visit" else (rng.choice(MARKET_PLACES) if e == "market" else e)
        (lo, hi), how = (DAY[e][1], DAY[e][2]) if e in DAY else (((20, 60), "inside") if e == "chang" else (((10, 25), "stand") if e == "market" else ((10, 40), "stand")))
        return go(to, lo, hi, how, rng.randint(1, 3) if how == "mani" else 0)

    for place, p in ([] if keep is not None else R["dawn"]):  # the dawn's outing, then home for tea (a keeper makes its goods
        if rng.random() < p:  # ready at home instead)
            if place == "mani":
                go("mani", 0, 0, "mani", rng.randint(2, 3))
            elif place in DAY:
                go(place, DAY[place][1][0], DAY[place][1][1], DAY[place][2])
            else:
                go(place, 10, 30, "stand")
            go(home, 25, 60, "inside")
            break
    t = max(t, rng.uniform(6.0, 7.2) * 60.0) if stops[-1][3] == "inside" and at[0] == home else t  # out for the day, after the
    # juniper on the roofs at 06:00
    stops[-1][2] = round(t, 2) if at[0] == home else stops[-1][2]
    if keep is not None and trav(at[0], keep[0]) is not None:  # a keeper: its stall from the market's opening to its packing up
        place, seat, k0, k1 = keep
        t = min(t, k0 - trav(at[0], place) - rng.uniform(4.0, 14.0))  # out in time for the opening
        stops[-1][2] = round(t, 2)
        arrive = t + trav(at[0], place) + 1.0
        stops.append([place, round(arrive, 2), round(k1 + rng.uniform(0.0, 6.0), 2), "stand", 0, seat])
        t, at[0] = stops[-1][2], place
    while t < 11.25 * 60 and errand(R["am"]):
        pass
    if rng.random() < R["noon"]:  # midday tea at home (11:43, solar noon)
        go(home, 45, 85, "inside")
    shadow = rng.uniform(16.4, 16.9) * 60
    while t < shadow - 30 and errand(R["pm"]):
        pass
    if rng.random() < R["sang"]:  # the roof sang, 17:00-17:45, on its own roof
        go(home, 0, 0, "inside", until=rng.uniform(17.5, 17.7) * 60)
    if rng.random() < R["kora"]:  # the kora at its busiest, 17:42
        go("mani", 0, 0, "mani", rng.randint(1, 2))
    go(home, 0, 0, "inside", until=rng.uniform(18.4, 18.9) * 60)  # supper, 18:30
    if rng.random() < R["eve"]:  # out again after supper
        keep = (t, list(at), len(stops))
        if rng.random() < R["bard"] / max(R["eve"], 0.01):  # the bard in Dechen-tsang's yard, 21:00-23:00
            if t < 20.5 * 60:
                errand(EVENING[sex])
            go("dechen", 0, 0, "inside", until=rng.uniform(22.2, 23.0) * 60)
        else:
            errand(EVENING[sex])
            if rng.random() < 0.3:
                errand(EVENING[sex])
        back = t + (trav(at[0], home) or 0.0) + 1.0
        if back > 23.25 * 60:  # home by about 23:15, or not out at all
            t, at[:], stops[keep[2]:] = keep[0], keep[1], []
    if at[0] == home:
        night(stops, home)
    else:
        stops.append([home, round(t + (trav(at[0], home) or 0.0) + 1.0, 2), 1440.0, "inside", 0])
    return stops


def hejie_day(rng, wk, trav, role):
    """One of Hejie's own drawn's day (HEJIE_DAY; chapter 05, 7.2), 04:00 to 04:00: out at the dawn drum or after it, the
    day between its door (a shopkeeper at his counter, a wife at her threshold) and River Street's places (the teahouse,
    the temple, the post, the gates, the godown, the carriers' inn), home at noon for most, home by the gates' shutting at
    the first watch, 19:00, a few to the teahouse's storyteller after. [place, arrive, leave, how, loops] as plan_day's."""
    H = HEJIE_DAY.get(role) or HEJIE_DAY["HM"]
    home = wk["home"]
    t = rng.uniform(*H["out"]) * 60.0
    back = rng.uniform(*H["back"]) * 60.0
    stops = [[home, 0.0, round(t, 2), "inside", 0]]
    at = home

    def go(to, lo, hi, how):
        nonlocal t, at
        if to == at and how == stops[-1][3]:
            t += rng.uniform(lo, hi)
            stops[-1][2] = round(t, 2)
            return True
        tr = trav(at, to) if to != at else 0.0
        if tr is None:
            return False
        arrive = t + tr + rng.uniform(0.0, 2.0)
        leave = arrive + rng.uniform(lo, hi)
        stops.append([to, round(arrive, 2), round(leave, 2), how, 0])
        t, at = leave, to
        return True

    noon = False
    for _ in range(24):
        if t >= back:
            break
        if not noon and t > 11.5 * 60:
            noon = True
            if rng.random() < H["noon"]:
                go(home, 40, 80, "inside")
                continue
        if rng.random() < H["door"]:  # at its own door, its counter or its threshold
            go(home, 20, 70, "stand")
            continue
        names = [k for k in H["w"] if k != at and trav(at, k) is not None]
        if not names:
            break
        e = rng.choices(names, [H["w"][k] for k in names])[0]
        (lo, hi), how = HEJIE_STAY.get(e, ((15, 45), "stand"))
        if role == "QS" and e in ("east_gate_in", "water_gate_in"):
            lo, hi = 60, 150  # a turn of duty at a gate
        go(e, lo, hi, how)
    if rng.random() < H["eve"] and trav(at, "HEJ-14") is not None:  # the storyteller at the teahouse from 19:30
        go("HEJ-14", 0, 0, "inside")
        stops[-1][1] = max(stops[-1][1], 19.4 * 60)
        stops[-1][2] = round(max(stops[-1][1] + 30.0, rng.uniform(20.8, 21.8) * 60), 2)
        t = stops[-1][2]
    if at != home:
        stops.append([home, round(t + (trav(at, home) or 0.0) + 1.0, 2), 1440.0, "inside", 0])
    else:
        night(stops, home)
    for k in range(1, len(stops)):  # (each stop after the one before)
        stops[k][1] = max(stops[k][1], stops[k - 1][2] + 0.01)
        stops[k][2] = max(stops[k][2], stops[k][1] + 0.01)
    return stops


def samkha_day(rng, wk, trav, role):
    """One of Samkha's own drawn's day (SAMKHA_DAY; M2 sprint 11, step 5), 04:00 to 04:00, as Hejie's own's: out after
    first light, the day between its door and Samkha's places (the castle's ward and gate, the ula yard, Castle Lane, the
    ramp), home at noon for most, home by the dusk horns. [place, arrive, leave, how, loops] as plan_day's."""
    H = SAMKHA_DAY.get(role) or SAMKHA_DAY["TM"]
    home = wk["home"]
    t = rng.uniform(*H["out"]) * 60.0
    back = rng.uniform(*H["back"]) * 60.0
    stops = [[home, 0.0, round(t, 2), "inside", 0]]
    at = home

    def go(to, lo, hi, how):
        nonlocal t, at
        if to == at and how == stops[-1][3]:
            t += rng.uniform(lo, hi)
            stops[-1][2] = round(t, 2)
            return True
        tr = trav(at, to) if to != at else 0.0
        if tr is None:
            return False
        arrive = t + tr + rng.uniform(0.0, 2.0)
        leave = arrive + rng.uniform(lo, hi)
        stops.append([to, round(arrive, 2), round(leave, 2), how, 0])
        t, at = leave, to
        return True

    noon = False
    for _ in range(24):
        if t >= back:
            break
        if not noon and t > 11.5 * 60:
            noon = True
            if rng.random() < H["noon"]:
                go(home, 40, 80, "inside")
                continue
        if rng.random() < H["door"] and home.startswith("H-"):  # at its own door
            go(home, 15, 50, "stand")
            continue
        names = [k for k in H["w"] if k != at and trav(at, k) is not None]
        if not names:
            break
        e = rng.choices(names, [H["w"][k] for k in names])[0]
        (lo, hi), how = SAMKHA_STAY.get(e, ((15, 40), "stand"))
        go(e, lo, hi, how)
    if at != home:
        stops.append([home, round(t + (trav(at, home) or 0.0) + 1.0, 2), 1440.0, "inside", 0])
    else:
        night(stops, home)
    for k in range(1, len(stops)):  # (each stop after the one before)
        stops[k][1] = max(stops[k][1], stops[k - 1][2] + 0.01)
        stops[k][2] = max(stops[k][2], stops[k][1] + 0.01)
    return stops


def court_day(rng, wk, homes, trav, loop_min, case):
    """A party to the Pönpo's morning hearing (tools/town/roster.py CASES; M2 sprint 11, step 5): in from its way or its
    door, up to the castle's ward to wait among the others by the steps (court_wait), up the steps at its case's minute
    and in the hall on its felt until the case is done (castle_door, inside: world/samkha_people.gd draws it there), then
    a market visitor's errands in Shöl and home the way it came, by 15:00-16:00. [place, arrive, leave, how, loops] as
    plan_day's; None if the castle is not on its ground."""
    home = wk["home"]
    h0, h1 = case
    to_wait, up = trav(home, "court_wait"), trav("court_wait", "castle_door")
    if to_wait is None or up is None:
        return None
    arrive = h0 - up - rng.uniform(12.0, 40.0)
    stops = [[home, 0.0, round(arrive - to_wait - rng.uniform(0.5, 2.0), 2), "inside", 0],
             ["court_wait", round(arrive, 2), round(h0 - up - 0.2, 2), "stand", 0], ["castle_door", h0, h1, "inside", 0]]
    t, at = h1, "castle_door"
    back = rng.uniform(15.0, 16.0) * 60.0
    weights = VISITS["market"][2]
    for _ in range(8):
        names = [k for k in weights if k != at and (k in ("visit", "market") or trav(at, k) is not None)]
        if t > MARKET_UNTIL or not MARKET_PLACES:
            names = [k for k in names if k != "market"]
        if not names:
            break
        e = rng.choices(names, [weights[k] for k in names])[0]
        to = rng.choice([h for h in homes if h != at]) if e == "visit" else (rng.choice(MARKET_PLACES) if e == "market" else e)
        (lo, hi), how = (DAY[e][1], DAY[e][2]) if e in DAY else ((20, 60), "inside") if e == "chang" else ((10, 30), "stand")
        loops = rng.randint(1, 2) if how == "mani" else 0
        tr, home_tr = trav(at, to), trav(to, home)
        if tr is None or home_tr is None:
            continue
        stay = WHEEL_MIN + rng.uniform(1.0, 4.0) if how == "wheel" else (loops * loop_min + rng.uniform(0.5, 2.0) if how == "mani" else rng.uniform(lo, hi))
        if t + tr + stay + home_tr > back:
            break
        a_ = t + tr + rng.uniform(0.0, 3.0)
        stops.append([to, round(a_, 2), round(a_ + stay, 2), how, loops])
        t, at = a_ + stay, to
    stops.append([home, round(t + (trav(at, home) or 0.0) + 1.0, 2), 1440.0, "inside", 0])
    for k in range(1, len(stops)):  # (each stop after the one before)
        stops[k][1] = max(stops[k][1], stops[k - 1][2] + 0.01)
        stops[k][2] = max(stops[k][2], stops[k][1] + 0.01)
    return stops


def visitor_day(rng, wk, homes, trav, loop_min, q, keep=None):
    """A day for one of those who come into Shöl (tools/town/roster.py): out of its way in, or its lodging, in the
    morning; its errands by what brings it (VISITS: the hamlets' people to market, a monk to read in a lay house, a
    pilgrim round the kora and the great wheel, a caravan's man lodged in town to the trading houses and the craftsmen,
    a beggar along the market and the kora, the nomads selling butter); and back the way it came, the hamlets' people
    two hours before dusk, the monks before the horns, the lodgers at dusk; the rest of its day out of town (chapter 05,
    7.2; 8.1). [place, arrive, leave, how, loops] as plan_day's."""
    home, role = wk["home"], q["role"]
    kind = ("monk" if role in ("MK", "MN", "MP") else "pilgrim" if role == "PL" else "beggar" if role == "BP"
            else "nomad" if role in ("NM", "NW") or "nomads" in q["household"] else "lodger" if home in ("dechen", "tsongra") else "market")
    (o0, o1), (b0, b1), weights = VISITS[kind]
    t = rng.uniform(o0, o1) * 60.0
    back = rng.uniform(b0, b1) * 60.0
    stops = [[home, 0.0, round(t, 2), "inside", 0]]
    at = home
    if keep is not None and trav(at, keep[0]) is not None:  # a keeper: in early to its stall, there until the market packs up
        place, seat, k0, k1 = keep
        t = min(t, k0 - trav(at, place) - rng.uniform(5.0, 20.0))
        stops[0][2] = round(t, 2)
        arrive = t + trav(at, place) + 1.0
        stops.append([place, round(arrive, 2), round(k1 + rng.uniform(0.0, 6.0), 2), "stand", 0, seat])
        t, at = stops[-1][2], place
    for _ in range(12):
        names = [k for k in weights if k != at and (k in ("visit", "market") or trav(at, k) is not None)]
        if t > MARKET_UNTIL or not MARKET_PLACES:
            names = [k for k in names if k != "market"]
        if not names:
            break
        e = rng.choices(names, [weights[k] for k in names])[0]
        to = rng.choice([h for h in homes if h != at]) if e == "visit" else (rng.choice(MARKET_PLACES) if e == "market" else e)
        (lo, hi), how = (DAY[e][1], DAY[e][2]) if e in DAY else ((20, 60), "inside") if e == "chang" else (((10, 25), "stand") if e == "market" else ((10, 30), "stand"))
        if kind == "monk" and e == "visit":
            lo, hi = 90, 150  # reading in a lay house (R-04)
        loops = rng.randint(2, 4) if how == "mani" and kind == "pilgrim" else (rng.randint(1, 2) if how == "mani" else 0)
        tr, home_tr = trav(at, to), trav(to, home)
        if tr is None or home_tr is None:
            continue
        stay = WHEEL_MIN + rng.uniform(1.0, 4.0) if how == "wheel" else (loops * loop_min + rng.uniform(0.5, 2.0) if how == "mani" else rng.uniform(lo, hi))
        if t + tr + stay + home_tr > back:
            break
        arrive = t + tr + rng.uniform(0.0, 3.0)
        stops.append([to, round(arrive, 2), round(arrive + stay, 2), how, loops])
        t, at = arrive + stay, to
    if at != home:
        stops.append([home, round(t + (trav(at, home) or 0.0) + 1.0, 2), 1440.0, "inside", 0])
    else:
        night(stops, home)
    return stops


def night(stops, home):
    """The day's last stop, at home: in until midnight. A stand at its door (or where a visitor came in) ends when it was
    planned to and the walker goes in (M2 sprint 11, step 5: the stand had run on to midnight, a walker at its door or in
    Tsongra all night)."""
    if stops[-1][3] == "inside":
        stops[-1][2] = 1440.0
    else:
        stops.append([home, round(stops[-1][2] + 0.01, 2), 1440.0, "inside", 0])


def tobler(s):
    """Walking speed on a slope s (rise over run) against the level's: Tobler's hiking function, 1 on the level."""
    return np.exp(-3.5 * (np.abs(s + 0.05) - 0.05))


def to_world(x, y, rot, u, v):
    """A kit point (u, v; the kit builds facing -v) of a building at (x, y) facing rot, in the town grid (as
    rooftop.load turns them)."""
    th = math.radians(rot - 180.0)
    c, s_ = math.cos(th), math.sin(th)
    return x + u * c + v * s_, y - u * s_ + v * c


def load(market=True):
    """The ground's obstacles (every building's own footprint, what stands by it with a box of its own, the mani wall
    and Pasang's pitch, the Sky Stair between its cheeks, the talkers' and Tsongra's steps, and with `market` the
    market's stalls) and the placed buildings with their kit files, for their doors."""
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    houses = json.load(open(os.path.join(ROOT, "data", "town_generic.json"), encoding="utf-8"))["houses"]
    own = {"SHL-19": "headman_house_v1", "SHL-21": "workshop_turner_v1", "SHL-22": "workshop_saddler_v1",
           "SHL-25": "workshop_tailor_v1", "SHL-08": "mani_lhakhang_v1", "SHL-04": "trading_house_v1"}  # world/town.gd NAMED
    named = {"B": "town_house_b2_v1", "B, large": "town_house_b3_v1", "B, workshop": "town_house_b1_v1"}
    feet, records = [], [(h, LD.kit_file(h)) for h in houses]
    for h in houses:
        feet.append(B.rect(h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1], h["rot_deg"], 0.35))
    if market and os.path.exists(MARKET):  # Tsongra's market's stalls (tools/town/market.py; step 4): walked round all day
        for st in json.load(open(MARKET, encoding="utf-8"))["stalls"]:
            w_, d_ = STALL_SIZE.get(st["kit"], (2.5, 2.0))
            feet.append(B.rect(st["pos"][0], st["pos"][1], w_, d_, st["facing"], 0.2))
    hj = json.load(open(HEJIE, encoding="utf-8")) if os.path.exists(HEJIE) else {"houses": [], "pads": {}}
    for h in hj["houses"]:  # Hejie's generic houses (tools/town/hejie.py; M2 sprint 10, step 3)
        feet.append(B.rect(h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1], h["rot_deg"], 0.35))
        records.append((h, "%s_v%d" % (h["kit"], h["seed"])))
    for b in town["buildings"]:
        p, fp = b.get("pos"), b.get("footprint")
        if not p or p[2] is None or not fp or "line" in b or max(fp) > 80 or any(t in b.get("type", "") for t in OPEN_TYPES):
            continue
        hkit = hj["pads"].get(b["id"], {}).get("kit") if b["id"].startswith("HEJ-") else None
        if hkit and b.get("type") == "gate tower":  # a gate's passage open between its piers (its kit's ground boxes)
            records.append((b, hkit))
            continue
        if b["id"] in P.TURNED or (b["id"].startswith("MON-") and b["id"] in P.MOVED):  # moved off the flank the Castle Ramp
            # crosses, and turned (tools/town/castle_ramp.py; M2 sprint 11): where pads.py stands it (chapter 02's place lay on
            # the ramp); a hall of the monastery moved off its fall or a gate turned out (tools/town/monastery.py; M2 sprint 13)
            mv = P.MOVED.get(b["id"], (p[0], p[1]))
            p = [mv[0], mv[1], p[2]]
            b = dict(b, pos=p, rot_deg=P.TURNED.get(b["id"], b.get("rot_deg", 180.0)))
            if b["id"] in RAMP_KIT:  # its kit's ground boxes there: the stables' walls, the ula yard's walls and things
                records.append((b, RAMP_KIT[b["id"]]))
                if b["id"] == "SAM-09":  # the yard walked in, between its walls (M2 sprint 11, step 3)
                    continue
        feet.append(B.rect(p[0], p[1], fp[0], fp[1], b.get("rot_deg", 180.0), 0.35))  # the building; a yard's walls are its ground boxes
        if hkit:
            records.append((b, hkit))
        elif b["id"] in own:
            records.append((b, own[b["id"]]))
        elif b.get("type") in named:
            records.append((b, named[b["type"]]))
    castle = next((b for b in town["buildings"] if b["id"] == "SAM-01"), None)
    if castle is not None:  # Samkha Khar's tower and its ward's walls, its kit's ground boxes where world/town.gd stands it
        # (NAMED: (-130, -87), facing 180): its ward walked in at its gate (M2 sprint 11, step 5)
        records.append((dict(castle, pos=[-130.0, -87.0, 2649.0], rot_deg=180.0), "sam01_castle_v1"))
    for h, f in records:
        side = json.load(open(os.path.join(KIT, f + ".json")))
        x, y, _ = h["pos"]
        rot = h.get("rot_deg", 180.0)
        for g in side.get("ground", []):
            feet.append([to_world(x, y, rot, u, v) for u, v in ((g[0] - 0.35, g[1] - 0.35), (g[2] + 0.35, g[1] - 0.35),
                                                              (g[2] + 0.35, g[3] + 0.35), (g[0] - 0.35, g[3] + 0.35))])
    mani = json.load(open(os.path.join(GEN, "mani_walls.json")))
    for wall in mani["walls"]:
        for x, y, z, yaw, f in wall["segments"] + wall["ends"]:
            c, s_ = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
            hl, hw = (1.0, 0.7) if "seg" in f else (0.8, 0.8)
            feet.append([(x + u * c - v * s_, y + u * s_ + v * c) for u, v in ((-hl, -hw), (hl, -hw), (hl, hw), (-hl, hw))])
        if "pitch" in wall:  # Pasang's, by the barkor's wall (the western has none)
            x, y, z, facing, f = wall["pitch"]["at"]
            feet.append([to_world(x, y, facing, u, v) for u, v in ((-1.35, -0.95), (2.15, -0.95), (2.15, 1.05), (-1.35, 1.05))])
    st = stair()
    for kind, y0, y1, z0, z1, n, width in st["plan"]:  # the stair between its cheeks, its foot and top open
        half = width / 2 + 0.35 + 0.35
        feet.append([st["at"](s, off) for s, off in ((y0 - 0.05, -half), (y1 + 0.05, -half), (y1 + 0.05, half), (y0 - 0.05, half))])
    run, rise, n, width = TALKERS  # the talkers' steps, before the stair's foot
    feet.append([st["at"](s, off) for s, off in ((-run - 0.35, -width / 2 - 0.35), (-1.6, -width / 2 - 0.35),
                                                  (-1.6, width / 2 + 0.35), (-run - 0.35, width / 2 + 0.35))])
    (tx, ty), tz, trun, trise, tn, tw = TSONGRA
    feet.append([(tx + u, ty + v) for u, v in ((-tw / 2 - 0.35, -0.35), (tw / 2 + 0.35, -0.35), (tw / 2 + 0.35, trun + 0.35),
                                                (-tw / 2 - 0.35, trun + 0.35))])
    return feet, records, town


def stair():
    """The Sky Stair: its plan (the kit's: flights and landings along it, [kind, y0, y1, z0, z1, steps, width]) and a
    function from (along, across to the east) to the town grid."""
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    line = next(b["line"] for b in town["buildings"] if b["id"] == "SHL-15")
    (ax, ay), (bx, by) = line
    L = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / L, (by - ay) / L
    ex, ey = uy, -ux  # to the right going up, east
    plan = json.load(open(os.path.join(KIT, "sky_stair_v1.json")))["plan"]
    return {"plan": plan, "u": (ux, uy), "at": lambda s, off=0.0: (ax + ux * s + ex * off, ay + uy * s + ey * off)}


def stair_z(plan, s):
    """The stair's tread line along it (its nosings on a flight, level on a landing), over its foot."""
    for kind, y0, y1, z0, z1, n, width in plan:
        if s <= y1:
            return STAIR_Z + (z0 if y1 <= y0 else z0 + (z1 - z0) * max(0.0, s - y0) / (y1 - y0))
    return STAIR_Z + plan[-1][4]


def main():
    site = Site.load()
    padded = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    terrain = lambda x, y: padded.z(x, y) - site.shift
    feet, records, town = load()
    lanes = json.load(open(os.path.join(ROOT, "data", "town_lanes.json"), encoding="utf-8"))["lanes"] + [ln for ln in P.ramp_lanes() if not ln.get("channel")]
    x0, y0, x1, y1 = GROUND_BOX
    ground = R.Ground(terrain, feet, x0, y0, x1, y1, lambda X, Y: np.ones(X.shape, dtype=bool), lanes,
                      raster=(padded.x0, padded.y1, padded.res))
    ok, gz, town_m, steep = ground.ok, ground.z, ground.town, ground.steep

    def zat(x, y):
        """The game's ground at (x, y): the whole-metre lattice, read bilinearly (as rooftop.Ground reads it)."""
        vx, vy = math.floor(x), math.floor(y)
        fx, fy = x - vx, y - vy
        q = terrain(np.array([vx, vx + 1.0, vx, vx + 1.0]), np.array([vy, vy, vy + 1.0, vy + 1.0]))
        return float(q[0] * (1 - fx) * (1 - fy) + q[1] * fx * (1 - fy) + q[2] * (1 - fx) * fy + q[3] * fx * fy)

    # The Mani Lane's way (chapter 05, 9.4): which moves are allowed where.
    (bax, bay), (bbx, bby) = P.BARKOR["from"], P.BARKOR["to"]
    WL = math.hypot(bbx - bax, bby - bay)
    wu = ((bbx - bax) / WL, (bby - bay) / WL)
    wn = (-wu[1], wu[0])  # north of the wall
    band = P.BARKOR["wall"] / 2 + P.BARKOR["lane"] + 0.5

    def allowed(mx, my, dx, dy):
        """Whether a move (dx, dy) at (mx, my) keeps the mani wall on the right: arrays in, a boolean array out."""
        rx, ry = mx - bax, my - bay
        al, lat = rx * wu[0] + ry * wu[1], rx * wn[0] + ry * wn[1]
        dal, dlat = dx * wu[0] + dy * wu[1], dx * wn[0] + dy * wn[1]
        beside = (al >= 0.0) & (al <= WL) & (np.abs(lat) <= band)
        west = (al < 0.0) & (al > -15.0) & (np.abs(lat) < 1.0)  # the wall's line past its ends: crossed one way only
        east = (al > WL) & (al < WL + 15.0) & (np.abs(lat) < 1.0)
        bad = beside & (((lat > 0) & (dal < -0.05)) | ((lat < 0) & (dal > 0.05)))
        bad |= west & (dlat < -0.05)
        bad |= east & (dlat > 0.05)
        return ~bad

    # The lattice: every other cell, joined to its eight neighbours.
    ny, nx = ok.shape
    ii, jj = np.meshgrid(np.arange(0, ny, 2), np.arange(0, nx, 2), indexing="ij")
    node_of = -np.ones(ok.shape, dtype=np.int64)
    lat_ok = ok[ii, jj]
    node_of[ii[lat_ok], jj[lat_ok]] = np.arange(int(lat_ok.sum()))
    nodes_i, nodes_j = ii[lat_ok], jj[lat_ok]
    xs = x0 + (nodes_j + 0.5) * CELL
    ys = y0 + (nodes_i + 0.5) * CELL
    zs = gz[nodes_i, nodes_j]
    xyz = [np.stack([xs, ys, zs], axis=1)]  # the lattice; the nodes added to it (kind 1 the stair's axis, 2 an end or an anchor) in `extra`
    n_lat = len(xs)
    src, dst, cost = [], [], []
    lim = math.tan(math.radians(30.0))
    for di, dj in ((0, 2), (2, 0), (2, 2), (2, -2)):
        w = math.hypot(di, dj) * CELL
        a_i, a_j = nodes_i, nodes_j
        b_i, b_j = a_i + di, a_j + dj
        m_i, m_j = a_i + di // 2, a_j + dj // 2
        inb = (b_i >= 0) & (b_i < ny) & (b_j >= 0) & (b_j < nx)
        a_i, a_j, b_i, b_j, m_i, m_j = a_i[inb], a_j[inb], b_i[inb], b_j[inb], m_i[inb], m_j[inb]
        good = ok[b_i, b_j] & ok[m_i, m_j] & (node_of[b_i, b_j] >= 0)
        good &= (np.abs(gz[m_i, m_j] - gz[a_i, a_j]) <= lim * w / 2) & (np.abs(gz[b_i, b_j] - gz[m_i, m_j]) <= lim * w / 2)
        a_i, a_j, b_i, b_j = a_i[good], a_j[good], b_i[good], b_j[good]
        na, nb = node_of[a_i, a_j], node_of[b_i, b_j]
        dz = gz[b_i, b_j] - gz[a_i, a_j]
        mx = x0 + ((a_j + b_j) / 2 + 0.5) * CELL
        my = y0 + ((a_i + b_i) / 2 + 0.5) * CELL
        ddx, ddy = dj * CELL, di * CELL
        for fwd in (True, False):
            p, q = (na, nb) if fwd else (nb, na)
            sgn = 1.0 if fwd else -1.0
            t = w / (PACE * tobler(sgn * dz / w))
            qi, qj = (b_i, b_j) if fwd else (a_i, a_j)
            t = t * np.where(town_m[qi, qj], 1.0, OPEN) * np.where(steep[qi, qj], STEEP, 1.0)
            keep = allowed(mx, my, sgn * ddx, sgn * ddy)
            src.append(p[keep])
            dst.append(q[keep])
            cost.append(t[keep])
    special = {}  # (a, b) -> (steps, [its first tread, its top] in the way a to b): the flights, kept whole in a route
    extra = []  # the nodes added to the lattice: (x, y, z, kind)

    def add_node(x, y, z, kind):
        extra.append((x, y, z, kind))
        return n_lat + len(extra) - 1

    def pos_of(k):
        return tuple(xyz[0][k]) if k < n_lat else extra[k - n_lat][:3]

    def kind_of(k):
        return 0 if k < n_lat else extra[k - n_lat][3]

    def join(a, b, t_ab, t_ba, flight=0, inner=None):
        """An edge each way (a way given no time is closed); a flight's `inner` points, its first tread and its top, are
        where a route leaves the level for its steps and comes back to it (a straight line from end to end had cut
        through a lane's level foot and head, up to a metre off the ground)."""
        for p, q, t, inn in ((a, b, t_ab, inner), (b, a, t_ba, inner[::-1] if inner else None)):
            if t is None:
                continue
            src.append(np.array([p]))
            dst.append(np.array([q]))
            cost.append(np.array([t]))
            if flight:
                special[(p, q)] = (flight, inn)

    def near_node(x, y, reach=2.5, within=None, straight=True):
        """The nearest lattice point within reach (and in the component `within`, when given) whose straight walk to
        (x, y) is walkable but at its very start (when `straight`)."""
        ci, cj = int((y - y0) / CELL), int((x - x0) / CELL)
        best = None
        r = int(reach / CELL) + 1
        for i in range(max(0, ci - r), min(ny, ci + r + 1)):
            for j in range(max(0, cj - r), min(nx, cj + r + 1)):
                k = node_of[i, j]
                if k < 0 or (within is not None and comp0[k] != within):
                    continue
                qx, qy = x0 + (j + 0.5) * CELL, y0 + (i + 0.5) * CELL
                d = math.hypot(qx - x, qy - y)
                if d <= reach and (best is None or d < best[0]) and (not straight or clear_line((x, y), (qx, qy), skip=0.6)):
                    best = (d, k)
        return best[1] if best else None

    def clear_line(a, b, skip=0.0, side=0.0):
        """Whether the straight walk a to b (town grid) is on walkable cells, but its first `skip` metres."""
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(L / 0.25))
        sx, sy = ((-(b[1] - a[1]) / L, (b[0] - a[0]) / L) if L > 0 else (0.0, 0.0))
        for off in ((0.0, side, -side) if side else (0.0,)):
            for k in range(n + 1):
                if k * L / n < skip:
                    continue
                c = ground.cell(a[0] + (b[0] - a[0]) * k / n + sx * off, a[1] + (b[1] - a[1]) * k / n + sy * off)
                if c is None:
                    return False
        return True

    # The Sky Stair: its axis from its foot to its top, split at its plan's joints and at the gap in its east cheek.
    st = stair()
    plan = st["plan"]
    cuts = sorted({round(p[1], 3) for p in plan} | {round(plan[-1][2], 3), STAIR_OPEN})
    axis = []
    for s in cuts:
        x, y = st["at"](s)
        axis.append(add_node(x, y, stair_z(plan, s), 1))
    for k in range(len(cuts) - 1):
        sa, sb = cuts[k], cuts[k + 1]
        seg = next(p for p in plan if p[1] - 1e-3 <= sa and sb <= p[2] + 1e-3)
        if seg[0] == "flight":
            steps = seg[5] * (sb - sa) / (seg[2] - seg[1])
            join(axis[k], axis[k + 1], steps * UP, steps * DOWN, flight=max(1, round(steps)))
        else:
            join(axis[k], axis[k + 1], (sb - sa) / PACE, (sb - sa) / PACE)
    ends = {}
    run, rise, n, width = TALKERS  # its foot: down the talkers' steps to Tsongra's upper level
    fx, fy = st["at"](-run - 0.9)
    ends["stair foot"] = add_node(fx, fy, zat(fx, fy), 2)
    join(ends["stair foot"], axis[0], n * UP + 1.6 / PACE, n * DOWN + 1.6 / PACE, flight=n,
         inner=[(*st["at"](-run), STAIR_Z - rise), (*st["at"](-1.6), STAIR_Z)])
    tx, ty = st["at"](plan[-1][2] + 1.8)  # its top: onto the level ground past it
    ends["stair top"] = add_node(tx, ty, zat(tx, ty), 2)
    join(axis[-1], ends["stair top"], 1.8 / PACE, 1.8 / PACE)
    k_open = cuts.index(STAIR_OPEN)  # the gap in its east cheek, onto the Mani Lhakhang's forecourt
    gx, gy = st["at"](STAIR_OPEN, 3.2)
    ends["stair gap"] = add_node(gx, gy, zat(gx, gy), 2)
    join(axis[k_open], ends["stair gap"], 3.2 / PACE, 3.2 / PACE)
    (tx0, ty0), tz, trun, trise, tn, tw = TSONGRA  # Tsongra's steps between its levels
    ends["Tsongra's steps' foot"] = add_node(tx0, ty0 - 0.9, tz, 2)
    ends["Tsongra's steps' top"] = add_node(tx0, ty0 + trun + 0.9, tz + trise, 2)
    join(ends["Tsongra's steps' foot"], ends["Tsongra's steps' top"], tn * UP + 1.8 / PACE, tn * DOWN + 1.8 / PACE, flight=tn,
         inner=[(tx0, ty0, tz), (tx0, ty0 + trun, tz + trise)])
    for key, a in ends.items():  # each onto the ground's lattice
        x, y, _, _ = extra[a - n_lat]
        k = near_node(x, y)
        if k is None:
            print("graph: WARNING: %s joins no ground" % key)
            continue
        d = math.dist((x, y), pos_of(k)[:2])
        join(a, k, d / PACE + 0.1, d / PACE + 0.1)
    n_flights = 0
    for ln in lanes:  # the side lanes' flights, foot to head (as rooftop.py climbs them)
        f = ln["flight"]
        if not f:
            continue
        (fx, fy), (ux, uy) = ln["from"], ln["dir"]
        s_up = f["s"] + max(0.0, ln["z_a"] - f["z"]) / 0.8
        ax_, ay_ = fx + ux * (s_up - 0.6), fy + uy * (s_up - 0.6)
        bx_, by_ = fx + ux * (ln["length"] + 0.4), fy + uy * (ln["length"] + 0.4)
        ka, kb = near_node(ax_, ay_, 2.5), near_node(bx_, by_, 2.5)  # 1.5 until IMP-019: a house's stair can pinch a lane's foot
        if ka is None or kb is None:  # something stands in its way at its foot or its head (IMP-019: a house's stair)
            print("graph: WARNING: side lane %d's flight joins no ground at its %s (%.1f, %.1f)" % (
                lanes.index(ln), "foot" if ka is None else "head", *((ax_, ay_) if ka is None else (bx_, by_))))
            continue
        steps = int(round((f["z"] + f["rise"] - max(ln["z_a"], f["z"])) / 0.2))  # the treads above the lane's floor
        s_top = f["s"] + f["rise"] / 0.2 * 0.25
        run_m = ln["length"] + 0.4 - (s_up - 0.6)
        up_t, down_t = steps * UP + (run_m - steps * 0.25) / PACE, steps * DOWN + (run_m - steps * 0.25) / PACE
        inner = [(fx + ux * s_up, fy + uy * s_up, max(ln["z_a"], f["z"])), (fx + ux * s_top, fy + uy * s_top, f["z"] + f["rise"])]
        join(ka, kb, up_t, down_t, flight=steps, inner=inner)
        n_flights += 1

    # The anchors: where the walkers go, each on the town's walkable whole (what Tsongra's upper level reaches and is
    # reached from: a door on an island of ground, walled in by its neighbours' pads, goes to the nearest ground that is
    # in it, within 4 m, and the walker stands there).
    G0 = csr_matrix((np.concatenate(cost), (np.concatenate(src), np.concatenate(dst))), shape=(n_lat + len(extra),) * 2)
    comp0 = connected_components(G0, directed=True, connection="strong")[1]
    main0 = comp0[near_node(3.0, 5.0)]
    anchors, standins = {}, []

    def anchor(name, x, y, reach=4.0):
        k = near_node(x, y, reach, within=main0)
        if k is not None:
            a = add_node(x, y, zat(x, y), 2)
            d = math.dist((x, y), pos_of(k)[:2])
            dz = pos_of(k)[2] - zat(x, y)  # a door on its pad over the ground before it: its few steps (TownSim's rule)
            steep = abs(dz) > d and abs(dz) > 0.3
            join(a, k, d / PACE + 0.1 + (abs(dz) / 0.2 * (UP if dz > 0 else DOWN) if steep else 0.0),
                 d / PACE + 0.1 + (abs(dz) / 0.2 * (DOWN if dz > 0 else UP) if steep else 0.0))
        else:
            k = near_node(x, y, reach, within=main0, straight=False)
            if k is None:
                return None
            a = k  # the door is not reached straight: the walker stops at the nearest ground that reaches it
            standins.append(name)
        anchors[name] = a
        return a

    def door(h, f, out=1.3, sock="SOCK_DOOR_1"):
        side = json.load(open(os.path.join(KIT, f + ".json")))
        sp = side["socket_pos"].get(sock)
        if sp is None:
            return None
        x, y, _ = h["pos"]
        rot = h.get("rot_deg", 180.0)
        # out from the wall the socket is on: the nearer of the front (-v) and the sides
        u, v = sp[0], sp[1]
        return to_world(x, y, rot, u, v - out)

    for b in town["buildings"]:
        if b["id"] == "SHL-04":
            gx, gy = to_world(b["pos"][0], b["pos"][1], 180.0, 0.0, -23.5 - 1.5)  # its gate (SOCK_GATE_1)
            anchor("dechen", gx, gy)
        elif b["id"] == "SHL-19":
            gx, gy = to_world(b["pos"][0], b["pos"][1], 180.0, 6.0 + 1.3, -7.3)  # its yard's east gate (SOCK_GATE_1)
            anchor("headman", gx, gy)
        elif b["id"] in ("SHL-21", "SHL-22", "SHL-25"):
            name = {"SHL-21": "turner", "SHL-22": "saddler", "SHL-25": "tailor"}[b["id"]]
            fname = {"turner": "workshop_turner_v1", "saddler": "workshop_saddler_v1", "tailor": "workshop_tailor_v1"}[name]
            p = door(b, fname, out=1.2)  # on the apron before it (its goods stand by the door)
            if p:
                anchor(name, *p, reach=8.0)  # (its raised apron walled round by its neighbours' yards since IMP-023)
        elif b["id"] == "SHL-08":
            dx, dy = to_world(b["pos"][0], b["pos"][1], b.get("rot_deg", 180.0), 0.0, -6.0 - 1.2)
            anchor("lhakhang", dx, dy)
        elif b["id"] == "SHL-02":
            anchor("basin", b["pos"][0], b["pos"][1] - 2.2)
        elif b["id"] in ENTER_TOWN:  # a building of the gazetteer to enter (the chang house, M2 sprint 2): its stair's foot
            name, seed = ENTER_TOWN[b["id"]]
            p = door(dict(b, rot_deg=b.get("rot_deg", 180.0)), "town_house_b2_in_v%d" % seed, out=1.2, sock="SOCK_STAIR_1")
            if p:
                anchor(name, *p, reach=6.0)
    anchor("tsongra", 3.0, 5.0)
    yak = next((b for b in town["buildings"] if b["id"] == "SAM-07"), None)  # the Yak Gate, where the performance route PT-slice starts
    if yak:
        anchor("yak_gate", yak["pos"][0], yak["pos"][1] + 3.0, reach=6.0)
    rp = os.path.join(ROOT, "data", "north_ramp.json")
    if os.path.exists(rp):  # the north ramp's foot, where the lower cantilever bridge begins (the caravan's way up)
        ramp = json.load(open(rp))
        foot = ramp["foot"]
        if anchor("ramp_foot", foot[0] - 1.0, foot[1], reach=3.0) is None:
            for ln in ramp["lanes"]:  # which of its lanes the town reaches, to find the break
                mx = ln["from"][0] + ln["dir"][0] * ln["length"] / 2
                my = ln["from"][1] + ln["dir"][1] * ln["length"] / 2
                k = near_node(mx, my, 2.0, straight=False)
                print("graph: the north ramp's %s at (%.1f, %.1f): %s" % (ln["id"], mx, my, "no ground" if k is None else (
                    "in the town's whole" if comp0[k] == main0 else "cut off (component %d)" % comp0[k])))
    anchor("tsongra_lower", 6.0, -9.0)
    anchor("stalls", -15.0, -6.0)
    sx, sy = st["at"](plan[-1][2] + 5.0)
    anchor("stair_top", sx, sy)
    mani_n = anchor("mani", bax - 1.0, bay + P.BARKOR["wall"] / 2 + P.BARKOR["lane"] / 2)  # the lane's west end, north side
    mani_s = anchor("mani_s", bax + 1.0, bay - P.BARKOR["wall"] / 2 - P.BARKOR["lane"] / 2)
    run, rise, n, width = TALKERS  # the named eight's places (sprint 6, step 3): the foot of the talkers' steps,
    anchor("talkers", *st["at"](-run - 0.9))  # on Tsongra's upper level, where the old men sit and trade news (SHL-40)
    mw = json.load(open(os.path.join(GEN, "mani_walls.json")))
    ppx, ppy, ppz, pfacing, pfile = mw["walls"][0]["pitch"]["at"]  # and before Pasang's pitch, in the Mani Lane (SHL-27)
    # arrived at from the west and left to the east, so the steps onto and off its seats keep the wall on the right
    # (the kit's +u is the town's west here): two ends in the lane before it
    anchor("pitch", *to_world(ppx, ppy, pfacing, 1.6, -1.9))
    anchor("pitch_out", *to_world(ppx, ppy, pfacing, -1.2, -1.9))
    departs = {"pitch": "pitch_out"}  # a place whose routes away start elsewhere than its arrival
    lk = next((b for b in town["buildings"] if b["id"] == "SHL-14"), None)  # the Lukhang spring's yard: Kalsang's water
    if lk:  # its way in at the yard's east side, where the path comes up (M2 sprint 6, step 3: in the kit's frame 5 m east
        # of its middle and 2.5 m down); world/spring.gd takes the water carriers on to the queue, the spouts, the gossip
        cx, cy = P.MOVED.get("SHL-14", lk["pos"][:2])
        anchor("spring", *to_world(cx, cy, lk.get("rot_deg", 180.0), 5.0, -2.5), reach=3.0)
    # the town's east and west ends on the walkers' ground (M2 sprint 6, step 2): Pema Ö's porch (its kit frame turned to
    # 140 degrees: kit/confluence.py's porch mouth 7.6 m before its middle) and the Conch terrace; the west edge's lanes,
    # its way down towards Hejie, the Landing and the caravan ground (a walker there is away, as the drovers are at the
    # Yak Gate), and the western mani wall SHL-10, the lingkor's west side
    pema = next((b for b in town["buildings"] if b["id"] == "SHL-11"), None)
    if pema:
        th = math.radians(180.0 - 140.0)
        anchor("pema_o", pema["pos"][0] + 7.6 * math.sin(th), pema["pos"][1] - 7.6 * math.cos(th), reach=5.0)
        anchor("conch_terrace", 188.0, -80.0, reach=5.0)
    gpath = os.path.join(ROOT, "data", "gardens.json")  # the Gorge Rim Lookout: its way on at the garden lane's end, where
    if os.path.exists(gpath):  # the terrace opens (its footprint the lattice's obstacle; M2 sprint 6, step 4)
        gl = json.load(open(gpath, encoding="utf-8"))["lanes"][-1]
        anchor("lookout", gl["from"][0] + gl["dir"][0] * gl["length"], gl["from"][1] + gl["dir"][1] * gl["length"], reach=3.0)
    # (the western mani wall's foot, on its bed's west side: tools/terrain/pads.py STAIRS "SHL-10"; M2 sprint 6, step 6)
    wsid, wa, wb, wwidth, wkit, wtop = next(st for st in P.STAIRS if st[0].startswith("SHL-10"))
    wL = math.hypot(wb[0] - wa[0], wb[1] - wa[1])
    wu = ((wb[0] - wa[0]) / wL, (wb[1] - wa[1]) / wL)
    west_at = lambda s_, lat: (wa[0] + wu[0] * s_ + wu[1] * lat, wa[1] + wu[1] * s_ - wu[0] * lat)  # lat < 0 west, > 0 east
    for name, (ax, ay) in (("west_edge", (-298.0, 40.0)), ("west_way", (-325.0, 25.0)), ("west_mani", west_at(4.0, -2.2))):
        if anchor(name, ax, ay, reach=8.0) is None:
            print("graph: WARNING: no ground for %s near (%.0f, %.0f)" % (name, ax, ay))
    houses = json.load(open(os.path.join(ROOT, "data", "town_generic.json"), encoding="utf-8"))["houses"]
    hj = json.load(open(HEJIE, encoding="utf-8")) if os.path.exists(HEJIE) else {"houses": [], "pads": {}}
    house_xy = {h["id"]: h["pos"] for h in houses + hj["houses"]}
    for name, (hx, hy) in HEJIE_PLACES.items():  # Hejie's places (M2 sprint 10, step 3)
        if anchor(name, hx, hy, reach=9.0) is None:
            print("graph: WARNING: no ground for %s near (%.0f, %.0f)" % (name, hx, hy))
    for name, (sx_, sy_) in SAMKHA_PLACES.items():  # Samkha's places (M2 sprint 11, step 5)
        if anchor(name, sx_, sy_, reach=6.0) is None:
            print("graph: WARNING: no ground for %s near (%.0f, %.0f)" % (name, sx_, sy_))
    market = json.load(open(MARKET, encoding="utf-8")) if os.path.exists(MARKET) else {"stalls": [], "keeps": [7.75, 11.75]}
    keeper_of = {}  # who -> (its stall's place, its seat behind the stall)
    del MARKET_PLACES[:]
    for stl in market["stalls"]:  # each stall's front, where its buyers stand (step 4)
        fx, fy = math.sin(math.radians(stl["facing"])), math.cos(math.radians(stl["facing"]))
        d_ = STALL_SIZE.get(stl["kit"], (2.5, 2.0))[1]
        if anchor(stl["id"], stl["pos"][0] + fx * (d_ / 2 + 0.9), stl["pos"][1] + fy * (d_ / 2 + 0.9), reach=2.5) is None:
            print("graph: WARNING: no ground before the stall %s" % stl["id"])
            continue
        MARKET_PLACES.append(stl["id"])
        if stl.get("keeper"):
            back = STALL_KEEPER.get(stl["kit"], 0.8)
            kx, ky = stl["pos"][0] - fx * back, stl["pos"][1] - fy * back
            keeper_of[stl["keeper"]] = (stl["id"], {"name": "stall", "at": [round(kx, 3), round(ky, 3), round(float(stl["pos"][2]), 3)],
                                                  "face": [round(fx, 4), round(fy, 4)], "pose": "stand"}, stl["kit"])
    homes, unreached = [], []  # the houses whose door reaches the town, and those whose door has no ground of it within 4 m
    for h in houses:
        if not (GROUND_BOX[0] + 5 < h["pos"][0] < GROUND_BOX[2] - 5 and GROUND_BOX[1] + 5 < h["pos"][1] < GROUND_BOX[3] - 5):
            continue
        p = door(h, LD.kit_file(h), out=1.3)
        if p and anchor(h["id"], *p) is not None:
            homes.append(h["id"])
        elif p:
            unreached.append(h["id"])
    for h in hj["houses"] + [b for b in town["buildings"] if b["id"] in hj["pads"] and hj["pads"][b["id"]].get("kit") and b.get("type") != "gate tower"]:
        f = "%s_v%d" % (h["kit"], h["seed"]) if "kit" in h else hj["pads"][h["id"]]["kit"]
        side = json.load(open(os.path.join(KIT, f + ".json")))
        sock = "SOCK_DOOR_1" if "SOCK_DOOR_1" in side["socket_pos"] else "SOCK_GATE_1"
        p = door(dict(h, pos=[h["pos"][0], h["pos"][1], 0.0]), f, out=1.3, sock=sock)
        if p and anchor(h["id"], *p) is not None:
            homes.append(h["id"])
        elif p:
            unreached.append(h["id"])

    # The graph, and the fastest ways through it.
    XYZ = np.concatenate([xyz[0], np.array([e[:3] for e in extra])])
    N = len(XYZ)
    n_doors = len(homes)  # every house door in the slice with ground before it
    S, D, C = np.concatenate(src), np.concatenate(dst), np.concatenate(cost)
    # the cheapest of any duplicate edges (csr_matrix would add them)
    order = np.lexsort((C, D, S))
    S, D, C = S[order], D[order], C[order]
    first = np.ones(len(S), dtype=bool)
    first[1:] = (S[1:] != S[:-1]) | (D[1:] != D[:-1])
    S, D, C = S[first], D[first], C[first]
    G = csr_matrix((C, (S, D)), shape=(N, N))
    # the town's walkable whole: what can be reached from Tsongra and back (a door on an island of ground is left out)
    _, comp = connected_components(G, directed=True, connection="strong")
    main_c = comp[anchors["tsongra"]]
    cut_off = sorted(k for k, v in anchors.items() if comp[v] != main_c)
    for k in cut_off:
        if not k.startswith("H-"):
            print("graph: WARNING: %s is cut off from Tsongra" % k)
    homes = [h for h in homes if comp[anchors[h]] == main_c]
    every_home = list(homes)  # every house door on the walkers' ground that reaches Tsongra (the quarter's people's homes)
    roster = [(i, q) for i, q in enumerate(json.load(open(ROSTER, encoding="utf-8"))["people"])  # (each its place in the whole
              if q.get("day") in ("shol", "hejie", "samkha", "court")] if os.path.exists(ROSTER) else None  # roster: its random
    # stream its own, whoever else walks today; M2 sprint 11, step 5)
    walkers = []
    if roster is None:  # before the population (M2 sprint 10): the slice's twenty, drawn as before
        homes = [h for h in homes if BOX[0] + 5 < house_xy[h][0] < BOX[2] - 5 and BOX[1] + 5 < house_xy[h][1] < BOX[3] - 5]
        rng = random.Random(SEED)
        rng.shuffle(homes)
        homes = homes[:WALKERS]
        people_ = [{"who": None, "role": None, "from": h, "w_i": w_i} for w_i, h in enumerate(homes)]
        visit_pool = homes
    else:  # the day's drawn (tools/town/roster.py): Shöl's own from their doors, those who come in from their way in
        people_, indoors = [], 0
        for w_i, q in roster:
            fr = q.get("from")
            if q["role"] in UNDRAWN or fr is None or fr not in anchors or comp[anchors[fr]] != main_c:
                indoors += 1  # a toddler carried, a nun (no figure yet), or a door cut off from the town: not walking today
                continue
            people_.append(dict(q, w_i=w_i))
        homes = sorted({q["from"] for q in people_ if q["from"].startswith("H-") or q["from"].startswith("HEJ-")})
        shol_homes = [h for h in homes if h.startswith("H-SHL-")]
        visit_pool = sorted(random.Random(SEED).sample(shol_homes, min(VISITED, len(shol_homes))))  # the houses visited, read in, called at
        print("graph: the day's drawn: %d walk in Shöl, Hejie and Samkha (%d from their own doors, %d to the Pönpo's hearing), %d stay in" % (
            len(people_), sum(1 for q in people_ if q["from"].startswith("H-") or q["from"].startswith("HEJ-")), sum(1 for q in people_ if q.get("day") == "court"), indoors))
    places = sorted(set([k for k in DAY if k != "visit" and k in anchors and comp[anchors[k]] == main_c] + ["mani_s"] + homes + visit_pool
                        + [q["from"] for q in people_ if not q["from"].startswith("H-")] + [k for k in ("chang",) if k in anchors and comp[anchors[k]] == main_c]
                        + [k for k in HEJIE_STAY if k in anchors and comp[anchors[k]] == main_c] + [k for k in MARKET_PLACES if comp[anchors[k]] == main_c]
                        + [k for k in SAMKHA_STAY if k in anchors and comp[anchors[k]] == main_c]
                        + [k for k in day_places() if k in anchors and comp[anchors[k]] == main_c]))  # (every place the days go to: a place
    # missing here had made every errand to or from it fail, unseen)
    tdist = dijkstra(G, directed=True, indices=[anchors[a] for a in places])  # seconds at the reference pace
    row = {a: i for i, a in enumerate(places)}
    loop_ref = float(tdist[row["mani"], anchors["mani_s"]] + tdist[row["mani_s"], anchors["mani"]])
    kinds_used = set()
    for q in people_:
        w_i, home = q["w_i"], q["from"]
        if q["who"] is None:  # TM and TW, two of each (people2/body.py); the monk a stand-in
            kind = "monk" if w_i % 7 == 3 else ["townsman", "townswoman", "townsman_b", "townswoman_b"][w_i % 4]
            old = w_i % 6 == 5
        else:  # its figure by its archetype and sex, the same each day it is drawn (its id's hash)
            choices = BODIES.get((q["role"], q["sex"])) or BODIES.get((q["role"], None)) or ["townsman" if q["sex"] == "m" else "townswoman"]
            if q.get("day") == "court":  # a party sits on the hall's felt: a body with the cross-legged sit (the town's first four
                # have only the town's clips: body.py TOWN), and nothing on its back (the water carriers' barrels, the porters' loads)
                choices = [c for c in choices if c not in TOWN_FOUR and not c.startswith(("water_", "porter"))] or choices
            kind = choices[zlib.crc32(q["who"].encode()) % len(choices)]
            old = q["role"] == "TE" or int(q.get("age", 30)) >= 60
            kinds_used.add(kind)
        young = q["who"] is not None and int(q.get("age", 30)) < 15
        rng_w = random.Random(SEED * 1000 + w_i)
        pace = rng_w.uniform(0.6, 0.8) if old else (rng_w.uniform(1.0, 1.3) if young else rng_w.uniform(0.9, 1.2))
        up = 1.2 if old else rng_w.uniform(0.6, 0.9)
        wk = {"kind": kind, "old": old, "pace": round(pace, 2), "up": round(up, 2), "down": 0.5, "home": home}
        if q["who"] is not None:
            wk.update({"who": q["who"], "roster": True, "role": q["role"]})

        def trav(a, b, pace=pace):
            if a not in row or b not in anchors:
                return None  # a place the town's ground does not reach
            d = float(tdist[row[a], anchors[b]])
            return None if not np.isfinite(d) else d * PACE / pace * RATE
        loop_min = loop_ref * PACE / pace * RATE
        if q["who"] is None:
            wk["day"] = plan_day(random.Random(SEED * 1000 + w_i), wk, visit_pool, trav, loop_min)
        elif q.get("day") == "hejie":  # Hejie's own in Hejie (step 3)
            wk["day"] = hejie_day(random.Random(SEED * 1000 + w_i), wk, trav, q["role"])
        elif q.get("day") == "samkha":  # Samkha's own about Samkha (M2 sprint 11, step 5)
            wk["day"] = samkha_day(random.Random(SEED * 1000 + w_i), wk, trav, q["role"])
        elif q.get("day") == "court":  # a party to the morning hearing: its felt in the hall (world/samkha_people.gd)
            wk["day"] = court_day(random.Random(SEED * 1000 + w_i), wk, visit_pool, trav, loop_min, q["case"])
            if wk["day"] is None:
                print("graph: WARNING: %s cannot reach the castle's steps for its case" % q["who"])
                wk["day"] = visitor_day(random.Random(SEED * 1000 + w_i), wk, visit_pool, trav, loop_min, q)
            else:
                wk["court"] = [q["case"][0], q["case"][1], q["felt"]]
        elif home.startswith("H-SHL-"):  # Shöl's own: its archetype's day (step 3), a keeper's morning at its stall (step 4)
            keep = keeping(keeper_of, q["who"], kind, market["keeps"])
            wk["day"] = archetype_day(random.Random(SEED * 1000 + w_i), wk, visit_pool, trav, loop_min, q["role"], q["sex"], keep)
            if keep:
                wk["keeper"] = keep[0]
        else:
            keep = keeping(keeper_of, q["who"], kind, market["keeps"])
            wk["day"] = visitor_day(random.Random(SEED * 1000 + w_i), wk, visit_pool, trav, loop_min, q, keep)
            if keep:
                wk["keeper"] = keep[0]
        walkers.append(wk)
    # The named eight (sprint 6, step 3): their days as written, each stop's seat worked out.
    named_days = json.load(open(NAMED_DAYS, encoding="utf-8"))["people"]
    tread = (run - 1.6) / n
    down = (-st["u"][0], -st["u"][1])
    town_b = {b["id"]: b for b in town["buildings"]}
    house_of = {h["id"]: h for h in houses}
    for bid, (name, seed) in ENTER_TOWN.items():  # the gazetteer's buildings to enter, by their place's name
        if bid in town_b:
            house_of[name] = dict(town_b[bid], seed=seed, type="B")
    off_homes = {}  # a house to enter off the graph's ground (as the west edge's H-SHL-142 was before GROUND_BOX): its door's outside, the town grid
    carver = json.load(open(os.path.join(KIT, pfile + ".json")))
    seat_h = carver["socket_pos"]["SOCK_CARVER_1"][2]  # the carver's seat block: 0.42 m, its front edge at v -0.03
    seat_front = carver["ground"][0][1]

    def ahead(rot, u=0.0, v=-1.0):
        """The town grid's way of the kit's (u, v) for a building facing rot (the kit builds facing -v)."""
        x1, y1 = to_world(0.0, 0.0, rot, u, v)
        L = math.hypot(x1, y1)
        return x1 / L, y1 / L

    # Dechen-tsang's rooms (sprint 7, step 3; the kit's trading_house and its four rooms' furnishings): a seat in a room is
    # walked to by the house's own ground, which the graph does not walk: from its gate anchor over the gate's threshold,
    # across Yard 1, up the passage's six steps, across the guest yard to the room's door, over its sill and in (`via`).
    ROOMS = ["dechen_tibetan", "dechen_chinese", "dechen_guest", "dechen_kitchen", "dechen_chapel", "dechen_dolkar"]  # the house's ROOM sockets' order
    # Yard 3's rooms (M2 sprint 8): from the passage's head through the guest yard, up its six steps into the garden and up
    # the room's own stair (the chapel's stone one, Dolkar's timber one to her gallery), points in the house's frame
    YARD3_WAY = {"dechen_chapel": [(5.0, 13.5, 1.05), (11.8, 16.2, 1.05), (15.6, 16.2, 2.05), (19.0, 14.6, 2.05), (20.85, 14.6, 2.05),
                                   (20.85, 15.0, 2.05), (20.85, 18.8, 5.02)],
                 "dechen_dolkar": [(5.0, 13.5, 1.05), (11.8, 16.2, 1.05), (15.6, 16.2, 2.05), (18.4, 11.5, 2.05), (18.3, 8.95, 2.05),
                                   (18.65, 8.95, 2.05), (22.5, 8.95, 4.96), (22.8, 8.95, 4.96)]}
    house_kit = {}

    def room_frame(room):
        """A room's frame in the house's: its ROOM socket (on the floor at the doorway's inner face), the way into it,
        and its doorway's sill (the sidecar's sills: the gate's first, then the rooms' in the sockets' order)."""
        if not house_kit:
            house_kit.update(json.load(open(os.path.join(KIT, "trading_house_v1.json"))))
        k = ROOMS.index(room) + 1
        rx, ry, rz = house_kit["socket_pos"]["SOCK_ROOM_%d" % k]
        return rx, ry, rz, math.radians(house_kit["socket_yaw"]["SOCK_ROOM_%d" % k]), house_kit["sills"][k]

    def house_room_seat(parts, how, pose, place):
        """room:house_kitchen_b2_in_v<n>:seat:<k> at a town house to enter (sprint 8, ISS-105: anyone at home), its house
        the stop's place: the kitchen's k-th SEAT (sitting on its bench, as room_seat's, or cross-legged on it: ISS-088),
        reached from the house's door anchor by its outside stair's foot (STAIR), up the flight to the landing, over the
        sill and in (`via`); or room:house_room_e1_in_v<n>:spot:<x>:<y>[:<bearing>] in a poor house's one room (H-SHL-142,
        chapter 04, 4.2), standing, crouched or cross-legged on its floor there, in at its door from the ground (no stair,
        no sill). A poor house off the graph's ground keeps its door's outside as its anchor (`off_homes`)."""
        h = house_of[place]
        poor = h.get("type") == "E"
        side = json.load(open(os.path.join(KIT, ("poor_house_e1_in_v%d" if poor else "town_house_b2_in_v%d") % int(h["seed"]) + ".json")))
        rot = h.get("rot_deg", 180.0)
        W = lambda u, v, z: [round(v_, 3) for v_ in (*to_world(h["pos"][0], h["pos"][1], rot, u, v), float(h["pos"][2]) + z)]
        turn = math.radians(rot - 180.0)
        rx, ry, rz = side["socket_pos"]["SOCK_ROOM_1"]
        a = math.radians(side["socket_yaw"]["SOCK_ROOM_1"])
        ex, ey, nx, ny = math.cos(a - math.pi / 2), math.sin(a - math.pi / 2), math.cos(a), math.sin(a)
        local = lambda lx, ly: (rx + lx * ex + ly * nx, ry + lx * ey + ly * ny)
        if parts[1] == "seat":
            room_side = json.load(open(os.path.join(KIT, parts[0] + ".json")))
            sk = "SOCK_SEAT_%d" % int(parts[2])
            lx, ly, lz = room_side["socket_pos"][sk]
            fy = math.radians(room_side["socket_yaw"][sk])
            fx_, fy_ = math.cos(fy) * ex + math.sin(fy) * nx, math.cos(fy) * ey + math.sin(fy) * ny
            sx, sy = local(lx, ly)
            back = SIT_BACK - 0.04 if pose == "chair" else (0.0 if pose == "cross" else -0.3)
            u, v = sx + fx_ * back, sy + fy_ * back
            z = rz + lz - (SIT_DROP if pose == "chair" else (0.0 if pose == "cross" else lz))
            if pose not in ("chair", "cross"):
                fx_, fy_ = -fx_, -fy_
        else:
            u, v = local(float(parts[2]), float(parts[3]))
            z = rz
            b = math.radians(float(parts[4])) if len(parts) > 4 else 0.0
            fx_, fy_ = math.sin(b) * ex + math.cos(b) * nx, math.sin(b) * ey + math.cos(b) * ny
            if pose == "cross":  # the hips on the spot: the clip's are behind its root
                u, v = u + fx_ * CROSS_HIPS, v + fy_ * CROSS_HIPS
        f = (fx_ * math.cos(turn) + fy_ * math.sin(turn), -fx_ * math.sin(turn) + fy_ * math.cos(turn))
        if poor:  # in at the door from its yard, ducking (the walkers do not yet: ISS-125), onto the floor
            dx, dy, _ = side["socket_pos"]["SOCK_DOOR_1"]
            via = [W(dx - nx * 1.2, dy - ny * 1.2, 0.05), W(dx + nx * 0.3, dy + ny * 0.3, 0.05),
                   W(rx + nx * 0.6, ry + ny * 0.6, rz + 0.02)]
            if place not in anchors:
                off_homes[place] = W(dx - nx * 1.2, dy - ny * 1.2, 0.05)
            return W(u, v, z), f, via
        cx, cy, cz, yaw, w_, h_, d_ = side["sills"][0]
        sn = (math.cos(math.radians(yaw)), math.sin(math.radians(yaw)))
        fx0, fy0, _ = side["socket_pos"]["SOCK_STAIR_1"]
        via = [W(fx0, fy0, 0.05), W(cx - sn[0] * 0.9, cy - sn[1] * 0.9, cz + 0.05),  # the flight's foot, its landing
               W(cx, cy, cz + h_ + 0.02), W(cx + sn[0] * 0.9, cy + sn[1] * 0.9, cz + 0.15)]  # over the sill, in
        return W(u, v, z), f, via

    def room_seat(parts, how, pose, place=None):
        """room:<room>:seat:<n>, the room's n-th SEAT (sitting on its ledge, as the sitting clip wants: the feet before
        its front edge and under it), or room:<room>:spot:<x>:<y>[:<bearing>], standing that far into the room from the
        doorway's inner face (x along the door's wall), facing the bearing in the room (0 in, away from the door; 90 to
        its +x). Returns x, y, z, the facing and the way in, all in the town grid. A town house's kitchen: its own
        (house_room_seat)."""
        if (parts[0].startswith("house_kitchen") or parts[0].startswith("house_room") or parts[0].startswith("chang_room")) and place in house_of:
            return house_room_seat(parts, how, pose, place)
        if parts[0].startswith("headman_"):
            return headman_room_seat(parts, how, pose)
        room = parts[0]
        dh = town_b["SHL-04"]
        W = lambda u, v, z: [round(v_, 3) for v_ in (*to_world(dh["pos"][0], dh["pos"][1], dh.get("rot_deg", 180.0), u, v), float(dh["pos"][2]) + z)]
        turn = math.radians(dh.get("rot_deg", 180.0) - 180.0)  # the kit's frame against the town grid's
        rx, ry, rz, a, sill = room_frame(room)
        ex, ey, nx, ny = math.cos(a - math.pi / 2), math.sin(a - math.pi / 2), math.cos(a), math.sin(a)
        local = lambda lx, ly: (rx + lx * ex + ly * nx, ry + lx * ey + ly * ny)
        if parts[1] == "seat":
            side = json.load(open(os.path.join(KIT, room + "_v1.json")))
            sk = "SOCK_SEAT_%d" % int(parts[2])
            lx, ly, lz = side["socket_pos"][sk]
            fy = math.radians(side["socket_yaw"][sk])
            fx_, fy_ = math.cos(fy) * ex + math.sin(fy) * nx, math.cos(fy) * ey + math.sin(fy) * ny  # its facing, in the kit
            sx, sy = local(lx, ly)
            back = SIT_BACK - 0.04 if pose == "chair" else (0.0 if pose == "cross" else -0.3)  # standing: before the seat, facing it
            u, v = sx + fx_ * back, sy + fy_ * back
            z = rz + lz - (SIT_DROP if pose == "chair" else (0.0 if pose == "cross" else lz))  # cross-legged: on the bench (ISS-088)
            if pose not in ("chair", "cross"):
                fx_, fy_ = -fx_, -fy_
        else:
            u, v = local(float(parts[2]), float(parts[3]))
            z = rz
            b = math.radians(float(parts[4])) if len(parts) > 4 else 0.0
            fx_, fy_ = math.sin(b) * ex + math.cos(b) * nx, math.sin(b) * ey + math.cos(b) * ny
            if pose == "cross":  # the hips on the spot
                u, v = u + fx_ * CROSS_HIPS, v + fy_ * CROSS_HIPS
        f = (fx_ * math.cos(turn) + fy_ * math.sin(turn), -fx_ * math.sin(turn) + fy_ * math.cos(turn))
        cx, cy, cz, yaw, w_, h_, d_ = sill
        sn = (math.cos(math.radians(yaw)), math.sin(math.radians(yaw)))
        via = [W(0.0, -23.5, 0.37), W(0.0, -21.8, 0.07), W(0.0, 1.2, 0.04), W(0.0, 3.6, 1.05)]  # the gate, Yard 1, the passage
        back = 2.4  # before the sill, straight at it
        if room in YARD3_WAY:  # up to the landing or the gallery before the door (M2 sprint 8)
            via += [W(*q) for q in YARD3_WAY[room]]
            back = 0.75
        via += [W(cx - sn[0] * back, cy - sn[1] * back, cz + 0.05), W(cx, cy, cz + h_ + 0.02), W(cx + sn[0] * 0.9, cy + sn[1] * 0.9, cz + 0.15)]
        return W(u, v, z), f, via

    def dyard_seat(parts, pose):
        """dyard:<x>:<y>[:<bearing>] in Dechen-tsang's Yard 1 or its guest yard (its frame's x, y; the flags' level, the
        guest yard's a metre up), facing the bearing (clockwise from north), cross-legged with the hips on the spot: in
        at the gate, and up through the passage for the guest yard (M2 sprint 8, steps 3 and 4: the tea-sewers, the pieman
        and the dice; the bard's fire and its listeners)."""
        dh = town_b["SHL-04"]
        W = lambda u, v, z: [round(v_, 3) for v_ in (*to_world(dh["pos"][0], dh["pos"][1], dh.get("rot_deg", 180.0), u, v), float(dh["pos"][2]) + z)]
        b = math.radians(float(parts[2])) if len(parts) > 2 else 0.0
        f = (math.sin(b), math.cos(b))
        x, y = float(parts[0]), float(parts[1])
        via = [W(0.0, -23.5, 0.37), W(0.0, -21.8, 0.07)]  # over the gate's threshold
        z = 0.05
        if y > 3.3:  # the guest yard: up the passage's six steps
            via += [W(0.0, 1.2, 0.04), W(0.0, 3.6, 1.05)]
            z = 1.05
        if pose == "cross":
            x, y = x + f[0] * CROSS_HIPS, y + f[1] * CROSS_HIPS
        return W(x, y, z), f, via

    def roof_seat(parts):
        """roof:<x>:<y>[:<bearing>], standing on Dechen-tsang's master range roof (its frame's x, y; the roof's level), facing
        the bearing (clockwise from north): reached by the house's ground to the master range's door, then out of sight up
        its stairs to the roof's hatch (a via point marked "in"; sprint 7, step 6: the household at the roof's sang)."""
        dh = town_b["SHL-04"]
        if not house_kit:
            house_kit.update(json.load(open(os.path.join(KIT, "trading_house_v1.json"))))
        W = lambda u, v, z: [round(v_, 3) for v_ in (*to_world(dh["pos"][0], dh["pos"][1], dh.get("rot_deg", 180.0), u, v), float(dh["pos"][2]) + z)]
        hx, hy, hz = house_kit["socket_pos"]["SOCK_HATCH_6"]  # the master range's hatch, by its sang burner
        via = [W(0.0, -23.5, 0.37), W(0.0, -21.8, 0.07), W(0.0, 1.2, 0.04), W(0.0, 3.6, 1.05),  # the gate, Yard 1, the passage
               W(0.0, 15.4, 1.05), W(0.0, 17.1, 1.05), W(hx, hy, hz) + ["in"]]  # the master range's door; up inside to the hatch
        b = math.radians(float(parts[2])) if len(parts) > 2 else 0.0
        return W(float(parts[0]), float(parts[1]), hz), (math.sin(b), math.cos(b)), via

    # The headman's house SHL-19, every floor (M2 sprint 7, step 4; tibet-blender kit/headman.py): a seat in one of its
    # rooms is walked to from its yard's gate (the anchor "headman") by the house's own ground: into the yard, to the
    # stable's door over its sill, or up the outside stair to the family's door over its sill into the first floor's hall,
    # up the stair inside to the second's, up the hatch's notched log onto the roof (the log out of sight, "in"); then to
    # the room's doorway, over its sill if it has one, and in. Its frame is the town grid's (the gazetteer's place, facing
    # 180), its floors 0.06, 2.45, 5.15 m and the roof's deck 8.15 m over the yard.
    HEADMAN_ROOMS = ["stable", "hall1", "kitchen", "reception", "grain", "hall2", "shrine", "guest", "bed1", "bed2", "roofroom"]
    HEADMAN_FLOOR = {"stable": 0, "hall1": 1, "kitchen": 1, "reception": 1, "grain": 1, "hall2": 2, "shrine": 2, "guest": 2,
                     "bed1": 2, "bed2": 2, "roofroom": 3}
    HEADMAN_DOOR = {  # each room's way in from its hall: points in the house's frame, and the sill's height at its doorway
        "kitchen": ([(-0.1, -0.8)], None), "reception": ([(-0.05, -1.6)], (0.5, -1.6, 0.15)), "grain": ([(-0.3, -3.7)], None),
        "shrine": ([(-0.9, 0.9)], (-1.5, 0.9, 0.2)), "bed1": ([(-0.2, 0.9)], None), "bed2": ([(0.0, -2.0)], None),
        "guest": ([(0.0, -2.6), (-0.3, -3.65)], (-1.5, -3.65, 0.15))}
    hm_kit = {}

    def headman_way(room):
        """The way in from the yard's gate to a room's doorway, in the town grid: [x, y, z] points, "in" on the log's."""
        h = town_b["SHL-19"]
        W = lambda u, v, z, *f: [round(v_, 3) for v_ in (*to_world(h["pos"][0], h["pos"][1], h.get("rot_deg", 180.0), u, v), float(h["pos"][2]) + z)] + list(f)
        fl = HEADMAN_FLOOR[room]
        via = [W(4.6, -7.3, 0.02)]
        if fl == 0:
            return via + [W(-3.3, -6.2, 0.02), W(-3.3, -4.9, 0.36), W(-3.3, -3.7, 0.08)]
        via += [W(3.6, -5.53, 0.02), W(0.3, -5.53, 2.3), W(-0.53, -5.6, 2.3), W(-0.53, -4.79, 2.57), W(-0.53, -3.7, 2.47)]
        if fl == 1:
            z = 2.47
        else:
            via += [W(-0.95, -3.75, 2.47), W(-0.95, -0.3, 5.17), W(-0.95, 0.3, 5.17)]
            z = 5.17
            if fl == 3:
                via += [W(0.05, 1.0, 5.17), W(0.05, 3.85, 5.17), W(-0.55, 3.85, 5.17), W(-0.55, 1.6, 8.17, "in"), W(-0.55, 0.9, 8.17)]
                z = 8.17
                if room == "roofroom":
                    via += [W(0.5, -2.14, 8.17), W(1.7, -2.14, 8.23)]
                return via
        pts, sill = HEADMAN_DOOR.get(room, ([], None))
        via += [W(x, y, z) for x, y in pts]
        if sill:
            via.append(W(sill[0], sill[1], z - 0.02 + sill[2] + 0.02))
        return via

    def headman_room_seat(parts, how, pose):
        """room:headman_<room>:seat:<n> or room:headman_<room>:spot:<x>:<y>[:<bearing>] in the headman's house (as
        room_seat's, in that room's frame), reached by headman_way."""
        key = parts[0][len("headman_"):]
        h = town_b["SHL-19"]
        W = lambda u, v, z: [round(v_, 3) for v_ in (*to_world(h["pos"][0], h["pos"][1], h.get("rot_deg", 180.0), u, v), float(h["pos"][2]) + z)]
        turn = math.radians(h.get("rot_deg", 180.0) - 180.0)
        if not hm_kit:
            hm_kit.update(json.load(open(os.path.join(KIT, "headman_house_v1.json"))))
        k = HEADMAN_ROOMS.index(key) + 1
        rx, ry, rz = hm_kit["socket_pos"]["SOCK_ROOM_%d" % k]
        a = math.radians(hm_kit["socket_yaw"]["SOCK_ROOM_%d" % k])
        ex, ey, nx, ny = math.cos(a - math.pi / 2), math.sin(a - math.pi / 2), math.cos(a), math.sin(a)
        local = lambda lx, ly: (rx + lx * ex + ly * nx, ry + lx * ey + ly * ny)
        if parts[1] == "seat":
            side = json.load(open(os.path.join(KIT, parts[0] + "_v1.json")))
            sk = "SOCK_SEAT_%d" % int(parts[2])
            lx, ly, lz = side["socket_pos"][sk]
            fy = math.radians(side["socket_yaw"][sk])
            fx_, fy_ = math.cos(fy) * ex + math.sin(fy) * nx, math.cos(fy) * ey + math.sin(fy) * ny
            sx, sy = local(lx, ly)
            back = SIT_BACK - 0.04 if pose == "chair" else (0.0 if pose == "cross" else -0.3)
            u, v = sx + fx_ * back, sy + fy_ * back
            z = rz + lz - (SIT_DROP if pose == "chair" else (0.0 if pose == "cross" else lz))
            if pose not in ("chair", "cross"):
                fx_, fy_ = -fx_, -fy_
        else:
            u, v = local(float(parts[2]), float(parts[3]))
            z = rz
            b = math.radians(float(parts[4])) if len(parts) > 4 else 0.0
            fx_, fy_ = math.sin(b) * ex + math.cos(b) * nx, math.sin(b) * ey + math.cos(b) * ny
            if pose == "cross":
                u, v = u + fx_ * CROSS_HIPS, v + fy_ * CROSS_HIPS
        f = (fx_ * math.cos(turn) + fy_ * math.sin(turn), -fx_ * math.sin(turn) + fy_ * math.cos(turn))
        return W(u, v, z), f, headman_way(key)

    def headman_roof_seat(parts):
        """hroof:<x>:<y>[:<bearing>]: standing on the headman's roof (the house's frame; the deck at 8.15 m), facing the
        bearing (clockwise from north), up the house and its hatch's log (headman_way's roof)."""
        h = town_b["SHL-19"]
        W = lambda u, v, z: [round(v_, 3) for v_ in (*to_world(h["pos"][0], h["pos"][1], h.get("rot_deg", 180.0), u, v), float(h["pos"][2]) + z)]
        b = math.radians(float(parts[2])) if len(parts) > 2 else 0.0
        return W(float(parts[0]), float(parts[1]), 8.15), (math.sin(b), math.cos(b)), headman_way("roof")

    HEADMAN_FLOOR["roof"] = 3

    def seat_of(name, how, place):
        """Where at a place a named walker's feet go, which way it faces and how it rests: chair (sitting on a ledge),
        crouch or stand; None for the place's anchor itself. talkers:<tread>[:<across>] sits on the talkers' steps (the
        feet two treads down, facing Tsongra), crouches or stands on a tread; pitch is Pasang's seat block, facing the
        lane; pitch_helper crouches by the stone at his side; dechen_gate stands in Dechen-tsang's gateway, facing out;
        door stands at a house's door, facing out; stall:<k>[:<along>[:front]] stands behind the k-th fuel stall's counter
        (or before it, facing it); spot:<east>:<north>[:<bearing>] stands, sits or crouches that far off the place's
        anchor, facing the bearing (clockwise from north), or the way it came."""
        if not name:
            return None
        pose = {"sit": "chair", "crouch": "crouch", "cross": "cross"}.get(how, "stand")
        part = name.split(":")
        if part[0] == "talkers":
            k, off = int(part[1]), float(part[2]) if len(part) > 2 else 0.0
            s_e = -run + k * tread  # the front edge of tread k
            z_k = STAIR_Z - rise + (k + 1) * rise / n
            s_, z = ((s_e + 0.04 - SIT_BACK, z_k - SIT_DROP) if pose == "chair" else
                     (s_e + (0.22 if pose == "crouch" else 0.16), z_k))
            (x, y), f = st["at"](s_, off), down
        elif part[0] == "pitch":
            x, y = to_world(ppx, ppy, pfacing, 0.0, seat_front + 0.11 - SIT_BACK)
            z, f = ppz + seat_h - SIT_DROP - 0.02, ahead(pfacing)
        elif part[0] == "pitch_helper":
            x, y = to_world(ppx, ppy, pfacing, 0.9, -0.55)
            z, f = ppz, ahead(pfacing, 0.0, 1.0)
        elif part[0] == "dechen_gate":
            b = town_b["SHL-04"]
            x, y = to_world(b["pos"][0], b["pos"][1], 180.0, 0.0, -24.1)
            z, f = zat(x, y), ahead(180.0)
        elif part[0] == "door":
            x, y, z = (float(c) for c in XYZ[anchors[place]])
            f = ahead(house_of[place].get("rot_deg", 180.0))
        elif part[0] == "stall":
            b = town_b["SHL-29"]
            k, along = int(part[1]), float(part[2]) if len(part) > 2 else 0.0
            front = len(part) > 3 and part[3] == "front"  # a customer, before the counter, facing it
            x, y = to_world(b["pos"][0] + (k - 1) * 3.0, b["pos"][1], 180.0, along, -1.0 if front else 0.7)  # world/town.gd: three, 3 m apart
            z, f = zat(x, y), ahead(180.0, 0.0, 1.0 if front else -1.0)
        elif part[0] == "room":
            (x, y, z), f, via = room_seat(part[1:], how, pose, place)
            return {"name": name, "at": [x, y, z], "face": [round(f[0], 4), round(f[1], 4)], "pose": pose, "via": via}
        elif part[0] == "roof":
            (x, y, z), f, via = roof_seat(part[1:])
            return {"name": name, "at": [x, y, z], "face": [round(f[0], 4), round(f[1], 4)], "pose": pose, "via": via}
        elif part[0] == "hroof":
            (x, y, z), f, via = headman_roof_seat(part[1:])
            return {"name": name, "at": [x, y, z], "face": [round(f[0], 4), round(f[1], 4)], "pose": pose, "via": via}
        elif part[0] == "dyard":
            (x, y, z), f, via = dyard_seat(part[1:], pose)
            return {"name": name, "at": [x, y, z], "face": [round(f[0], 4), round(f[1], 4)], "pose": pose, "via": via}
        elif part[0] == "spot":
            ax, ay, _ = (float(c) for c in XYZ[anchors[place]])
            x, y = ax + float(part[1]), ay + float(part[2])
            z = zat(x, y)
            f = (math.sin(math.radians(float(part[3]))), math.cos(math.radians(float(part[3])))) if len(part) > 3 else None
        else:
            print("graph: WARNING: no seat %s" % name)
            return None
        if pose == "chair" and part[0] not in ("talkers", "pitch"):
            print("graph: WARNING: %s is not a seat to sit on" % name)
        return {"name": name, "at": [round(float(x), 3), round(float(y), 3), round(float(z), 3)],
                "face": [round(f[0], 4), round(f[1], 4)] if f else None, "pose": pose}

    generic_days = json.load(open(GENERIC_DAYS, encoding="utf-8"))["people"] if os.path.exists(GENERIC_DAYS) else {}
    people = [(k, v, False) for k, v in named_days.items()] + [(k, v, True) for k, v in generic_days.items()]
    taken = {v["home"] for k, v, g_ in people if not v["home"].startswith("near:")}  # the homes given, before any is chosen
    for key, nd, generic in people:
        home = nd["home"]
        if home.startswith("near:"):  # the nearest house door to a place that none of the others has, in Shöl (its places
            # all are; Samkha's houses by Dechen-tsang are its retainers' and servants', M2 sprint 11, step 2)
            near = XYZ[anchors[home[5:]]][:2]
            doors = sorted((math.dist(near, XYZ[v][:2]), k) for k, v in anchors.items()
                           if k.startswith("H-SHL-") and comp[v] == main_c and k not in taken)
            home = doors[0][1]
        taken.add(home)
        nd = dict(nd, home=home, day=[[home if st[0] == "home" else st[0]] + list(st[1:]) for st in nd["day"]])
        day, ok_ = [], True
        # a household that never leaves a house to enter off the graph's ground (the west edge was, ISS-105) is placed in it
        # all the same: its stops are in its own room, its anchor its door's outside (off_homes)
        stays = home in house_of and home not in anchors and all(st[0] == home for st in nd["day"])
        for place, arrive, leave, how, loops, seat in nd["day"]:
            if stays:
                day.append([place, float(arrive), float(leave), how, int(loops), seat_of(seat, how, place)])
                continue
            if place not in anchors or comp[anchors[place]] != main_c:
                print("graph: WARNING: %s's %s is not in the town's graph" % (key, place))
                ok_ = False
            day.append([place, float(arrive), float(leave), how, int(loops), seat_of(seat, how, place) if ok_ else None])
        if ok_:
            walkers.append({"kind": nd.get("body", key), "who": key, "named": True, "generic": generic, "old": False,
                            "pace": nd["pace"], "up": nd["up"], "down": nd["down"], "home": nd["home"], "day": day})
    pairs = set()
    for wk in walkers:
        stops = [s_[0] for s_ in wk["day"]]
        for a, b in zip(stops, stops[1:]):
            if a != b:
                pairs.add((a, b))
    for a, b in (("yak_gate", "tsongra"), ("tsongra", "lhakhang")):  # the performance route PT-slice (tests/terrain/s3.gd)
        if a in anchors and b in anchors:
            pairs.add((a, b))
    for a, b in (("ramp_foot", "dechen"), ("dechen", "ramp_foot")):  # the caravan CV-02 up the north ramp and back (step 5)
        if a in anchors and b in anchors:
            pairs.add((a, b))
    pairs.add(("mani", "mani_s"))  # the kora round the wall: east on its north side, round its east end, west on its south
    pairs.add(("mani_s", "mani"))  # and round its west end, north, back to the start
    sources = sorted({a for a, b in pairs})
    dist, pred = dijkstra(G, directed=True, indices=[anchors[departs.get(a, a)] for a in sources], return_predecessors=True)

    def clear_way(a, b):
        """String pulling's test: on walkable cells 0.3 m either side, no steeper than the lattice's steps, over a
        steep facet only where both ends are, and the Mani Lane's way kept at every sample."""
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L < 1e-6:
            return True
        n = max(1, int(L / 0.25))
        dx, dy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        sx, sy = -dy, dx
        ca, cb = ground.cell(*a[:2]), ground.cell(*b[:2])
        steep_ok = ca is not None and cb is not None and steep[ca] and steep[cb]
        prev = None
        mxs, mys = [], []
        for k in range(n + 1):
            px, py = a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n
            for off in (0.3, -0.3):
                if ground.cell(px + sx * off, py + sy * off) is None:
                    return False
            c = ground.cell(px, py)
            if c is None or (steep[c] and not steep_ok):
                return False
            h = float(gz[c])
            if prev is not None and abs(h - prev) > lim * 0.25 + 0.06:
                return False
            prev = h
            mxs.append(px)
            mys.append(py)
        return bool(np.all(allowed(np.array(mxs), np.array(mys), np.full(len(mxs), dx), np.full(len(mxs), dy))))

    routes = {}
    worst = 0.0
    for a, b in sorted(pairs):
        row = sources.index(a)
        ka, kb = anchors[departs.get(a, a)], anchors[b]
        if not np.isfinite(dist[row, kb]):
            print("graph: WARNING: no way from %s to %s" % (a, b))
            continue
        path = [kb]
        while path[-1] != ka:
            path.append(int(pred[row, path[-1]]))
        path.reverse()
        # runs on the ground string-pulled and sampled every metre on it; flights and the stair's axis kept whole
        pts, segk, segn = [tuple(XYZ[path[0]])], [], []
        run_pts = [tuple(XYZ[path[0]])]

        def flush(run):
            if len(run) < 2:
                return
            simple = R.simplify(run, clear_way)
            for p0, p1 in zip(simple, simple[1:]):
                L = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
                m = max(1, int(round(L / 1.0)))
                for k in range(1, m + 1):
                    qx, qy = p0[0] + (p1[0] - p0[0]) * k / m, p0[1] + (p1[1] - p0[1]) * k / m
                    pts.append((qx, qy, zat(qx, qy)))
                    segk.append(0)
                    segn.append(0)

        for u_, v_ in zip(path, path[1:]):
            fl = special.get((u_, v_))
            on_axis = kind_of(u_) == 1 and kind_of(v_) == 1
            if fl or on_axis:
                flush(run_pts)
                if fl and fl[1]:  # on the level to its first tread, up or down its steps, on the level from its top
                    pts.extend([tuple(fl[1][0]), tuple(fl[1][1]), tuple(XYZ[v_])])
                    segk.extend([0, 1, 0])
                    segn.extend([0, int(fl[0]), 0])
                else:
                    pts.append(tuple(XYZ[v_]))
                    segk.append(1 if fl else 0)
                    segn.append(int(fl[0]) if fl else 0)
                run_pts = [tuple(XYZ[v_])]
            else:
                run_pts.append(tuple(XYZ[v_]))
        flush(run_pts)
        t_ref = float(dist[row, kb])
        worst = max(worst, t_ref)
        routes["%s>%s" % (a, b)] = {"p": [round(float(c), 2) for q in pts for c in q], "k": segk, "n": segn, "t": round(t_ref, 1)}
    # the Mani Lhakhang's hall: in at the door, round the great wheel clockwise twice at its bars, and out
    lh = next(b for b in town["buildings"] if b["id"] == "SHL-08")
    cx, cy, cz = lh["pos"][0], lh["pos"][1], float(lh["pos"][2]) + 0.02
    rot = lh.get("rot_deg", 180.0)
    hall = [tuple(XYZ[anchors["lhakhang"]])]
    for u, v in ((0.0, -6.0), (0.0, -3.4)):  # the door, and in
        hall.append((*to_world(cx, cy, rot, u, v), cz))
    a0 = math.atan2(hall[-1][1] - cy, hall[-1][0] - cx)
    for k in range(0, 33):
        a = a0 - k * math.pi / 8  # clockwise seen from above
        hall.append((cx + 2.2 * math.cos(a), cy + 2.2 * math.sin(a), cz))
    for u, v in ((0.0, -3.4), (0.0, -6.0)):
        hall.append((*to_world(cx, cy, rot, u, v), cz))
    hall.append(tuple(XYZ[anchors["lhakhang"]]))
    routes["wheel"] = {"p": [round(float(c), 2) for q in hall for c in q], "k": [2] * (len(hall) - 1), "n": [0] * (len(hall) - 1)}
    mn = routes.get("mani>mani_s")
    ms = routes.get("mani_s>mani")
    if mn and ms:  # the kora round the wall, one loop from its west end's north side
        routes["mani_loop"] = {"p": mn["p"] + ms["p"][3:], "k": mn["k"] + ms["k"], "n": mn["n"] + ms["n"],
                               "t": round(mn["t"] + ms["t"], 1)}
    if "west_mani" in anchors:  # once round the western mani wall's first section, clockwise: up its west side, through the
        # way to the next, down its east side and round its foot (tools/town/mani.py WEST_SECTIONS; M2 sprint 6, step 6)
        bed = lambda s_: wa[2] + (wb[2] - wa[2]) * min(max(s_, 0.0), wL) / wL
        corners = [(4.0, -2.2), (63.5, -2.2), (63.5, 2.2), (0.8, 2.2), (0.8, -2.2), (4.0, -2.2)]
        loop = []
        for (s0_, l0), (s1_, l1) in zip(corners, corners[1:]):
            n_ = max(1, int(math.hypot(s1_ - s0_, l1 - l0)))
            for i in range(n_):
                q = i / n_
                s_, l_ = s0_ + (s1_ - s0_) * q, l0 + (l1 - l0) * q
                loop.append((*west_at(s_, l_), bed(s_)))
        loop.append((*west_at(4.0, -2.2), bed(4.0)))
        loop[0] = tuple(XYZ[anchors["west_mani"]])
        loop[-1] = tuple(XYZ[anchors["west_mani"]])
        routes["mani_loop_west_mani"] = {"p": [round(float(c), 2) for q in loop for c in q], "k": [0] * (len(loop) - 1),
                                         "n": [0] * (len(loop) - 1),
                                         "t": round(sum(math.dist(a_[:2], b_[:2]) for a_, b_ in zip(loop, loop[1:])) / PACE, 1)}
    def stretch(d, kind, steps, wk):
        """A stretch's time in real seconds, as TownSim times it (autoload/town_sim.gd `_stretch`): a flight's steps, a
        stretch steeper than 45 degrees as steps of 0.2 m, else Tobler's function of its slope at the walker's pace."""
        if kind == 1:
            return steps * (wk["up"] if d[2] > 0 else wk["down"])
        flat = math.hypot(d[0], d[1])
        if abs(d[2]) > flat and abs(d[2]) > 0.3:
            return abs(d[2]) / 0.2 * (wk["up"] if d[2] > 0 else wk["down"])
        return flat / (wk["pace"] * math.exp(-3.5 * (abs(d[2] / max(flat, 0.01) + 0.05) - 0.05)))

    def walk_min(name, wk):
        r = routes.get(name)
        if not r:
            return 0.0
        p = r["p"]
        pts = [p[i:i + 3] for i in range(0, len(p), 3)]
        return sum(stretch([b_ - a_ for a_, b_ in zip(pts[k], pts[k + 1])], r["k"][k], r["n"][k], wk) for k in range(len(pts) - 1)) * RATE

    def seat_min(q, pl, wk):
        """The walk from a place's anchor onto a seat (or off it), as TownSim walks it: by its way (a room's) or straight."""
        pts = [list(XYZ[anchors[pl]]) if pl in anchors else list(off_homes[pl])] + q.get("via", []) + [q["at"]]
        return sum(stretch([pts[k + 1][i] - pts[k][i] for i in range(3)], 0, 0, wk) for k in range(len(pts) - 1)) * RATE

    slack = {}  # each of the twenty's least time to spare between leaving one place and being due at the next (game minutes)
    for wk in walkers:
        if not wk.get("named"):
            continue
        least = None
        for a, b in zip(wk["day"], wk["day"][1:]):
            a = list(a)
            if a[3] == "mani":  # it leaves when its loops round the wall are done, if that is later
                loop_t = walk_min("mani_loop" if a[0] == "mani" or "mani_loop_" + a[0] not in routes else "mani_loop_" + a[0], wk)
                a[2] = max(a[2], a[1] + a[4] * loop_t)
            elif a[3] == "wheel":
                a[2] = max(a[2], a[1] + walk_min("wheel", wk))
            walk = walk_min("%s>%s" % (a[0], b[0]), wk) + sum(seat_min(q, pl, wk) for q, pl in ((a[5], a[0]), (b[5], b[0])) if q)
            if a[0] == b[0] and a[5] and b[5] and a[5].get("via") and b[5].get("via"):  # two rooms of one house: TownSim goes
                va, vb = a[5]["via"], b[5]["via"]  # back only to where their ways part, and on (autoload/town_sim.gd)
                m = 0
                while m < min(len(va), len(vb)) and va[m] == vb[m]:
                    m += 1
                if m:
                    pts = [a[5]["at"]] + va[m - 1:][::-1] + vb[m:] + [b[5]["at"]]
                    walk = sum(stretch([pts[k + 1][i] - pts[k][i] for i in range(3)], 0, 0, wk) for k in range(len(pts) - 1)) * RATE
            spare = b[1] - a[2] - walk
            if least is None or spare < least[0]:
                least = (spare, b[0], b[1])
            if spare < -0.5:
                print("graph: WARNING: %s is due at %s at %02d:%02d but can be there only %.0f game minutes late" % (
                    wk["who"], b[0], int(b[1]) // 60, int(b[1]) % 60, -spare))
        slack[wk["who"]] = least
    # The caravan CV-02's way (sprint 6, step 5; chapter 06, 8.4-8.5): over the lower bridge's deck from the slot's south side
    # to the north ramp's foot, up the ramp by its route to Dechen-tsang's gate, then (the house's own ground, which the
    # graph does not walk) through the gate over its threshold, across Yard 1 north of the tea stacks, through the animal
    # passage under the east range and into Yard 0, the stable yard, where ten places stand in two files before the
    # platform the loads are lifted onto (the kit's trading_house: kit/trading.py's yard and passage; the town's placing).
    caravan = None
    if "ramp_foot" in anchors and "ramp_foot>dechen" in routes:
        dh = town_b["SHL-04"]
        hx, hy, hz = dh["pos"][0], dh["pos"][1], float(dh["pos"][2])
        W = lambda u, v, dz=0.0: [round(hx + u, 2), round(hy + v, 2), round(hz + dz, 2)]  # the kit's (u, v), rot 180
        pv = -23.0 + (-3.0 - -23.0) * 2.5 / 6  # kit/trading.py: the animal passage in the east range's third bay
        foot = XYZ[anchors["ramp_foot"]]
        inside = [W(0.0, -25.0), W(0.0, -23.5, 0.35), W(0.0, -21.5), W(3.0, -16.0), W(10.0, pv), W(12.8, pv),  # the gate, Yard 1
                  W(14.3, pv), W(19.3, pv), W(21.5, pv)]  # the passage (3 m wide, 2.4 m high, 5 m long), Yard 0
        spots = []
        for k in range(10):  # two files, the first to arrive nearest the platform; facing it, north
            spots.append(W(29.0 - 4.0 * (k % 2) - 2.5, -4.0 - 3.0 * (k // 2) - 2.5) + [180.0])
        dz = json.load(open(os.path.join(ROOT, "data", "north_ramp.json")))["foot"][2]  # the deck's level: the ramp's foot
        # M2 sprint 3: the arrival's road before the deck, from SER-20 along the cliff gallery, under the Gate Chorten, past
        # the eight chortens (the south branch) to the south pavilion's toll, then back along the rim and down the south
        # ramp's legs to the lower bridge's south end (data/arrival.json, data/south_ramp.json)
        road, road_ramp = [], 0
        ap, sp_ = os.path.join(ROOT, "data", "arrival.json"), os.path.join(ROOT, "data", "south_ramp.json")
        sr_ = os.path.join(ROOT, "data", "serchu_road.json")
        if os.path.exists(ap) and os.path.exists(sp_):
            road = [list(q) for q in json.load(open(ap))["road_west"]]
            if os.path.exists(sr_):  # M2 sprint 12, step 6: from further back, down the north bank's road, through the Zampa's
                # gateway chorten and over its deck, down the south bank's R-01 past the mani wall by its south side to the
                # gallery's east end (data/serchu_road.json), then on as before (past SER-20 on its south side, not through it)
                srd = json.load(open(sr_))
                road = [list(q) for q in reversed(srd["north_path"])] + [list(q) for q in srd["path"]] + road[2:]
            ramp = json.load(open(sp_))
            legs = [ln for ln in ramp["lanes"] if ln["id"] == "SAM-06S.a" or (ln["id"].startswith("SAM-06S.") and ln["id"][8:].isdigit())]
            road_ramp = len(road)
            for ln in legs:
                fx, fy = ln["from"]
                ux, uy = ln["dir"]
                L = ln["length"]
                for f in (0.0, 1.0):
                    road.append([round(fx + ux * L * f, 2), round(fy + uy * L * f, 2), round(ln["z_a"] + (ln["z_b"] - ln["z_a"]) * f, 2)])
            road.append([-55.0, -118.0, dz])
        caravan = {"road": road, "road_ramp": road_ramp,
                   "deck": [[-55.0, -118.0, dz], [-55.0, -103.2, dz], [round(float(foot[0]), 2), round(float(foot[1]) + 0.5, 2), round(float(foot[2]), 2)]],
                   "up": "ramp_foot>dechen", "down": "dechen>ramp_foot", "inside": inside, "passage": [6, 7],
                   "spots": spots, "platform": W(24.65, -4.4) + [180.0]}
    # Everyone who stands at a place without a seat of their own is given one (ISS-094, Greg's walk, 27 Sep 2026: they
    # all stood on the place's anchor, one on top of another): the nearest spot round the anchor, on rings a metre
    # apart, that is walkable ground in a straight walk from it and that no one else holds at those minutes (a seat
    # given in the days counts), facing the anchor, as a loose gathering stands; out to 7.3 m since the day's drawn filled
    # the market (M2 sprint 10, step 2).
    rings = [(0.0, 0.0)] + [(r * math.cos(a), r * math.sin(a)) for r, n_ in ((1.0, 6), (1.9, 10), (2.8, 14), (3.7, 18), (4.6, 22), (5.5, 26), (6.4, 30), (7.3, 34))
                            for a in [2.0 * math.pi * (q + 0.5 * (r > 1.5)) / n_ for q in range(n_)]]
    held = {}  # place -> [(x, y, from, until)]
    for wk in walkers:
        for s_ in wk["day"]:
            if len(s_) > 5 and s_[5]:
                held.setdefault(s_[0], []).append((s_[5]["at"][0], s_[5]["at"][1], s_[1], s_[2]))
    stops = sorted(((s_[1], w_i, k) for w_i, wk in enumerate(walkers) for k, s_ in enumerate(wk["day"])
                    if s_[3] != "inside" and not (len(s_) > 5 and s_[5]) and s_[0] in anchors and not s_[0].startswith("H-")))
    spread, crowded = 0, 0
    for _, w_i, k in stops:
        s_ = walkers[w_i]["day"][k]
        place, t0, t1 = s_[0], s_[1], s_[2]
        ax, ay, _az = (float(c) for c in XYZ[anchors[place]])
        got = None
        for dx, dy in rings:
            n_ = near_node(ax + dx, ay + dy, reach=0.75, straight=False) if (dx or dy) else anchors[place]  # the 1 m lattice
            if n_ is None:
                continue
            qx, qy, qz = (float(c) for c in XYZ[n_])
            if (dx or dy) and not clear_line((ax, ay), (qx, qy), skip=0.6):  # an anchor may stand on a door's step
                continue
            if place == "mani" and (qx - bax) * wu[0] + (qy - bay) * wu[1] > -0.3:  # the kora's start: waiting west of the
                continue  # wall's west end, so the step back to it never goes the wrong way along the wall (M2 sprint 10)
            if any(math.hypot(qx - hx, qy - hy) < 0.9 and t0 < h1 + 1.0 and h0 < t1 + 1.0 for hx, hy, h0, h1 in held.get(place, [])):
                continue
            got = (qx, qy, qz)
            break
        if got is None:
            crowded += 1
            continue
        held.setdefault(place, []).append((got[0], got[1], t0, t1))
        f = (ax - got[0], ay - got[1])
        L = math.hypot(*f)
        seat = {"name": "spot", "at": [round(got[0], 3), round(got[1], 3), round(got[2], 3)],
                "face": [round(f[0] / L, 4), round(f[1] / L, 4)] if L > 0.3 else None, "pose": "stand"}
        if len(s_) > 5:
            s_[5] = seat
        else:
            s_.append(seat)
        spread += 1
    print("graph: %d stops at a place without a seat given their own spot round it (%d with none free left on the anchor)" % (spread, crowded))
    walkers = [w for w in walkers if not w.get("roster")] + [w for w in walkers if w.get("roster")]  # the written walkers
    # first: the town's lookups by a figure's name (the caravan's drovers, the headman's groom) find them before the day's drawn
    json.dump({"about": "The street graph's walkers, from tools/town/graph.py: each a home and a default day, [place, arrive, leave, how, loops] in game minutes from midnight (how: stand, inside, wheel, mani; loops round the mani wall), and for the named eight (named: true, their kind their key; data/named_days.json) a sixth, the seat: where at the place the feet go (at, the town grid), which way it faces (face) and how it rests (pose: chair, crouch, stand), or null for the place itself (how also sit, talk, crouch); the routes between them, each its points (x, y, z in the town grid, flat) and per stretch its kind (0 walked on the ground, 1 a flight of `n` steps, 2 in a hall) and its time at the reference pace (seconds); `wheel` in at the Mani Lhakhang's door and twice round the great wheel, `mani_loop` once round the mani wall. Regenerated with the town.",
               "pace": PACE, "up": UP, "down": DOWN, "rate": RATE,
               "anchors": dict({k: [round(float(c), 2) for c in XYZ[v]] for k, v in anchors.items()},
                               **{k: [round(float(c), 2) for c in v] for k, v in off_homes.items()}),
               "walkers": walkers, "routes": routes, "caravan": caravan,
               "kinds": sorted(kinds_used) if kinds_used else ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]}, open(OUT, "w"), separators=(",", ":"))
    n_edges = len(S)
    lens = {k: sum(math.hypot(r["p"][3 * i + 3] - r["p"][3 * i], r["p"][3 * i + 4] - r["p"][3 * i + 1]) for i in range(len(r["k"])))
            for k, r in routes.items()}
    near_only = [k for k in standins if k.startswith("H-")]
    summary = ("%d nodes (%d on the 1 m lattice, %d on the stair's axis, %d anchors), %d edges, one way on the Mani Lane; %d flights "
               "(the Sky Stair's %d, the talkers' and Tsongra's steps, %d side lanes'). Of %d house doors, %d reach the town, %d of them "
               "only to ground up to 4 m off (the apron before them walled in by its neighbours' pads: %s), and %d do not (%s); the "
               "workshops stood in for: %s. %d walkers, %d routes, %.0f m in all, the longest %.0f m" % (
                   N, n_lat, len(axis), len(anchors), n_edges, len(special) // 2, sum(1 for k in special if k[0] in axis and k[1] in axis) // 2,
                   n_flights, n_doors + len(unreached), n_doors, len(near_only), ", ".join(near_only) or "none", len(unreached),
                   ", ".join(unreached) or "none", ", ".join(k for k in standins if not k.startswith("H-")) or "none", len(walkers),
                   len(routes), sum(lens.values()), max(lens.values())))
    print("graph: " + summary + " -> " + os.path.relpath(OUT, ROOT))
    lines = ["# The street graph (chapter 11, 12.3)", "",
             "_Written by `tools/town/graph.py` (M1 sprint 4, step 4; days since sprint 6, step 1): the slice's walkable ground on a 1 m lattice, its flights, the Mani Lane one way, and the walkers' days and routes. Times at the reference pace (%.1f m/s, %.2f s a step up, %.2f down)._" % (PACE, UP, DOWN), "",
             summary + ".", "", "| Walker | Kind | Pace (m/s) | Home | Out at | The day | Home for the night | Walked (m) |", "|---|---|---|---|---|---|---|---|"]
    hm = lambda m: "%02d:%02d" % (int(m) // 60, int(m) % 60)
    for k, wk in enumerate(walkers):
        stops = [s_[0] for s_ in wk["day"]]
        m = sum(lens.get("%s>%s" % (a, b), 0.0) for a, b in zip(stops, stops[1:]) if a != b)
        lines.append("| %d | %s%s | %.2f | %s | %s | %s | %s | %.0f |" % (
            k + 1, wk["kind"].replace("_", " "), ", old" if wk["old"] else "", wk["pace"], wk["home"], hm(wk["day"][0][2]),
            ", ".join("%s %s" % (hm(s_[1]), "home" if s_[0] == wk["home"] else (s_[0] if not s_[0].startswith("H-") else "a neighbour's")) for s_ in wk["day"][1:-1]),
            hm(wk["day"][-1][1]), m))
    out_at = {}
    for hh in (4.5, 6, 7, 9, 11, 13, 15, 16, 17, 19, 21, 0):
        mm = hh * 60
        out_at[hh] = sum(1 for wk in walkers if not any(s_[1] <= mm < s_[2] and s_[3] == "inside" for s_ in wk["day"]))
    lines += ["", "Out of doors (walking, standing, at the wheel or the wall), of %d: " % len(walkers) + ", ".join(
        "%s %d" % (hm(h * 60), n) for h, n in out_at.items()) + " (chapter 05, 8.1 has Shöl's 10, 70, 98, 112, 120, 104, 98, -, 102, 52, 24, 6 of about 120)."]
    lines += ["", "## The named eight and the twelve generic", "", "_Their days from `data/named_days.json` (M1 sprint 6, step 3; chapter 05, 4.2) and `data/generic_days.json` (step 4): each stop's arrival, what they do there and on which seat; the least time any of them has to spare between leaving one place and being due at the next, at their own pace (TownSim leaves as late as it can: the spare is time to stand at the place first)._", "",
              "| Who | Pace (m/s) | Home | The day | Least to spare |", "|---|---|---|---|---|"]
    for wk in walkers:
        if not wk.get("named"):
            continue
        least = slack.get(wk["who"])
        lines.append("| %s | %.2f | %s | %s | %s |" % (
            wk["who"].replace("_", " "), wk["pace"], wk["home"],
            ", ".join("%s %s (%s%s)" % (hm(s_[1]), s_[0], s_[3], ", " + s_[5]["name"] if s_[5] else "") for s_ in wk["day"][1:]),
            "%.1f min before %s at %s" % (least[0], least[1], hm(least[2])) if least else "-"))
    def in_hejie(place):  # a place inside Hejie's wall (tools/town/hejie.py WALL: x -462 to -214, y -142 to 12)
        if place not in anchors:
            return False
        x_, y_ = XYZ[anchors[place]][:2]
        return -463.0 < x_ < -213.0 and -143.0 < y_ < 13.0

    def in_samkha(place):  # Samkha's places, its houses (M2 sprint 11, step 5)
        return place in SAMKHA_PLACES or place.startswith("H-SAM-")

    out_by = []
    for hr in sorted(PRESENCE):
        m = hr * 60.0
        n_shol, n_hejie, n_samkha = 0, 0, 0
        for wk in walkers:
            k = next((i for i, s_ in enumerate(wk["day"]) if s_[1] <= m < s_[2]), None)
            if k is not None and wk["day"][k][3] == "inside":
                continue
            # at its stop, or walking to the next (counted where it is going)
            place = wk["day"][k][0] if k is not None else next((s_[0] for s_ in wk["day"] if s_[1] > m), wk["home"])
            if in_hejie(place):
                n_hejie += 1
            elif in_samkha(place):
                n_samkha += 1
            else:
                n_shol += 1
        out_by.append((hr, n_shol, PRESENCE[hr], n_hejie, PRESENCE_HEJIE[hr], n_samkha, PRESENCE_SAMKHA[hr]))
    print("graph: outdoors by the hour, Shöl, Hejie and Samkha (chapter 05, 8.1's): " + ", ".join("%02d:%02d %d (%d), %d (%d), %d (%d)" % (int(h), int(h % 1 * 60), n, w, nh, wh, ns, ws) for h, n, w, nh, wh, ns, ws in out_by))
    lines += ["", "## Outdoors by the hour", "", "_The walkers outdoors (standing at a place or walking between them, counted where they are going) against chapter 05, 8.1's Shöl, Hejie and Samkha columns (the simulated 300's, outdoors and visible; Shöl's 17:00 counts the roof sang's people on the roofs, which the walkers are not; Samkha's count the court's, the toll's and the ula yard's people, whom their scenes draw: world/samkha_people.gd, world/ula_yard.gd)._", "",
              "| Hour | Shöl | Chapter 05 | Hejie | Chapter 05 | Samkha | Chapter 05 |", "|---|---|---|---|---|---|---|"] + ["| %02d:%02d | %d | %d | %d | %d | %d | %d |" % (int(h), int(h % 1 * 60), n, w, nh, wh, ns, ws) for h, n, w, nh, wh, ns, ws in out_by]
    lines += ["", "Anchors: " + ", ".join(sorted(k for k in anchors if not k.startswith("H-"))) + "; %d house doors, %d of them the walkers' homes." % (n_doors, len(homes)), ""]
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w").write("\n".join(lines))
    draw(ground, town_m, XYZ, anchors, routes, walkers, homes)


def draw(ground, town_m, XYZ, anchors, routes, walkers, homes):
    """A map of the graph for checking it by eye: the walkable ground (the town's lighter), the walkers' routes each in
    its colour, the anchors named, into tests/terrain/out/street_graph_map.png (north up, 3 px a metre)."""
    from PIL import Image, ImageDraw, ImageFont
    x0, y0, x1, y1 = GROUND_BOX
    k = 3
    W, H = int((x1 - x0) * k), int((y1 - y0) * k)
    base = np.full(ground.ok.shape + (3,), (70, 62, 58), dtype=np.uint8)
    base[ground.ok & ~town_m] = (150, 140, 120)
    base[ground.ok & town_m] = (215, 205, 180)
    img = Image.fromarray(base[::-1]).resize((W, H), Image.NEAREST)
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 14)
    to_px = lambda x, y: ((x - x0) * k, (y1 - y) * k)
    rng = random.Random(7)
    for wk in walkers:
        col = tuple(rng.randint(30, 200) for _ in range(3))
        stops = [s_[0] for s_ in wk["day"]]
        for a, b in zip(stops, stops[1:]):
            r = routes.get("%s>%s" % (a, b))
            if not r:
                continue
            pts = [to_px(r["p"][3 * i], r["p"][3 * i + 1]) for i in range(len(r["p"]) // 3)]
            d.line(pts, fill=col, width=2)
    for name in ("mani_loop", "wheel"):
        r = routes.get(name)
        if r:
            d.line([to_px(r["p"][3 * i], r["p"][3 * i + 1]) for i in range(len(r["p"]) // 3)], fill=(200, 30, 30), width=2)
    for name, a in anchors.items():
        x, y = XYZ[a][:2]
        px, py = to_px(x, y)
        home = name in homes
        d.ellipse((px - 4, py - 4, px + 4, py + 4), fill=(20, 90, 200) if home else ((180, 30, 30) if not name.startswith("H-") else (120, 120, 120)))
        if not name.startswith("H-") or home:
            d.text((px + 6, py - 8), name, font=font, fill=(20, 20, 20))
    out = os.path.join(ROOT, "tests", "terrain", "out", "street_graph_map.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("graph: map -> %s" % os.path.relpath(out, ROOT))


if __name__ == "__main__":
    main()
