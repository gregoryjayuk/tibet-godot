#!/usr/bin/env python3
"""The phrasebook and the slice's bark lines (plan chapter 07, 8.4-8.6; chapter 05, 9.6's greeting duty; M1 sprint 7,
step 8). Reads the plan's two phrasebook tables (PB-T01 to PB-T62, Tibetan; PB-C01 to PB-C31, Chinese) into
data/phrasebook.json, and writes the slice's lines, each put on its speakers and its moment, into data/barks.json for
world/barks.gd. A line whose script the plan marks "(script unverified)" is never shown in the game; it stays on Greg's
check sheet (tools/culture/bark_sheet.py) with its question.

A bark's `who` are roles (ROLES: the walkers' keys and kinds), `where` a place world/barks.gd knows, `hours` the
game's hours it can be said in, and `how`:
- greet: the speaker's duty (chapter 05, 9.6): to the player coming within 3.5 m, once a day each (hosts, stall-keepers);
- near: now and then to the player standing by;
- pass: to the player squeezing past on a stair;
- leave: as the player goes (from a room, from a stall);
- overheard: said to another (`with`: roles one of whom must stand by), heard by the player within 6 m;
- event: said in a scene of its own (the tea, the message, the roof's sang: world/tea.gd, message.gd, roof_sang.gd).
Run: python3 tools/culture/barks.py   Writes data/phrasebook.json and data/barks.json.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "docs", "plan", "07-culture.md")

ROLES = {
    "host": ["achak_dolkar", "kitchen_woman"],
    "household": ["house_grandmother", "house_mother", "house_man", "poor_grandmother"],  # whoever is home in the houses to enter (H-SHL-142's too)
    "cook": ["cook"],
    "host_zh": ["yang_shouren"],
    "clerk_zh": ["han_man"],
    "agent": ["ngodrup_dedpon"],
    "stall": ["stall_woman", "stall_man", "kalsang_drolma", "tsomo_nomad", "nomad_woman"],
    "nomad": ["tsomo_nomad", "nomad_woman"],
    "mother": ["stall_woman"],
    "buyer": ["townsman", "townswoman", "townsman_b", "townswoman_b", "porter", "porter_woman"],
    "elder": ["elder_man", "elder_woman", "sonam_wangyal", "pasang_carver"],
    "old_woman": ["elder_woman"],
    "child": ["nyima_boy", "boy", "girl"],
    "nyima": ["nyima_boy"],
    "young_man": ["drover", "drover_b", "porter", "townsman", "townsman_b"],
    "drover": ["drover", "drover_b"],
    "woman": ["townswoman", "townswoman_b", "stall_woman", "porter_woman"],
    "monk": ["monk"],
    "bard": ["drakpa_bard"],
    "chang_host": ["ama_yudron", "yudron_daughter"],  # the chang house's widow and her daughter (M2 sprint 2)
    "gatekeeper": ["castle_gatekeeper"],  # Samkha Khar's, in its gate passage (M2 sprint 4; world/samkha_people.gd)
    "gonkhang_keeper": ["gonkhang_keeper"],  # the Gönkhang's, at its curtain (M3 sprint 6; world/boots.gd)
    "lookout_woman": ["lookout_woman"],  # the old woman who burns juniper at the Gorge Rim Lookout at dusk (M2 sprint 6, step 4)
    "anyone": ["townsman", "townswoman", "townsman_b", "townswoman_b", "porter", "porter_woman", "drover", "drover_b",
               "elder_man", "elder_woman", "stall_woman", "stall_man", "kalsang_drolma", "sonam_wangyal"],
}

# [phrasebook id, who, where, hours (from, to), how, with (overheard: the listener's roles), weight, and where the plan's
#  line holds two or a usage note, or a scene says it its own way, the one said: {"script": ..., "english": ...}]
SLICE = [
    # the hosts and their house (chapter 07, 7.2, the script of a visit)
    ["PB-T01", ["host"], "dechen", [6.0, 21.0], "greet", [], 4],  # a visit's first word, before the door's
    ["PB-T05", ["host"], "tibetan_door", [6.0, 21.0], "greet", [], 3],
    ["PB-T06", ["host"], "tibetan_room", [6.0, 21.0], "greet", [], 3],
    ["PB-T04", ["host"], "roof", [16.9, 17.8], "greet", [], 3],
    ["PB-T08", ["cook"], "kitchen", [6.0, 21.0], "greet", [], 3],
    ["PB-T01", ["household"], "house_kitchen", [6.0, 21.0], "greet", [], 4],  # the houses to enter (ISS-105): a visit's first word,
    ["PB-T06", ["household"], "house_kitchen", [6.0, 21.0], "greet", [], 3],  # then the seat, from whoever is home
    ["PB-T01", ["chang_host"], "chang_room", [10.0, 23.0], "greet", [], 4],  # the chang house (M2 sprint 2): a customer come up the stair,
    ["PB-T06", ["chang_host"], "chang_room", [10.0, 23.0], "greet", [], 3],  # then a seat on the benches
    ["PB-T24", ["host"], "dechen_gate", [16.3, 18.0], "greet", [], 4],
    ["PB-T07", ["host"], "tibetan_room", [0.0, 24.0], "event", [], 0],
    ["PB-T09", ["host"], "tibetan_room", [0.0, 24.0], "event", [], 0],
    ["PB-T10", ["host"], "tibetan_room", [0.0, 24.0], "event", [], 0],
    ["PB-T12", ["host"], "tibetan_room", [0.0, 24.0], "event", [], 0],
    ["PB-T16", ["agent"], "tibetan_room", [0.0, 24.0], "event", [], 0],
    ["PB-T31", ["agent"], "tibetan_room", [0.0, 24.0], "event", [], 0, {"english": "That's fine, it will do."}],
    ["PB-T43", ["host"], "roof", [0.0, 24.0], "event", [], 0],
    ["PB-T46", ["bard"], "chang_room", [0.0, 24.0], "event", [], 0, {"english": "The refrain that opens a song of Gesar."}],
    ["PB-T43", ["lookout_woman"], "lookout", [16.85, 17.7], "near", [], 3],  # her shout to the god in the notch as the juniper takes (chapter 08, V-13a)  # the bard's episode at the chang house (data/talks/m2_bard.json)
    ["PB-T60", ["gatekeeper"], "castle_gate", [17.5, 24.0], "event", [], 0],  # through the barred leaves, to the player at Samkha Khar's shut gate (world/castle_gate.gd)
    ["PB-T62", ["gonkhang_keeper"], "gonkhang_door", [6.0, 23.0], "event", [], 0],  # the Gönkhang's keeper at its curtain, to the player as a woman (world/boots.gd; M3 sprint 6)
    ["PB-T15", ["host"], "tibetan_room", [13.0, 17.0], "overheard", ["host"], 1],
    ["PB-T54", ["agent"], "tibetan_room", [13.0, 16.2], "overheard", ["host"], 1],  # swearing to his price
    ["PB-T55", ["agent"], "tibetan_room", [13.0, 16.2], "overheard", ["host"], 1],
    ["PB-T37", ["cook"], "kitchen", [6.0, 21.0], "near", [], 1],
    # Tsongra's stalls: the women keep them (CX-047), the buyers haggle
    ["PB-T28", ["stall"], "stalls", [7.0, 18.0], "greet", [], 3],
    ["PB-T29", ["stall"], "stalls", [7.0, 18.0], "near", [], 2],
    ["PB-T30", ["stall"], "stalls", [7.0, 18.0], "near", [], 1],
    ["PB-T25", ["buyer"], "stalls", [7.0, 18.0], "overheard", ["stall"], 2],
    ["PB-T26", ["buyer"], "stalls", [7.0, 18.0], "overheard", ["stall"], 2],
    ["PB-T27", ["buyer"], "stalls", [7.0, 18.0], "overheard", ["stall"], 1],
    ["PB-T13", ["buyer"], "stalls", [7.0, 18.0], "overheard", ["stall"], 1],
    ["PB-T33", ["nomad"], "stalls", [7.0, 18.0], "overheard", ["clerk_zh"], 2],
    ["PB-T11", ["nomad"], "stalls", [7.0, 18.0], "leave", [], 2],
    # the greetings of the lanes and the stair (chapter 07, 8.1: "You have come?", "Where are you going?")
    ["PB-T18", ["stall"], "tsongra", [6.0, 20.0], "greet", [], 2],
    ["PB-T19", ["anyone"], "stair", [6.0, 20.0], "near", [], 2],
    ["PB-T17", ["anyone"], "stair", [6.0, 20.0], "pass", [], 2],
    ["PB-T23", ["anyone"], "anywhere", [8.0, 16.0], "overheard", ["anyone"], 1],
    ["PB-T02", ["anyone"], "anywhere", [6.0, 20.0], "overheard", ["elder"], 1],
    ["PB-T32", ["anyone"], "anywhere", [6.0, 20.0], "overheard", ["anyone"], 1],
    ["PB-T49", ["anyone"], "anywhere", [6.0, 20.0], "overheard", ["monk"], 1],
    ["PB-T14", ["anyone"], "anywhere", [6.0, 20.0], "overheard", ["monk"], 1],
    ["PB-T52", ["young_man"], "anywhere", [6.0, 20.0], "overheard", ["young_man"], 1],
    ["PB-T51", ["nyima"], "anywhere", [6.0, 20.0], "overheard", ["mother"], 2, {"english": "Mother."}],
    ["PB-T61", ["child"], "anywhere", [8.0, 17.5], "overheard", ["child"], 1],
    ["PB-T38", ["woman"], "anywhere", [17.3, 18.3], "overheard", ["child"], 2],
    ["PB-T59", ["drover"], "anywhere", [16.6, 17.6], "overheard", ["drover"], 2],
    ["PB-T44", ["old_woman", "elder"], "mani", [5.0, 20.0], "wrong_way", [], 3],
    # the Chinese room and the Han clerk (chapter 07, 7.2's step 9, "in Hejie")
    ["PB-C10", ["host_zh"], "chinese_room", [6.0, 21.0], "greet", [], 3],
    ["PB-C08", ["host_zh"], "chinese_room", [6.0, 21.0], "leave", [], 3],
    ["PB-C13", ["clerk_zh"], "chinese_room", [13.6, 16.4], "overheard", ["host_zh"], 1],  # over Yang's tea (the clerk sits with him 13:40-16:20)
    ["PB-C07", ["clerk_zh"], "chinese_room", [13.6, 16.4], "overheard", ["host_zh"], 1, {"script": "曉得了。", "english": "Got it."}],
    ["PB-C30", ["host_zh"], "chinese_room", [13.0, 19.0], "near", [], 1],
    ["PB-C02", ["host_zh"], "chinese_room", [0.0, 24.0], "event", [], 0, {"english": "Too dear. Come down a bit."}],
    ["PB-C03", ["host_zh"], "chinese_room", [0.0, 24.0], "event", [], 0, {"english": "Agreed!"}],
    ["PB-C04", ["host_zh"], "chinese_room", [0.0, 24.0], "event", [], 0],
    ["PB-C01", ["clerk_zh"], "stalls", [7.0, 18.0], "overheard", ["stall"], 2],
    ["PB-C26", ["clerk_zh"], "stalls", [7.0, 18.0], "overheard", ["nomad"], 2],
    ["PB-C06", ["clerk_zh"], "stalls", [7.0, 18.0], "overheard", ["stall"], 1],
    ["PB-C09", ["clerk_zh"], "tsongra", [11.5, 13.5], "greet", [], 2],
]


def phrasebook():
    text = open(SRC, encoding="utf-8").read()
    out = {}
    for sec, lang in (("### 8.5 Phrasebook: Tibetan", "bo"), ("### 8.6 Phrasebook: Chinese", "zh")):
        body = text[text.index(sec):]
        body = body[:body.index("\n### ", 10)]
        for line in body.splitlines():
            m = re.match(r"\| (PB-[TC]\d+) \| (.+?) \| (.+?) \| (.+?) \| (.+?) \| (.+?) \|(?: (.+?) \|)?$", line.strip())
            if not m:
                continue
            pid, script, roman, meaning, who, note = m.group(1, 2, 3, 4, 5, 6)
            src = m.group(7) or ""
            out[pid] = {"id": pid, "lang": lang, "script": script.strip(), "roman": roman.strip(), "meaning": meaning.strip(),
                        "who": who.strip(), "note": note.strip(), "source": src.strip(),
                        "unverified": "unverified" in script}
    return out


def gloss(meaning):
    """The English a subtitle shows: the plan's meaning without its working marks, "(h.)" and the like."""
    g = meaning if meaning.startswith("(") else re.sub(r"\s*\([^)]*\)", "", meaning).strip()  # the plan's working notes
    g = g.split(": ")[0] if g.startswith("Go slowly") or g.startswith("Stay slowly") else g
    g = g[0].upper() + g[1:] if g else g
    return g if not g or g[-1] in ".?!)" else g + "."


def main():
    pb = phrasebook()
    json.dump({"about": "Chapter 07's phrasebook (8.5 Tibetan, 8.6 Chinese), written by tools/culture/barks.py: do not edit by hand. roman is the plan's Wylie or pinyin, a working notation for Greg's checks only: never shown in the game (Greg, 25 Sep 2026).",
               "lines": pb}, open(os.path.join(ROOT, "data", "phrasebook.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    barks, left_out = [], []
    for row in SLICE:
        pid, who, where, hours, how, with_, weight = row[:7]
        say = row[7] if len(row) > 7 else {}
        p = pb[pid]
        if p["unverified"]:
            left_out.append(pid)
            continue
        barks.append({"id": pid, "lang": p["lang"], "script": say.get("script", p["script"]), "english": say.get("english", gloss(p["meaning"])),
                      "who": who, "where": where, "hours": hours, "how": how, "with": with_, "weight": weight})
    json.dump({"about": "The slice's bark lines (chapter 07, 8.4-8.6; chapter 05, 9.6), written by tools/culture/barks.py: do not edit by hand. Each line on its speakers (roles), place, hours and moment; world/barks.gd says them; the lines of scenes (how: event) are said by those scenes.",
               "roles": ROLES, "barks": barks}, open(os.path.join(ROOT, "data", "barks.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    n_bo = sum(1 for b in barks if b["lang"] == "bo")
    n_zh = sum(1 for b in barks if b["lang"] == "zh")
    print("barks: the phrasebook's %d lines (%d Tibetan, %d Chinese); the slice's %d Tibetan and %d Chinese%s" % (
        len(pb), sum(1 for p in pb.values() if p["lang"] == "bo"), sum(1 for p in pb.values() if p["lang"] == "zh"), n_bo, n_zh,
        ("; left out, script unverified: " + ", ".join(left_out)) if left_out else ""))


if __name__ == "__main__":
    main()
