#!/usr/bin/env python3
"""The population as data (M2 sprint 10, step 1; plan chapter 05, 2.1-2.4; chapter 02, 12): one record per household,
`household:<house ID>`, for everyone the valley holds on the default day of October 1903, from which TownSim draws the
day's 300 at dawn (step 2).

The settled households come from the gazetteer's house groups (chapter 02: Shöl's town houses SHL-34 with their 70
households in 55 houses, the log-storey houses SHL-35, the ngakpa quarter SHL-36, the west edge SHL-37; Tödé's TOD-16 to
19 and its Bön houses TOD-03; Samkha's castle, its retainers' houses SAM-14 and poor houses SAM-15; Pharkha's PHK-05
and 06), its named houses (the four trading houses, the headman's, the physician's, the chang house, the painter's),
the camp's butcher and smith, the Gyalrong masons, Hejie (its shop-houses and courtyard houses, tools/town/hejie.py, and
its named shops, inns and the post), the Hui, the nunnery and Pema Ö's monks, and the nine valley hamlets (chapter 01,
8.1: about 900, off the core map, in town on market days; their households without houses, each hamlet's way into town
in `enters_by`); the monastery's 280 as numbers by house (its people are M3's). Chapter 05, 2.1 gives each community's households and people, 2.2 their ages: a household's
size is drawn about its group's mean and the community brought to chapter 05's total; its members' ages and sexes are
drawn from 2.2's shares, a head first. The transients of the season (2.1) are parties: the two caravans' crews, the
trading houses' guests, the nomads' tents, pilgrims, beggars and performers.
Each member: an id, age, sex, role (2.3's archetype: TM, TW, TE, TB, TG, TT, NG, HM, HP, HW, HC, QS, HU, CV, NM, NW, PL,
BP, MK, MN, MP, NU), work, dress ("everyday": the day's best is the draw's), and the forty-one named (chapter 05, 4.1)
by their key in their homes; today's walkers (tools/town/graph.py's street graph: the named eight, the written days of
data/generic_days.json and the twenty) each a member of the household at its home, by its key (`walker`).
Away: a house the town draws shut (world/households.gd's `decide`, written by tools/town/households_dump.gd) has every
household in it away, with a caravan, on pilgrimage or with the herds, or gone for good where it is left; and of the
households at home a third of the Tibetan men of 15 to 49 are away with caravans (chapter 05, 2.2: "adult women
outnumber adult men in the lanes about 6 to 4"), never a named one or a walker.
Run: tools/py tools/town/population.py   Writes data/population.json and docs/town/population-report.md
(tools/terrain/build.sh runs it last, after tools/town/households_dump.gd).
"""
import collections
import json
import os
import random
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, "data")
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
OUT = os.path.join(DATA, "population.json")
REPORT = os.path.join(ROOT, "docs", "town", "population-report.md")
CHAPTER = os.path.join(ROOT, "docs", "plan", "05-people.md")
SEED = 1903

# chapter 02's house groups: (group, house prefix, first, last, households, kind, community)
GROUPS = [("SHL-34", "H-SHL", 1, 55, 70, "town", "shol"), ("SHL-35", "H-SHL", 56, 110, 60, "log", "shol"),
          ("SHL-36", "H-SHL", 111, 135, 25, "ngakpa", "shol"), ("SHL-37", "H-SHL", 136, 150, 15, "poor", "shol"),
          ("TOD-16", "H-TOD", 1, 14, 13, "tower", "tode"), ("TOD-17", "H-TOD", 15, 44, 33, "log", "tode"),
          ("TOD-03", "H-TOD", 45, 48, 4, "bon", "tode"), ("TOD-18", "H-TOD", 49, 64, 18, "pise", "tode"),
          ("TOD-19", "H-TOD", 65, 68, 4, "poor", "tode"), ("SAM-14", "H-SAM", 1, 8, 11, "retainers", "samkha"),
          ("SAM-15", "H-SAM", 9, 12, 4, "servants", "samkha"), ("PHK-05", "H-PHK", 1, 16, 16, "farm", "pharkha"),
          ("PHK-06", "H-PHK", 17, 22, 6, "poor", "pharkha")]
HAMLETS = ["yak_gate", "yak_gate", "yak_gate", "west_way", "west_way", "west_way", "stair_top", "stair_top", "stair_top"]  # each
# hamlet's way into Shöl (tools/town/graph.py's anchors): up the Serchu road through Samkha and the Yak Gate, along the
# Yalong's bank by the Landing, down from Tathang and the upper valley by the monastery stair
SKIP = {"H-TOD-002"}  # the Gyalrong masons' house (TOD-15), its two families their own
# a group's households' mean size; each community is then brought to chapter 05, 2.1's people
MEAN = {"town": 6.8, "log": 7.2, "ngakpa": 6.8, "poor": 4.6, "tower": 7.6, "bon": 6.8, "pise": 6.6, "retainers": 6.2,
        "servants": 4.4, "farm": 6.8}
TOTAL = {"shol": 1140, "tode": 490, "samkha": 72, "pharkha": 136}  # (Samkha's 107 with its castle's 35, Pharkha's 140 with the
# dues house's four; Shöl's named houses besides its 170)
# chapter 05, 2.2: children under 15, adults 15-49, elders 50+ (half of the elders over 60)
AGES = {"tibetan": (0.25, 0.55, 0.20), "hejie": (0.37, 0.50, 0.13), "transient": (0.03, 0.90, 0.07), "monks": (0.21, 0.60, 0.19)}
WORK = {"town": (["shopkeeper", "trader", "tailor", "saddler", "turner", "smith", "carpenter", "porter", "butter seller"],
                 ["trader", "weaver", "spinner", "brewer", "water carrier", "shopkeeper"]),
        "log": (["farmer", "trader", "herder", "carpenter", "porter"], ["farmer", "weaver", "spinner", "water carrier"]),
        "ngakpa": (["ngakpa"], ["farmer", "weaver", "spinner"]),
        "poor": (["porter", "coracle man", "labourer", "beggar"], ["spinner", "porter", "labourer", "beggar"]),
        "tower": (["farmer", "herder"], ["farmer", "weaver"]), "bon": (["farmer"], ["farmer", "weaver"]),
        "pise": (["farmer", "herder"], ["farmer", "spinner"]), "farm": (["farmer", "coracle man"], ["farmer"]),
        "retainers": (["retainer", "groom", "guard", "scribe"], ["servant", "weaver"]),
        "servants": (["servant", "mastiff-keeper"], ["servant"])}
# today's walkers' homes that are places, not houses (tools/town/graph.py's anchors)
PLACES = {"dechen": "SHL-04", "headman": "SHL-19", "chang": "SHL-24"}
# the walkers by the Yak Gate and the stair's top: their households outside Shöl (by the walker's key)
OUTSIDE = {"drover": "caravan:CV-02", "drover_b": "caravan:CV-02", "muleteer": "caravan:CV-02", "muleteer_b": "caravan:CV-02",
           "ngodrup_dedpon": "caravan:CV-02", "jiang_deshun": "HEJ-30", "post_soldier": "HEJ-05", "post_soldier_b": "HEJ-05",
           "han_man": "HEJ-24", "hejie_trader": "HEJ-09", "pieman": "HEJ-13", "tsomo_nomad": "nomads:THG-02.1",
           "nomad_woman": "nomads:THG-02.2", "novice": "gonpa:MON-30", "novice_b": "gonpa:MON-30", "tashi_phuntsok": "H-TOD-007",
           "monk": "gonpa:MON-28"}  # (a house's id, resolved as any home, or a party's or the monastery's)
# a walker's body to its archetype (chapter 05, 2.3) and sex
BODY = {"townsman": ("TM", "m"), "townsman_b": ("TM", "m"), "townswoman": ("TW", "f"), "townswoman_b": ("TW", "f"),
        "monk": ("MK", "m"), "novice": ("MN", "m"), "novice_b": ("MN", "m"), "boy": ("TB", "m"), "girl": ("TG", "f"),
        "elder_man": ("TE", "m"), "elder_woman": ("TE", "f"), "drover": ("CV", "m"), "drover_b": ("CV", "m"),
        "muleteer": ("CV", "m"), "muleteer_b": ("CV", "m"), "han_man": ("HM", "m"), "hejie_trader": ("HM", "m"),
        "pieman": ("HP", "m"), "post_soldier": ("QS", "m"), "post_soldier_b": ("QS", "m"), "jiang_deshun": ("HM", "m"),
        "nomad_woman": ("NW", "f"), "tsomo_nomad": ("NW", "f"), "ngakpa_man": ("NG", "m"), "ngakpa_man_b": ("NG", "m"),
        "ngakpa_woman": ("TW", "f"), "ngakpa_woman_b": ("TW", "f"), "water_girl": ("TG", "f"), "water_girl_b": ("TG", "f"),
        "younger_son": ("TM", "m"), "headman_grandchild": ("TB", "m"), "headman_grandmother": ("TE", "f"),
        "house_grandmother": ("TE", "f"), "poor_grandmother": ("TE", "f"), "dechen_lama": ("MK", "m"),
        "lookout_woman": ("TE", "f"), "nyima_boy": ("TB", "m"), "norbu_girl": ("TG", "f"), "norbu_boy": ("TB", "m"),
        "yudron_daughter": ("TW", "f"), "kalsang_drolma": ("TW", "f"), "drakpa_bard": ("BP", "m"), "porter": ("TM", "m"),
        "porter_woman": ("TW", "f"), "stall_man": ("TM", "m"), "stall_woman": ("TW", "f"), "cook": ("TM", "m"),
        "tashi_phuntsok": ("TM", "m"), "pieman": ("HP", "m"), "dechen_child": ("TG", "f")}
FEMALE_KEY = re.compile(r"woman|girl|grandmother|wife|daughter|mother|sewer|dawa|yudron|drolma|tsomo|nun")  # a figure's sex by its
# name where BODY does not give it


def _age(rnd, shares, lo=0):
    c, a, e = shares
    while True:
        x = rnd.random()
        age = rnd.randint(0, 14) if x < c else (rnd.randint(15, 49) if x < c + a else (rnd.randint(50, 60) if rnd.random() < 0.5 else rnd.randint(61, 78)))
        if age >= lo:
            return age


def _role(age, sex, kind):
    if age < 5:
        return "TT"
    if age < 15:
        return "TB" if sex == "m" else "TG"
    if age >= 50:
        return "TE"
    if kind == "ngakpa" and sex == "m":
        return "NG"
    return "TM" if sex == "m" else "TW"


def _work(rnd, age, sex, kind):
    if age < 5:
        return "toddler"
    if age < 15:
        return "child"
    if age >= 61:
        return "elder"
    men, women = WORK.get(kind, (["farmer"], ["farmer"]))
    return rnd.choice(men if sex == "m" else women)


def cast():
    """Chapter 05, 4.1's forty-one: [key, name, age, group, home] from its table."""
    out = []
    for line in open(CHAPTER, encoding="utf-8"):
        m = re.match(r"\| NPC-\d+ \| `([a-z_]+)` \| ([^|]+) \| (\d+) \| ([^|]+) \| ([^|]+) \|", line)
        if m:
            out.append([m.group(1), m.group(2).strip(), int(m.group(3)), m.group(4).strip(), m.group(5).strip()])
    return out


def main():
    rnd = random.Random(SEED)
    town = json.load(open(os.path.join(DATA, "town.json"), encoding="utf-8"))
    built = {h["id"]: h for h in json.load(open(os.path.join(DATA, "town_generic.json"), encoding="utf-8"))["houses"]}
    hejie = json.load(open(os.path.join(DATA, "hejie.json"), encoding="utf-8"))["houses"] if os.path.exists(os.path.join(DATA, "hejie.json")) else []
    dump = os.path.join(GEN, "households.json")
    state = json.load(open(dump, encoding="utf-8"))["houses"] if os.path.exists(dump) else {}
    names = {b["id"]: b.get("name_en", "") for b in town["buildings"]}
    hh = collections.OrderedDict()  # household id -> record

    def add(hid, house, community, kind, members=None, **extra):
        rec = {"id": hid, "house": house, "community": community, "kind": kind, "away": None, "members": members or []}
        rec.update(extra)
        hh[hid] = rec
        return rec

    def member(rec, age, sex, role, work, **extra):
        m = {"id": "%s.%d" % (rec["id"][len("household:"):] if rec["id"].startswith("household:") else rec["id"], len(rec["members"]) + 1), "age": age, "sex": sex, "role": role,
             "work": work, "dress": "everyday"}
        m.update(extra)
        rec["members"].append(m)
        return m

    def fill(rec, n, shares, kind, role_of=_role):  # a household of n: a head of 15-59 first, then 2.2's shares
        sex = "m" if rnd.random() < 0.82 else "f"  # (a widow heads about one in six)
        age = rnd.randint(24, 59)
        member(rec, age, sex, role_of(age, sex, kind), _work(rnd, age, sex, kind), head=True)
        if n > 1 and sex == "m":  # his wife
            age2 = max(16, min(70, age - rnd.randint(0, 8)))
            member(rec, age2, "f", role_of(age2, "f", kind), _work(rnd, age2, "f", kind))
        c, _a, e = shares  # the rest drawn so the household as a whole keeps 2.2's shares (its head and wife are adults)
        k = max(1.0, n - len(rec["members"]))
        c2, e2 = min(0.7, c * n / k), min(0.45, e * n / k)
        rest = (c2, max(0.05, 1.0 - c2 - e2), e2)
        while len(rec["members"]) < n:
            a = _age(rnd, rest)
            s = "m" if rnd.random() < 0.5 else "f"
            member(rec, a, s, role_of(a, s, kind), _work(rnd, a, s, kind))

    # the settled groups: their houses (the built ones where the town has them), each household a size about its mean
    for gid, prefix, first, last, n_hh, kind, community in GROUPS:
        houses = ["%s-%03d" % (prefix, k) if prefix != "H-SAM" and prefix != "H-PHK" else "%s-%02d" % (prefix, k) for k in range(first, last + 1)]
        houses = [h for h in houses if h not in SKIP and (prefix != "H-SHL" or h in built)]
        # the bigger houses hold the second households (chapter 02: "three houses hold two")
        order = sorted(houses, key=lambda h: -(built[h]["footprint"][0] * built[h]["footprint"][1] * built[h].get("storeys", 2)) if h in built else rnd.random())
        count = collections.Counter(houses)
        for h in order[:max(0, n_hh - len(houses))]:
            count[h] += 1
        for h in houses:
            for k in range(count[h]):
                hid = "household:%s" % h if count[h] == 1 else "household:%s.%d" % (h, k + 1)
                rec = add(hid, h, community, kind, group=gid)
                rec["size"] = max(2, min(13, int(round(rnd.gauss(MEAN[kind], 1.9)))))
    # each community to chapter 05's people
    for community, total in TOTAL.items():
        recs = [r for r in hh.values() if r["community"] == community]
        while sum(r["size"] for r in recs) != total:
            r = rnd.choice(recs)
            if sum(q["size"] for q in recs) < total and r["size"] < 13:
                r["size"] += 1
            elif sum(q["size"] for q in recs) > total and r["size"] > 2:
                r["size"] -= 1
        for r in recs:
            fill(r, r.pop("size"), AGES["tibetan"], r["kind"])
    # Tödé's Gyalrong masons (TOD-15, H-TOD-002: two families, about 12)
    for k, n in ((1, 7), (2, 5)):
        fill(add("household:H-TOD-002.%d" % k, "H-TOD-002", "tode", "masons", group="TOD-15"), n, AGES["tibetan"], "town")
    # Shöl's named houses: the trading houses' families, the headman's, the physician's, the chang house, the painter's
    for bid, kind, n in (("SHL-04", "trading", 5), ("SHL-05", "trading", 9), ("SHL-06", "trading", 8), ("SHL-07", "trading", 6),
                         ("SHL-19", "headman", 4), ("SHL-20", "physician", 6), ("SHL-24", "chang", 1), ("SHL-28", "painter", 5)):
        # (Dechen-tsang's and the headman's households are mostly their named and their walkers, the servants among them)
        rec = add("household:%s" % bid, bid, "shol", kind, name=names.get(bid, ""))
        rec["size"] = n
    # the camp's butcher and smith (GAR-05, 06)
    for bid, n, w in (("GAR-05", 6, "butcher"), ("GAR-06", 7, "smith")):
        rec = add("household:%s" % bid, bid, "camp", "camp", name=names.get(bid, ""))
        fill(rec, n, AGES["tibetan"], "town")
        rec["members"][0]["work"] = w
    # Samkha's castle: the Pönpo's household, retainers and servants, about 35
    rec = add("household:SAM-01", "SAM-01", "samkha", "castle", name=names.get("SAM-01", ""))
    rec["size"] = 35
    # the nine valley hamlets within two hours (chapter 01, 8.1: about 900 people, in town on market days; chapter 05, 2.1:
    # "inside the 192"), off the core map: their households without houses here, each hamlet's road into town
    for k in range(1, len(HAMLETS) + 1):
        road = HAMLETS[k - 1]
        for j in range(1, 15):
            rec = add("household:hamlet-%d.%d" % (k, j), "hamlet-%d" % k, "hamlets", "farm", enters_by=road)
            rec["size"] = max(3, min(11, int(round(rnd.gauss(6.6, 1.8)))))
    recs = [r for r in hh.values() if r["community"] == "hamlets"]
    while sum(r["size"] for r in recs) != 900:
        r = rnd.choice(recs)
        r["size"] += 1 if sum(q["size"] for q in recs) < 900 and r["size"] < 11 else (-1 if r["size"] > 3 else 0)
    for r in recs:
        fill(r, r.pop("size"), AGES["tibetan"], "farm")
    # Pharkha's dues house (Nyarong's: the agent and three guards)
    rec = add("household:PHK-02", "PHK-02", "pharkha", "nyarong", name=names.get("PHK-02", ""))
    rec["size"] = 4
    # Hejie: 160 Han men, 95 wives (Tibetan or mixed), 150 children; its houses and named buildings, the post, the Hui
    hj_homes = [(h["id"], 3 if h["type"] == "G" else 2) for h in hejie]  # a shop's family and its upper floor's; a courtyard house's three
    for bid in ("HEJ-09", "HEJ-14", "HEJ-15", "HEJ-16", "HEJ-17", "HEJ-22", "HEJ-23", "HEJ-24", "HEJ-25", "HEJ-26", "HEJ-27",
                "HEJ-29", "HEJ-30", "HEJ-11", "HEJ-12", "HEJ-39", "HEJ-08", "HEJ-10", "HEJ-07"):
        hj_homes.append((bid, 1))
    slots = [h for h, k in hj_homes for _ in range(k)]
    married, wives, kids = 0, 0, 0
    homes_hh = collections.Counter()
    for h in slots:
        homes_hh[h] += 1
    hj_recs = []
    for h, k in homes_hh.items():
        for j in range(k):
            hid = "household:%s" % h if k == 1 else "household:%s.%d" % (h, j + 1)
            hj_recs.append(add(hid, h, "hejie", "han", name=names.get(h, "")))
    rnd.shuffle(hj_recs)
    # 95 married households, the rest single men's (shopmen, clerks); children 150 among the married
    kid_left = 150
    for i, rec in enumerate(hj_recs):
        man_age = _age(rnd, (0.0, 0.8, 0.2), lo=20)
        member(rec, man_age, "m", "HM", rnd.choice(["shopkeeper", "craftsman", "clerk", "innkeeper", "tea merchant"]), head=True)
        if i < 95:
            member(rec, max(17, min(55, man_age - rnd.randint(2, 15))), "f", "HW", "wife")
            n_k = min(kid_left, max(0, int(round(rnd.gauss(1.6, 1.1)))))
            for _ in range(n_k):
                a = rnd.randint(0, 14)
                member(rec, a, "m" if rnd.random() < 0.5 else "f", "HC", "child" if a >= 5 else "toddler")
            kid_left -= n_k
        else:
            member(rec, rnd.randint(16, 40), "m", "HM", "shopman")
    while kid_left > 0:  # the rest of the 150
        rec = rnd.choice(hj_recs[:95])
        a = rnd.randint(0, 14)
        member(rec, a, "m" if rnd.random() < 0.5 else "f", "HC", "child" if a >= 5 else "toddler")
        kid_left -= 1
    men = sum(1 for r in hj_recs for m in r["members"] if m["sex"] == "m" and m["role"] in ("HM", "HP"))
    carriers = add("household:HEJ-13", "HEJ-13", "hejie", "carriers", name=names.get("HEJ-13", ""))  # the carriers' inn's lodgers
    boat = add("household:FER-03", "FER-03", "hejie", "boatmen", name=names.get("FER-03", ""))  # the government boat's crew
    while men < 160:
        if len(boat["members"]) < 6:
            member(boat, _age(rnd, (0.0, 0.85, 0.15), lo=18), "m", "HP", "boatman")
        else:
            member(carriers, _age(rnd, (0.0, 0.9, 0.1), lo=16), "m", "HP", rnd.choice(["carrier", "labourer"]))
        men += 1
    post = add("household:HEJ-05", "HEJ-05", "hejie", "post", name=names.get("HEJ-05", ""), absent=23)  # 17 of 40 present
    for _ in range(17):
        member(post, rnd.randint(19, 52), "m", "QS", "soldier")
    relay = add("household:HEJ-06", "HEJ-06", "hejie", "relay", name=names.get("HEJ-06", ""))
    for _ in range(6):
        member(relay, rnd.randint(18, 50), "m", "HP", "relay man")
    for bid, k, n in (("HEJ-18", 1, 6), ("HEJ-19", 1, 7), ("HEJ-19", 2, 3), ("HEJ-20", 1, 2), ("HEJ-21", 1, 6)):  # the Hui: 5, 24
        rec = add("household:%s" % bid if (bid, k) != ("HEJ-19", 2) and bid != "HEJ-19" else "household:%s.%d" % (bid, k), bid, "hui", "hui", name=names.get(bid, ""))
        age = rnd.randint(30, 55)
        member(rec, age, "m", "HU", {"HEJ-18": "noodle maker", "HEJ-19": "butcher", "HEJ-20": "brass trader", "HEJ-21": "mule-hirer"}[bid], head=True)
        if bid == "HEJ-20":
            member(rec, rnd.randint(16, 22), "m", "HU", "his nephew")
            continue
        member(rec, max(18, age - rnd.randint(2, 10)), "f", "HW", "wife")
        while len(rec["members"]) < n:
            a = _age(rnd, AGES["hejie"])
            s = "m" if rnd.random() < 0.5 else "f"
            member(rec, a, s, "HU" if s == "m" and a >= 15 else ("HC" if a < 15 else "HW"), "child" if a < 15 else "")
    # the nunnery (26 nuns) and Pema Ö (9 monks)
    nuns = add("community:SER-13", "SER-13", "nuns", "nunnery", name=names.get("SER-13", ""))
    for _ in range(26):
        member(nuns, _age(rnd, (0.12, 0.6, 0.28)), "f", "NU", "nun")
    pema = add("community:SHL-11", "SHL-11", "shol", "pema_o", name=names.get("SHL-11", ""))
    for _ in range(9):
        member(pema, _age(rnd, (0.1, 0.6, 0.3), lo=10), "m", "MP", "monk")
    # the transients of the season (chapter 05, 2.1): the caravans' crews, the trading houses' guests, the nomads' tents,
    # pilgrims, beggars and performers; and the monastery's walkers' places
    parties = [("caravan:CV-02", "GAR-03", "caravan", 18, "CV"), ("caravan:CV-01", "GAR-03", "caravan", 16, "CV"),
               ("guests:SHL-04", "SHL-04", "guests", 24, "CV"), ("guests:SHL-05", "SHL-05", "guests", 12, "CV"),
               ("guests:SHL-06", "SHL-06", "guests", 10, "CV"), ("guests:SHL-07", "SHL-07", "guests", 8, "NM"),
               ("nomads:THG-02.1", "THG-02", "nomads", 7, "N"), ("nomads:THG-02.2", "THG-02", "nomads", 8, "N"),
               ("nomads:THG-02.3", "THG-02", "nomads", 6, "N"), ("nomads:THG-02.4", "THG-02", "nomads", 7, "N"),
               ("nomads:THG-02.5", "THG-02", "nomads", 6, "N"), ("pilgrims:SHL-07", "SHL-07", "pilgrims", 22, "PL"),
               ("wanderers:SHL-37", "SHL-37", "beggars", 18, "BP")]  # (on the west edge, wherever they are let in)
    for pid, house, kind, n, role in parties:
        rec = add(pid, house, "transient", kind)
        for _ in range(n):
            a = _age(rnd, AGES["transient"]) if role != "N" else _age(rnd, AGES["tibetan"])
            s = "m" if rnd.random() < (0.82 if role in ("CV", "PL") else 0.5) else "f"
            r = ("NM" if s == "m" else "NW") if role in ("N", "NM") and a >= 15 else ("TB" if s == "m" else "TG") if a < 15 else role
            member(rec, a, s, r, {"CV": "drover", "NM": "nomad", "N": "nomad", "PL": "pilgrim", "BP": "beggar"}[role] if a >= 15 else "child")
    gonpa = {}
    for gid, n, role in (("MON-27", 52, "MK"), ("MON-28", 116, "MK"), ("MON-29", 43, "MK"), ("MON-30", 60, "MN"), ("MON-09", 6, "MK"), ("MON-10", 2, "MK"), ("MON-11", 1, "MK")):
        gonpa[gid] = {"house": gid, "name": names.get(gid, ""), "monks": n, "role": role}
    # the named sized houses, now their members (after the named and the walkers are known, to leave them room)
    for rec in hh.values():
        if "size" in rec:
            n = rec.pop("size")
            fill(rec, n, AGES["tibetan"], {"trading": "town", "headman": "town", "physician": "town", "chang": "town", "painter": "town", "castle": "retainers", "nyarong": "retainers"}[rec["kind"]])

    def home_of(home):  # a cast row's or a walker's home to its household id
        h = home.split(" (")[0].strip()
        h = PLACES.get(h, h)
        if h == "TOD-04":
            h = "H-TOD-001"
        if h == "TOD-15":
            h = "H-TOD-002"
        for cand in ("household:%s" % h, "household:%s.1" % h, "community:%s" % h):
            if cand in hh:
                return cand
        if h in ("THG-02",):
            return "nomads:THG-02.1"
        if h in ("GAR-03",):
            return "caravan:CV-02"
        return None

    def take(rid, key, age, sex, role, field, head=False, work=None):  # a named person or a walker into its household: its
        # head if it heads it, else the member nearest its age of its sex and role not yet anyone's, or a new one
        rec = hh[rid]
        free = [m for m in rec["members"] if "named" not in m and "walker" not in m and m["sex"] == sex
                and (m["role"] == role or abs(m["age"] - age) <= 12 or (head and m.get("head")))]  # (a named head takes the
        # drawn head's place whatever its age: Sherab, 46, had been added beside his house's head of 59)
        free.sort(key=lambda m: (not (head and m.get("head")), abs(m["age"] - age)))
        if free:
            m = free[0]
            m["age"] = age
        else:
            m = member(rec, age, sex, role, _work(rnd, age, sex, rec["kind"]))
        m["role"] = role
        if head and not m.get("head"):
            for o in rec["members"]:
                o.pop("head", None)
            m["head"] = True
        if work:
            m["work"] = work
        m[field] = key
        return m

    def walker_of(key, body):  # a walker's archetype, sex and age from the figure the game draws it with, its work from its key
        base = re.sub(r"_[bcd]$", "", key)
        fig = re.sub(r"_[bcd]$", "", body)
        role, sex = BODY.get(body, BODY.get(fig, (None, "f" if FEMALE_KEY.search(body) else "m")))
        if role is None:
            role = "TE" if re.search(r"grandmother|elder|old", body) else ("TG" if "girl" in body else ("TB" if re.search(r"boy|child|grandchild", body) else ("TM" if sex == "m" else "TW")))
        age = {"TE": rnd.randint(56, 76), "TB": rnd.randint(6, 14), "TG": rnd.randint(6, 14), "MN": rnd.randint(8, 14)}.get(role, rnd.randint(18, 48))
        work = {"water_woman": "water carrier", "water_girl": "water carrier", "stall_man": "stallholder", "stall_woman": "stallholder",
                "kitchen_woman": "kitchen woman", "tea_sewer": "tea-sewer", "dechen_servant": "servant", "dechen_steward": "steward",
                "headman_steward": "steward", "headman_groom": "groom", "headman_kitchen_girl": "kitchen girl", "dechen_lama": "household lama",
                "lookout_woman": "elder", "dice_player": "dice player", "pieman": "pieman", "porter_woman": "porter", "porter": "porter",
                "post_soldier": "soldier", "hejie_trader": "trader", "han_man": "shopman", "drover": "drover", "muleteer": "muleteer",
                "nomad_woman": "nomad", "ngakpa_man": "ngakpa", "cook": "cook", "house_man": "farmer", "house_mother": "farmer"}.get(base)
        # (a walker named for its relation or its name keeps the household's own work for it)
        return role, sex, age, work

    HEADS = {"achak_dolkar", "sonam_wangyal", "ama_yudron", "menpa_tsering_dondrup", "lhawang_painter", "ponpo_tsewang_namgyal", "liu_dechang",
             "han_desheng", "wang_er", "he_maoxiu", "ma_zhankui", "deng_laosan", "jiang_deshun", "norbu_dondrup", "yungdrung_gyaltsen",
             "rabten_mason", "zhang_changshun", "wang_gui", "sherab_steward"}  # the named who head their households (Sherab the
    # Pönpo's steward his, in H-SAM-01: M2 sprint 11, step 2)

    # the forty-one named (chapter 05, 4.1)
    named_where, unplaced = {}, []
    monks_named = []
    FEMALE = {"achak_dolkar", "chodron_tode", "dickyi", "liu_guiying", "yangchen_drolma", "ama_yudron", "kalsang_drolma", "tsomo_nomad", "ani_pema_chodron"}
    for key, name, age, group, home in cast():
        sex = "f" if key in FEMALE else "m"
        h = home.split(" (")[0].strip()
        if h.startswith("MON-") or h.startswith("H-MON-"):
            monks_named.append({"key": key, "name": name, "age": age, "house": h, "role": "MN" if age < 15 else "MK"})
            named_where[key] = "gonpa:%s" % h
            continue
        rid = home_of(home)
        if rid is None:
            unplaced.append(key)
            continue
        role = {"liu_dechang": "QS", "han_desheng": "HM", "jiang_deshun": "HM", "wang_gui": "QS", "deng_laosan": "HM", "wang_er": "HM",
                "he_maoxiu": "HM", "zhang_changshun": "HP", "ma_zhankui": "HU", "dickyi": "HW", "liu_guiying": "HC", "yang_shouren": "HM",
                "lama_orgyen_dorje": "MP", "ani_pema_chodron": "NU", "tsomo_nomad": "NW", "dorje_tsering_nomad": "NM",
                "ngodrup_dedpon": "CV", "drakpa_bard": "BP", "he_wanchun": "HM", "norbu_dondrup": "TM"}.get(key)
        if role is None:
            role = _role(age, sex, hh[rid]["kind"])
        m = take(rid, key, age, sex, role, "named", head=key in HEADS, work=group)
        m["name"] = name
        named_where[key] = rid
    # today's walkers (the street graph: the named eight and the written days by their keys, in its order; the twenty)
    graph = os.path.join(GEN, "street_graph.json")
    walkers_where, walkers_unplaced = {}, []
    if os.path.exists(graph):
        nd = json.load(open(os.path.join(DATA, "named_days.json"), encoding="utf-8"))["people"]
        gd = json.load(open(os.path.join(DATA, "generic_days.json"), encoding="utf-8"))["people"]
        keys = list(nd.keys()) + list(gd.keys())
        written = [w for w in json.load(open(graph, encoding="utf-8"))["walkers"] if w.get("named")]
        others = [w for w in json.load(open(graph, encoding="utf-8"))["walkers"] if not w.get("named")]
        for key, w in zip(keys, written):
            if key in named_where:  # one of the forty-one: already in its household
                rid = named_where[key]
                for m in hh.get(rid, {"members": []})["members"]:
                    if m.get("named") == key:
                        m["walker"] = key
                walkers_where[key] = rid
                continue
            home = str(w.get("home", ""))
            rid = OUTSIDE.get(key) if home in ("yak_gate", "stair_top") or key in OUTSIDE and not home.startswith("H-") else home_of(home)
            if rid is not None and ":" not in rid:
                rid = home_of(rid)
            if rid is None or (rid not in hh and not rid.startswith("gonpa:")):
                walkers_unplaced.append("%s (%s)" % (key, home))
                continue
            if rid.startswith("gonpa:"):
                monks_named.append({"key": key, "walker": True, "house": rid.split(":")[1], "role": BODY.get(key, ("MK", "m"))[0]})
                walkers_where[key] = rid
                continue
            role, sex, age, work = walker_of(key, str(w.get("kind", key)))
            take(rid, key, age, sex, role, "walker", work=work)
            walkers_where[key] = rid
        for i, w in enumerate(others):
            if w.get("roster"):  # the day's drawn (tools/town/roster.py): already the population's own people
                continue
            key = "%s#%d" % (w["kind"], i + 1)
            home = str(w.get("home", ""))
            if w["kind"] == "monk":
                monks_named.append({"key": key, "walker": True, "house": "MON-28", "role": "MK"})
                walkers_where[key] = "gonpa:MON-28"
                continue
            rid = home_of(home)
            if rid is None:
                walkers_unplaced.append("%s (%s)" % (key, home))
                continue
            role, sex, age, work = walker_of(w["kind"], w["kind"])
            take(rid, key, age, sex, role, "walker", work=None)
            walkers_where[key] = rid
    # away: the houses the town draws shut, every household in them; and a third of the Tibetan men of 15-49 at home
    walker_homes = set(r for r in walkers_where.values())
    for rec in hh.values():
        st = state.get(rec["house"])
        if st and st.get("shut") and rec["id"].startswith("household:") and rec["id"] not in walker_homes and not any("named" in m or "walker" in m for m in rec["members"]):
            rec["away"] = "left" if st.get("left") else rnd.choice(["caravan", "caravan", "pilgrimage", "herds"])
    for community in ("shol", "tode", "samkha"):
        home = [(r, m) for r in hh.values() if r["community"] == community and not r["away"] for m in r["members"] if 15 <= m["age"] <= 49]
        women = sum(1 for r, m in home if m["sex"] == "f")
        men = [m for r, m in home if m["sex"] == "m"]
        free = [m for r, m in home if m["sex"] == "m" and r["kind"] not in ("ngakpa", "pema_o") and "named" not in m and "walker" not in m and not m.get("head")]
        rnd.shuffle(free)
        n_home = len(men)
        while free and n_home > 0.667 * women:
            free.pop()["away"] = "caravan"
            n_home -= 1
    # the record
    houses = sorted(set(r["house"] for r in hh.values()))
    out = {"about": "The population as data (M2 sprint 10, step 1; plan chapter 05, 2.1-2.4), written by tools/town/population.py: `households`, one record a household (`household:<house ID>`, or a house's `.n` where it holds more than one; the nunnery's and Pema Ö's `community:`, the season's transients as `caravan:`, `guests:`, `nomads:`, `pilgrims:`, `wanderers:` parties at their lodging), each its house, community, kind, `away` (null, caravan, pilgrimage, herds, left: a house the town draws shut, world/households.gd) and members (id, age, sex, role: chapter 05, 2.3's archetype, work, dress, and `named`, the forty-one's key, `walker`, today's walker's key, `away` for a man with a caravan); `monastery`, the 280 resident monks by house as numbers and its named; read by TownSim for the day's 300 (step 2). Regenerated with the town.",
           "seed": SEED, "households": list(hh.values()), "monastery": {"houses": gonpa, "named": monks_named}}
    with open(OUT, "w", encoding="utf-8") as f:  # a household a line, so a change reads in a diff
        f.write('{"about": %s,\n "seed": %d,\n "households": [\n' % (json.dumps(out["about"], ensure_ascii=False), SEED))
        f.write(",\n".join("  " + json.dumps(r, ensure_ascii=False, separators=(",", ":")) for r in out["households"]))
        f.write('\n ],\n "monastery": %s\n}\n' % json.dumps(out["monastery"], ensure_ascii=False, separators=(",", ":")))
    # the report
    by = collections.OrderedDict()
    for rec in hh.values():
        c = rec["community"]
        b = by.setdefault(c, {"hh": 0, "people": 0, "away_hh": 0, "away": 0, "kids": 0, "adults": 0, "elders": 0, "m": 0, "f": 0, "m_home": 0, "f_home": 0})
        b["hh"] += 1
        b["away_hh"] += int(bool(rec["away"]))
        for m in rec["members"]:
            b["people"] += 1
            b["kids" if m["age"] < 15 else ("adults" if m["age"] < 50 else "elders")] += 1
            if rec["away"] or m.get("away"):
                b["away"] += 1
            elif 15 <= m["age"] < 50:
                b["m_home" if m["sex"] == "m" else "f_home"] += 1
    want = {"hamlets": ("9 hamlets", "about 900"), "shol": ("170 + the named houses", "1,140"), "tode": ("72 (and the masons' 2)", "490 (and 12)"), "samkha": ("16", "107"),
            "camp": ("2", "13"), "hejie": ("the shops, houses, post, relay", "405 and 17 soldiers, 6 relay men"), "hui": ("5", "24"),
            "pharkha": ("22 and the dues house", "140"), "nuns": ("1", "26"), "transient": ("parties", "250-450 a day in the season")}
    rep = ["# Population", "", "_Written by `tools/town/population.py` (M2 sprint 10, step 1; plan chapter 05, 2.1-2.4): every household the valley holds on the default day, from which TownSim draws the day's 300. Regenerated with the town._", "",
           "%d households and parties, %d people (the monastery's %d monks as numbers besides); %d houses." % (len(hh), sum(len(r["members"]) for r in hh.values()), sum(g["monks"] for g in gonpa.values()), len(houses)), "",
           "| Community | Households | People | Chapter 05 (households, people) | Children, adults, elders | Away (households, people) | At home, men to women 15-49 |", "|---|---|---|---|---|---|---|"]
    for c, b in by.items():
        n = max(1, b["people"])
        rep.append("| %s | %d | %d | %s | %.0f%%, %.0f%%, %.0f%% | %d, %d | %d : %d |" % (c, b["hh"], b["people"], ", ".join(want.get(c, ("", ""))), 100 * b["kids"] / n, 100 * b["adults"] / n, 100 * b["elders"] / n, b["away_hh"], b["away"], b["m_home"], b["f_home"]))
    rep += ["", "## The named", "", "%d of chapter 05's forty-one placed%s." % (len(named_where), (": not placed " + ", ".join(unplaced)) if unplaced else ""), ""]
    rep += ["- %s: %s" % (k, v) for k, v in named_where.items()]
    shut_named = sorted(set(r["house"] for r in hh.values() if state.get(r["house"], {}).get("shut") and any("named" in m or "walker" in m for m in r["members"])))
    rep += ["", "Named or walking in a house the town draws shut (world/households.gd `kept` should hold it): %s." % (", ".join(shut_named) or "none")]
    rep += ["", "## Today's walkers", "", "%d of the street graph's walkers in their households%s." % (len(walkers_where), (": not placed " + ", ".join(walkers_unplaced)) if walkers_unplaced else "")]
    roles = collections.Counter(m["role"] for r in hh.values() if not r["away"] for m in r["members"] if not m.get("away"))
    rep += ["", "## At home today, by archetype (chapter 05, 2.3)", "", ", ".join("%s %d" % (k, v) for k, v in sorted(roles.items()))]
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("population: %d households, %d people (%d at home), %d of the 41 named, %d walkers placed%s -> %s" % (
        len(hh), sum(len(r["members"]) for r in hh.values()), sum(roles.values()), len(named_where), len(walkers_where),
        (" (not placed: %s)" % ", ".join(unplaced + walkers_unplaced)) if unplaced or walkers_unplaced else "", os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
