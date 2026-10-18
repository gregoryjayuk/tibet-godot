#!/usr/bin/env python3
"""The conversations' own lines for the language check (M2 sprint 1, step 2; plan chapter 01, 11 and chapter
07, 8.1: every Tibetan and Chinese line passes Greg before it ships). The story's conversations (data/conversations/*.json,
run by world/conversation.gd) say the phrasebook's checked lines where they fit (by their PB ids; their check is
docs/culture/bark-lines-check.md) and lines of their own, which the game shows in English alone until they are written
in their script. This lists every one of their own, who says it and where, with a cell for the line in Tibetan (or
Chinese) and a Check cell; both cells are kept when the file is rebuilt. With --apply, every line whose Check cell holds
a tick and whose script cell is filled is written into its conversation (`bo` or `zh`), and the game shows it in its
script with the English under it.
Run: python3 tools/culture/conversation_lines.py [--apply]   Writes docs/culture/conversation-lines-check.md.
"""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "data", "conversations")
OUT = os.path.join(ROOT, "docs", "culture", "conversation-lines-check.md")
WHO = {"achak_dolkar": "Achak Dolkar, the hostess of Dechen-tsang", "yang_shouren": "Yang Shouren, her husband",
       "ama_yudron": "Ama Yudrön, the chang house's widow", "jiang_deshun": "Jiang Deshun, the post's interpreter",
       "post_soldier": "a soldier of the post", "post_soldier_b": "another soldier of the post",
       "poor_grandmother": "the grandmother of H-SHL-142", "ngodrup_dedpon": "Ngodrup, the caravan's leader"}


def kept():
    """The script and Check cells of the file as it stands, by line id."""
    cells = {}
    if not os.path.exists(OUT):
        return cells
    for row in open(OUT, encoding="utf-8"):
        c = [x.strip() for x in row.strip().strip("|").split("|")]
        if len(c) >= 7 and c[1].startswith("CV-"):
            cells[c[1]] = (c[5], c[6])
    return cells


LINES = os.path.join(ROOT, "data", "story_lines.json")


TALKS = os.path.join(ROOT, "data", "talks")


def lines():
    out = []
    for path in sorted(glob.glob(os.path.join(TALKS, "*.json"))):  # the talk overheard (world/talks.gd)
        talk = json.load(open(path, encoding="utf-8"))
        for k, l in enumerate(talk.get("lines", [])):
            if "line" in l and "en" in l:
                who = l.get("who", "")
                out.append({"id": l["line"], "en": l["en"], "who": WHO.get(who, who.replace("_", " ")), "talk": talk["id"],
                            "path": path, "node": "line %d" % (k + 1), "lang": l.get("lang", "bo")})
    if os.path.exists(LINES):  # the story's own lines said by the world's mechanics (the chang poured, the talk overheard)
        for l in json.load(open(LINES, encoding="utf-8"))["lines"]:
            out.append({"id": l["id"], "en": l["en"], "who": WHO.get(l.get("who", ""), l.get("who", "").replace("_", " ")),
                        "talk": "story_lines", "path": LINES, "node": l.get("where", ""), "lang": l.get("lang", "bo")})
    for path in sorted(glob.glob(os.path.join(SRC, "*.json"))):
        talk = json.load(open(path, encoding="utf-8"))
        for nid, node in talk.get("nodes", {}).items():
            if "line" in node and "en" in node:
                who = node.get("who", talk.get("who", ""))
                out.append({"id": node["line"], "en": node["en"], "who": WHO.get(who, who.replace("_", " ")), "talk": talk["id"],
                            "path": path, "node": nid, "lang": node.get("lang", "bo")})
    return out


def write(rows, cells):
    head = ["# The conversations' own lines: the language check", "",
            "_What this is: every line the story's conversations say that is not already a phrasebook line (M2 sprint 1, step 2), "
            "with who says it, where and when, and the English the player reads now; the game shows it in English alone until "
            "it is written in its script here and checked. How to use it: write the line in Tibetan (or Chinese) in its cell, "
            "put ✓ in its Check cell, then `python3 tools/culture/conversation_lines.py --apply` writes it into its "
            "conversation (data/conversations/), and the game shows it in its script with the English under it. Rebuilt by "
            "the same script without --apply; the two cells are kept. The phrasebook's lines the conversations use are checked "
            "in [bark-lines-check.md](bark-lines-check.md)._", "",
            "| # | ID | English in the game | Who | Where in the story | Tibetan (or Chinese), to write | Check |",
            "|---|---|---|---|---|---|---|"]
    body = []
    for k, r in enumerate(rows):
        script, check = cells.get(r["id"], ("", ""))
        body.append("| %d | %s | %s | %s | %s (%s)%s | %s | %s |" % (k + 1, r["id"], r["en"], r["who"], r["talk"], r["node"],
                                                              ", in Sichuanese: write it in Chinese" if r["lang"] == "zh" else "", script, check))
    open(OUT, "w", encoding="utf-8").write("\n".join(head + body) + "\n")
    print("conversation_lines: %d lines -> %s" % (len(rows), OUT))


def apply(rows, cells):
    n = 0
    for r in rows:
        script, check = cells.get(r["id"], ("", ""))
        if script and "✓" in check:
            data = json.load(open(r["path"], encoding="utf-8"))
            if r["talk"] == "story_lines" or r["path"].startswith(TALKS):
                for l in data["lines"]:
                    if l.get("id", l.get("line")) == r["id"]:
                        l[r["lang"]] = script
            else:
                data["nodes"][r["node"]][r["lang"]] = script
            json.dump(data, open(r["path"], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
            n += 1
    print("conversation_lines: %d checked lines written into their conversations" % n)


def main():
    rows = lines()
    cells = kept()
    if "--apply" in sys.argv:
        apply(rows, cells)
    write(rows, cells)


if __name__ == "__main__":
    main()
