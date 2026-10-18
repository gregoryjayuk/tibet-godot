#!/usr/bin/env python3
"""The day's 300 (M2 sprint 10, step 2; plan chapter 05, 2.3-2.4): drawn at dawn from data/population.json with chapter
05's proportions for the core map at 11:00, the named cast always among them, and the roster kept for the whole day, so
a person can be followed from spring to roof to kora; those not drawn are indoors, at the hamlets or on the road, and
nobody is spawned out of nothing. Seeded by the date (the default day, Wednesday 28 October 1903: chapter 02's), so a
day replays.

The draw: first today's walkers (the street graph's: the named eight, the written days and those drawn before them) and
the forty-one named, then 2.3's archetypes to their counts, the Tibetan town and village's 192 by community as 2.1
gives them at 11:00 (Shöl 96, Tödé 28, Samkha 10, the hamlets the rest: in town on a market day), the monks from the
monastery's numbers by house, the Hejie people, the Hui, the caravan men and women, the nomads (a child among them),
the pilgrims and the beggars and performers from their parties. Each drawn person: who (the member's id, or a monk's
house and number), the household and house, the community, the archetype, the dress (the hamlets' people in their
best: chapter 05, 1), and where the day takes them: `shol` for Shöl's own and those who come into it today (the
hamlets to market, some of the caravans' men, the nomads, the pilgrims, the beggars, a third of the monks reading in
lay houses, some of Hejie and the camp), each with the place on the walkers' ground it comes from (`from`: its house's
door, or the way into town it uses); `hejie` for Hejie's own who keep to Hejie, from their doors (since step 3, the
walkers' ground over Hejie); `samkha` for Samkha's own who keep to Samkha, from their doors or the castle's steps (since
M2 sprint 11, step 5); `court` for those who bring the day's cases to the Pönpo's morning hearing (CASES); `away` for those who keep to their own district (Tödé, the monastery, the camp) until the walkers'
ground reaches them.
Run: tools/py tools/town/roster.py   Writes data/roster.json and docs/town/roster-report.md (tools/terrain/build.sh runs
it after the population, before the street graph).
"""
import collections
import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
POP = os.path.join(ROOT, "data", "population.json")
OUT = os.path.join(ROOT, "data", "roster.json")
REPORT = os.path.join(ROOT, "docs", "town", "roster-report.md")
DATE = "1903-10-28"  # the default day (chapter 02, the default day; chapter 05, 7.2)
SEED = int(DATE.replace("-", ""))
# chapter 05, 2.3: the 300 by archetype
QUOTA = {"TM": 52, "TW": 70, "TE": 18, "TB": 24, "TG": 20, "TT": 2, "NG": 6, "MK": 20, "MN": 5, "MP": 2, "NU": 2, "HM": 9,
         "HP": 7, "HW": 9, "HC": 15, "QS": 2, "HU": 2, "CV": 22, "NM": 3, "NW": 3, "PL": 3, "BP": 3}
TIBETAN = ("TM", "TW", "TE", "TB", "TG", "TT", "NG")
BY_COMMUNITY = {"shol": 96, "tode": 28, "samkha": 10, "hamlets": 58}  # 2.1's share of the 192 at 11:00
# who of those not of Shöl comes into it today (the rest keep to their own district)
INTO_SHOL = {"hamlets": 1.0, "tode": 0.15, "samkha": 0.1, "hejie": 0.2, "hui": 0.5, "transient": 0.8, "nuns": 0.5, "camp": 0.3,
             "pharkha": 0.5, "gonpa": 0.3}
# the named whose own scenes place them (world/samkha_people.gd: the toll steward at the south pavilion, the Pönpo in
# court and on his roof; world/pema_o_people.gd: the lama at first sun): not drawn as walkers too (M2 sprint 11, step 5:
# the Pönpo had walked Shöl as a generic figure while his court sat)
SCENES = {"sherab_steward", "ponpo_tsewang_namgyal", "lama_orgyen_dorje"}
# The Pönpo's morning hearing, 07:30-12:00 (chapter 05, NPC-03; chapter 04, 4.6): the day's cases, each its hearing's
# minutes and who brings it, by community; drawn from those who would have kept to their own district today (Tödé's,
# Pharkha's) or from Hejie's own (M2 sprint 11, step 5). Case 2 is the dispute over landing dues with Pharkha (the
# court's felts, two parties); a Tödé farmer's wife about a debt, a fine in tea bricks, a quarrel over water turns.
CASES = [(455.0, 500.0, ["tode:TW"]), (506.0, 586.0, ["pharkha", "hejie:HM"]), (592.0, 640.0, ["tode:TM"]), (647.0, 712.0, ["tode:TM"])]
# the way into Shöl by where they come from (tools/town/graph.py's anchors)
FROM = {"tode": "stair_top", "gonpa": "stair_top", "samkha": "yak_gate", "hejie": "west_way", "hui": "west_way", "camp": "west_way",
        "pharkha": "west_way", "nuns": "yak_gate", "caravan:CV-01": "west_way", "caravan:CV-02": "yak_gate", "guests:SHL-04": "dechen",
        "guests:SHL-05": "tsongra", "guests:SHL-06": "tsongra", "guests:SHL-07": "tsongra", "pilgrims:SHL-07": "tsongra",
        "wanderers:SHL-37": "west_edge", "community:SHL-11": "pema_o"}


def main():
    rnd = random.Random(SEED)
    pop = json.load(open(POP, encoding="utf-8"))
    hh = {r["id"]: r for r in pop["households"]}
    drawn = collections.OrderedDict()  # who -> entry

    def entry(r, m, why):
        return {"who": m["id"], "household": r["id"], "house": r["house"], "community": r["community"], "role": m["role"], "sex": m["sex"],
                "age": m["age"], "why": why, **({"named": m["named"]} if "named" in m else {}), **({"walker": m["walker"]} if "walker" in m else {})}

    # today's walkers and the forty-one named
    for r in pop["households"]:
        for m in r["members"]:
            if "walker" in m or "named" in m:
                drawn[m["id"]] = entry(r, m, "walker" if "walker" in m else "named")
    for m in pop["monastery"]["named"]:
        who = "%s:%s" % (m["house"], m["key"])
        drawn[who] = {"who": who, "household": "gonpa:%s" % m["house"], "house": m["house"], "community": "gonpa", "role": m["role"], "sex": "m",
                      "age": m.get("age", 30), "why": "walker" if m.get("walker") else "named", ("walker" if m.get("walker") else "named"): m["key"]}
    have = collections.Counter(e["role"] for e in drawn.values())
    have_c = collections.Counter((e["community"], e["role"]) for e in drawn.values() if e["role"] in TIBETAN)

    def eligible(pred):
        out = []
        for r in pop["households"]:
            if r["away"]:
                continue
            for m in r["members"]:
                if m["id"] not in drawn and not m.get("away") and pred(r, m):
                    out.append((r, m))
        return out

    def take(cands, n, why):
        rnd.shuffle(cands)
        for r, m in cands[:max(0, n)]:
            drawn[m["id"]] = entry(r, m, why)
        return min(len(cands), max(0, n))

    short = {}
    # the Tibetan 192: each archetype split over the communities as 2.1's shares, less those already drawn there
    for a in TIBETAN:
        if a == "NG":  # the ngakpa quarter's own
            got = take(eligible(lambda r, m: m["role"] == "NG"), QUOTA[a] - have[a], "drawn")
            if got < QUOTA[a] - have[a]:
                short[a] = QUOTA[a] - have[a] - got
            continue
        total = QUOTA[a]
        shares = {c: total * n / 192.0 for c, n in BY_COMMUNITY.items()}
        alloc = {c: int(v) for c, v in shares.items()}
        for c in sorted(shares, key=lambda c: -(shares[c] - alloc[c]))[:total - sum(alloc.values())]:
            alloc[c] += 1
        for c, n in alloc.items():
            got = take(eligible(lambda r, m, c=c, a=a: r["community"] == c and m["role"] == a), n - have_c[(c, a)], "drawn")
            if got < n - have_c[(c, a)]:
                short["%s %s" % (a, c)] = n - have_c[(c, a)] - got
    # the monks: the monastery's numbers by house (its people are M3's: a drawn monk is its house and a number)
    for a in ("MK", "MN"):
        need = QUOTA[a] - have[a]
        houses = [(g, v) for g, v in pop["monastery"]["houses"].items() if v["role"] == a]
        weights = [v["monks"] for g, v in houses]
        for k in range(max(0, need)):
            g, v = rnd.choices(houses, weights)[0]
            who = "%s.m%d" % (g, k + 1)
            drawn[who] = {"who": who, "household": "gonpa:%s" % g, "house": g, "community": "gonpa", "role": a, "sex": "m",
                          "age": rnd.randint(8, 14) if a == "MN" else rnd.randint(15, 75), "why": "drawn"}
    # the rest from their communities and parties
    for a, pred in (("MP", lambda r, m: m["role"] == "MP"), ("NU", lambda r, m: m["role"] == "NU"),
                    ("HM", lambda r, m: m["role"] == "HM" and r["community"] == "hejie"), ("HP", lambda r, m: m["role"] == "HP" and r["community"] == "hejie"),
                    ("HW", lambda r, m: m["role"] == "HW" and r["community"] == "hejie"), ("HC", lambda r, m: m["role"] == "HC" and r["community"] == "hejie"),
                    ("QS", lambda r, m: m["role"] == "QS"), ("HU", lambda r, m: m["role"] == "HU"), ("NM", lambda r, m: m["role"] == "NM"),
                    ("NW", lambda r, m: m["role"] == "NW"), ("PL", lambda r, m: m["role"] == "PL"), ("BP", lambda r, m: m["role"] == "BP")):
        got = take(eligible(pred), QUOTA[a] - have[a], "drawn")
        if got < QUOTA[a] - have[a]:
            short[a] = QUOTA[a] - have[a] - got
    # the caravans' 22: 18 men, 4 women
    cv_m = sum(1 for e in drawn.values() if e["role"] == "CV" and e["sex"] == "m")
    cv_f = sum(1 for e in drawn.values() if e["role"] == "CV" and e["sex"] == "f")
    take(eligible(lambda r, m: m["role"] == "CV" and m["sex"] == "m"), 18 - cv_m, "drawn")
    take(eligible(lambda r, m: m["role"] == "CV" and m["sex"] == "f"), 4 - cv_f, "drawn")
    # a nomad child (drawn as TB)
    take(eligible(lambda r, m: r["kind"] == "nomads" and m["age"] < 15), 1, "drawn")
    # where the day takes each: Shöl's own and those who come into it, from their door or their way in
    for e in drawn.values():
        c = e["community"]
        hid = e["household"]
        if c == "shol" and hid.startswith("household:") and e["house"].startswith("H-SHL-"):
            e["day"], e["from"] = "shol", e["house"]
        elif c in ("hejie", "hui") and hid.startswith("household:"):  # Hejie's own from their doors: into Shöl today, or about
            e["day"], e["from"] = ("shol" if rnd.random() < INTO_SHOL[c] else "hejie"), e["house"]  # Hejie (step 3)
        elif c == "samkha" and hid.startswith("household:"):  # Samkha's own from their doors (the castle's household from its
            # ward): into Shöl today, or about Samkha (M2 sprint 11, step 5: the walkers' ground over the ward, the ramp, Castle Lane)
            src = "castle_door" if e["house"] == "SAM-01" else e["house"]  # (the castle's: in by the steps from its ward)
            e["day"], e["from"] = ("shol" if rnd.random() < INTO_SHOL[c] else "samkha"), src
        elif hid.startswith("nomads:"):  # down from their tents on Tathang by the stair's top (Tsomo's way: chapter 05, 7.2)
            e["day"], e["from"] = ("shol", "stair_top") if rnd.random() < INTO_SHOL["transient"] else ("away", None)
        elif hid in FROM:
            e["day"], e["from"] = ("shol", FROM[hid]) if (hid.startswith("guests:SHL-04") or hid == "community:SHL-11" or rnd.random() < INTO_SHOL.get(c, 0.8)) else ("away", None)
        elif c == "shol":  # Shöl's named houses: their own place on the walkers' ground where it has one
            place = {"SHL-04": "dechen", "SHL-19": "headman", "SHL-24": "chang"}.get(e["house"])
            e["day"], e["from"] = ("shol", place) if place else ("shol", "tsongra")
        else:
            into = rnd.random() < INTO_SHOL.get(c, 0.0)
            road = hh[hid].get("enters_by") if hid in hh else None
            e["day"], e["from"] = ("shol", road or FROM.get(c)) if into else ("away", None)
        if "walker" in e:  # today's walkers keep the street graph's own days
            e["day"] = "walker"
        elif e.get("named") in SCENES:  # placed by their scenes all day, never walking as anyone else
            e["day"], e["from"] = "scene", None
        e["dress"] = "best" if c == "hamlets" else "everyday"
    # the hearing's parties (CASES): day `court`, from their way in or their door, their case and their felt (1 or 2)
    rc = random.Random(SEED + 5)  # their own stream: the rest of the day's drawn as before
    for k, (h0, h1, parties) in enumerate(CASES):
        for felt, want in enumerate(parties, 1):
            c, _, role = want.partition(":")
            pool = [e for e in drawn.values() if e["community"] == c and (not role or e["role"] == role) and "walker" not in e
                    and e["day"] == ("hejie" if c == "hejie" else "away") and e["household"].startswith("household:") and e["age"] >= 18]
            if not pool:
                print("roster: WARNING: no one of %s to bring case %d" % (want, k + 1))
                continue
            e = rc.choice(sorted(pool, key=lambda e: e["who"]))
            e["day"], e["case"], e["felt"] = "court", [h0, h1], felt
            e["from"] = e["house"] if c == "hejie" else FROM.get(c)
    out = {"about": "The day's 300 (M2 sprint 10, step 2; plan chapter 05, 2.3-2.4), written by tools/town/roster.py from data/population.json, seeded by the date: each drawn person's who (the member's id), household, house, community, archetype (role), sex, age, why (walker, named, drawn), dress, and day: walker (today's walkers, their days the street graph's own), shol (Shöl's own and those who come into it today, from their door or their way in: from), away (in their own district until the walkers' ground reaches it). Read by tools/town/graph.py for the walkers. Regenerated with the town.",
           "date": DATE, "seed": SEED, "people": list(drawn.values())}
    out["about"] = out["about"].replace("away (in their own district", "hejie (Hejie's own about Hejie, from their doors), samkha (Samkha's own about Samkha), court (the parties to the Pönpo's morning hearing: case, its minutes; felt, 1 or 2), scene (placed by their own scenes), away (in their own district")
    json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=0, separators=(",", ":"))
    roles = collections.Counter(e["role"] for e in drawn.values())
    days = collections.Counter(e["day"] for e in drawn.values())
    comm = collections.Counter(e["community"] for e in drawn.values())
    rep = ["# The day's 300", "", "_Written by `tools/town/roster.py` (M2 sprint 10, step 2; plan chapter 05, 2.3-2.4) for %s, seeded by the date. Regenerated with the town._" % DATE, "",
           "%d drawn: %d of today's walkers, %d more of the forty-one named, %d drawn to chapter 05's counts. %d walk in Shöl today (its own and those who come in), %d about Hejie, %d keep to their own district." % (
               len(drawn), sum(1 for e in drawn.values() if e["why"] == "walker"), sum(1 for e in drawn.values() if e["why"] == "named"), sum(1 for e in drawn.values() if e["why"] == "drawn"),
               days["shol"] + days["walker"], days["hejie"], days["away"]), "",
           "| Archetype | Drawn | Chapter 05 |", "|---|---|---|"] + ["| %s | %d | %d |" % (a, roles[a], QUOTA[a]) for a in QUOTA] + [
           "", "By community: " + ", ".join("%s %d" % (c, n) for c, n in comm.most_common()) + ".",
           "", "Short of chapter 05's count (none left at home to draw): " + (", ".join("%s %d" % kv for kv in short.items()) or "none") + "."]
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("roster: %d drawn for %s, %d in Shöl today (%d of them today's walkers), %d away in their districts -> %s" % (
        len(drawn), DATE, days["shol"] + days["walker"], days["walker"], days["away"], os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
