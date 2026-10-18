#!/usr/bin/env python3
"""The codex's entries from the plan (chapter 07, 9: CX-001 to CX-146, district by district), for the game's Codex
(autoload/codex.gd; chapter 11, 14.3; M1 sprint 7, step 7): each its id, district, place (the gazetteer's ID), nod (its
title), text (what the codex says when it is found) and truth (A attested, G general practice, L legend, I invented, or a
pair: the kind attested, our placing or detail invented). The plan is the source; rerun after it changes.
Run: python3 tools/culture/codex.py   Writes data/codex.json.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "docs", "plan", "07-culture.md")
OUT = os.path.join(ROOT, "data", "codex.json")
TRUTH = {"A": "attested in a period source", "G": "general practice", "L": "told in the town", "I": "the game's invention"}


def main():
    text = open(SRC, encoding="utf-8").read()
    body = text[text.index("## 9. The codex"):]
    body = body[:body.index("\n## 10.")] if "\n## 10." in body else body
    entries, district, name = [], None, None
    for line in body.splitlines():
        m = re.match(r"### (D\d+) `(\w+)` — (.+)", line)
        if m:
            district, name = m.group(2), m.group(3).strip()
            continue
        if line.startswith("| CX-"):
            cells = [c.strip() for c in line.strip().strip("|").split(" | ")]
            if len(cells) < 5:
                raise SystemExit("codex: a row with %d cells: %s" % (len(cells), line[:80]))
            cid, place, nod, codex_text, truth = cells[0], cells[1], cells[2], " | ".join(cells[3:-1]), cells[-1]
            entries.append({"id": cid, "district": district, "district_name": name, "place": place, "nod": nod,
                            "text": codex_text, "truth": truth})
    json.dump({"about": "The codex's entries (docs/plan/07-culture.md, 9), written by tools/culture/codex.py: do not edit by hand. truth: A attested in a period source, G general practice, L told in the town, I the game's invention; two letters: the kind attested, the placing or detail the game's.",
               "truth": TRUTH, "entries": entries}, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("codex: %d entries in %d districts -> %s" % (len(entries), len({e["district"] for e in entries}), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
