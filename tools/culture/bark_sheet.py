#!/usr/bin/env python3
"""The bark lines' check sheet (M1 sprint 7, step 8; plan chapter 07, 8.1: "Every line of Tibetan and Chinese passes
a native speaker before it ships"). From data/barks.json and data/phrasebook.json (both written by
tools/culture/barks.py) it writes docs/culture/bark-lines-check.md, the record of the check (each line's Check cell is
kept when the file is rebuilt), and renders the same lines in their scripts to tests/culture/out/bark_sheet.pdf, pages
to print or send to the reviewer, and bark_sheet_<n>.jpg. A correction goes into chapter 07's phrasebook (8.5, 8.6),
then `python3 tools/culture/barks.py`, then this again.
Run: tools/py tools/culture/bark_sheet.py
"""
import glob
import json
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "culture", "out")
MD = os.path.join(ROOT, "docs", "culture", "bark-lines-check.md")
FONTS = os.path.join(ROOT, "assets", "source", "fonts")
BO = os.path.join(FONTS, "jomolhari", "Jomolhari-Regular.ttf")  # the game's (ui/subtitles.gd)
ZH = os.path.join(FONTS, "ar-pl-ukai", "ukai.ttc")
LA = os.path.join(FONTS, "noto-serif", "NotoSerif[wdth,wght].ttf")

WHO = {"host": "Achak Dolkar or the house's woman", "cook": "Dechen-tsang's cook", "host_zh": "Yang Shouren",
       "clerk_zh": "the Han clerk", "agent": "the Litang agent", "stall": "a stall-keeper", "nomad": "a nomad woman",
       "mother": "a stall woman", "buyer": "a buyer", "elder": "an elder", "old_woman": "an old woman",
       "child": "a child", "nyima": "Nyima (a boy)", "young_man": "a young man", "drover": "a drover", "woman": "a woman",
       "monk": "a monk", "anyone": "a townsman or townswoman",
       "household": "whoever is home in a house to enter (the grandmother, the mother, the man of the house)",
       "bard": "Drakpa Tharchin, the Gesar bard",
       "gatekeeper": "Samkha Khar's gatekeeper",
       "gonkhang_keeper": "the Gönkhang's keeper",
       "chang_host": "Ama Yudrön or her daughter, at the chang house"}
WHERE = {"anywhere": "anywhere in the town", "stalls": "at Tsongra's stalls", "tsongra": "on Tsongra, the square",
         "stair": "on the Sky Stair", "tibetan_room": "in Dechen-tsang's Tibetan room",
         "chinese_room": "in Yang's Chinese room", "kitchen": "in Dechen-tsang's kitchen", "dechen": "in Dechen-tsang's yards",
         "dechen_gate": "at Dechen-tsang's gate", "tibetan_door": "at the Tibetan room's door",
         "roof": "on Dechen-tsang's roof", "mani": "by the mani wall", "house_kitchen": "in a house to enter's kitchen",
         "chang_room": "in the chang house's drinking room", "castle_gate": "at Samkha Khar's gate, barred",
         "gonkhang_door": "at the Gönkhang's curtain, to the player as a woman"}
# the moments said in words where the data's fields would not say them well: the scenes' lines, and the goodbyes
MOMENT = {
    "PB-T07": "Tea: the hostess, at every pour and refill of the guest's bowl (13:30-16:40); in a house to enter whoever is home pours (about 12:30-20:30)",
    "PB-T09": "Tea: the hostess or the house's one at home, as the guest gets up to go",
    "PB-T12": "Tea: the guest (the player), a palm over the bowl",
    "PB-T10": "The message: Achak Dolkar, riding out to meet the caravan, to the player who stays",
    "PB-T16": "The message: the Litang agent's answer, his fingers in the player's sleeve",
    "PB-T31": "The message: the agent's last word, the deal done",
    "PB-C02": "The message: Yang Shouren's first answer to the agent's price",
    "PB-C04": "The message: Yang, coming up a little",
    "PB-C03": "The message: Yang, agreeing the price",
    "PB-T43": "The roof's juniper at five: the household, as the player lays juniper on the burner (16:58-17:45)",
    "PB-T46": "The chang house at 19:30: the bard, his hat on, opens his short episode with it (data/talks/m2_bard.json); shown on the subtitles while his voice waits for a recording made with consent",
    "PB-T60": "Samkha Khar after the dusk horns: the gatekeeper's answer through the barred leaves to whoever comes to the shut gate (world/castle_gate.gd)",
    "PB-T11": "A nomad woman, as the player walks away from her stall (7:00-18:00)",
    "PB-C08": "Yang Shouren, as the player leaves his room",
    "PB-T44": "An old woman or an elder, to the player walking the mani wall's lane the wrong way",
}
ASK = {
    "PB-T01": "The hostess's first word to her lodger coming into the yard: natural?",
    "PB-T05": "At the Tibetan room's door: ཕེབས་དང་། alone, or ནང་ལ་ཕེབས།?",
    "PB-T04": "Called from the roof to someone coming up the ladder: natural?",
    "PB-T08": "The cook to a lodger in the kitchen: is the honorific too high for a cook?",
    "PB-T24": "The hostess at her gate to a trader coming home at dusk: natural?",
    "PB-T07": "What a hostess says at each refill: this, or something else?",
    "PB-T09": "The goodbye to one leaving: said so in Kham too?",
    "PB-T10": "The goodbye from one leaving (she rides out, the player stays): the right way round?",
    "PB-T12": "What a guest says covering the bowl: this?",
    "PB-T16": "The agent's polite no while haggling in the sleeve: ལགས་མིན། or ལགས་མ་རེད།?",
    "PB-T43": "At the sang fire: this alone, or the whole cry (\"ki ki so so ...\")? If so, how is it spelled?",
    "PB-T46": "The refrain a Gesar bard opens with: this form and spelling, as a Kham bard sang it?",
    "PB-T60": "A gatekeeper calling through a shut gate at dusk: is this how he would say it, and is it said to anyone, or more roughly to a stranger?",
    "PB-T15": "Rockhill heard \"La so, la so\" from a Kham headman: right for the house's woman answering the hostess?",
    "PB-T54": "An oath a trader swears to his price: natural?",
    "PB-T55": "The plan marks it unverified as common usage: is it said?",
    "PB-T37": "The cook at a spill or a burn: natural?",
    "PB-T28": "A stall-keeper calling to a passer-by: natural?",
    "PB-T29": "A price at a stall. Did Kham say a sh-sound for ཕྱ in ཕྱེད? (Rockhill heard it for ཕྱ; unverified for this word)",
    "PB-T27": "A buyer to a stall-keeper: is གནང་ (honorific) right, or plain?",
    "PB-T13": "Rockhill heard Kham \"Ka-dri\" for thanks: right for a buyer at a stall?",
    "PB-T33": "A nomad woman to the Han clerk speaking to her in Chinese: natural?",
    "PB-T11": "Rockhill heard \"dêmo p'eb\" from a nomad in 1892: right as her goodbye?",
    "PB-T18": "A stall-keeper to a stranger crossing the square: natural as a greeting?",
    "PB-T19": "Asked on the stair as a greeting: natural?",
    "PB-T17": "Squeezing past on a narrow stair: this, or something shorter?",
    "PB-T02": "In the Kokonor Rockhill heard \"aku dêmo\": what would Kham say to an elder?",
    "PB-T49": "The plan: common for monks in Amdo and parts of Kham, unverified here. Right for a townsman to a monk?",
    "PB-T14": "Thanks to a monk (honorific): right?",
    "PB-T52": "The plan: Kham and Amdo, unverified. Young men to each other: right?",
    "PB-T51": "A boy to a stall woman who is not his mother: right? (the English says \"Mother.\")",
    "PB-T61": "Children to each other; the plan has the spoken མགྱོགས་པོ, not the literary མྱུར་དུ: right?",
    "PB-T38": "A mother calling the children in at dusk: natural?",
    "PB-T59": "The Tibetan says only that the sun has set; does it carry \"time to go home\", or should the English stop at \"The sun has set.\"?",
    "PB-T44": "An old woman to a stranger going round a mani wall the wrong way: what would she say?",
    "PB-C10": "Yang, a Sichuanese, to a Tibetan lodger coming into his room: natural?",
    "PB-C08": "His goodbye as the player leaves: 慢慢走哈 or 慢走哈?",
    "PB-C13": "The clerk over Yang's tea: does 巴適得很 suit tea, or only a good meal?",
    "PB-C07": "The clerk to Yang: right?",
    "PB-C30": "Yang at bad news (the caravan late), with the player by his desk: natural?",
    "PB-C01": "The Han clerk to a Tibetan stall woman: would he call her 老闆?",
    "PB-C26": "阿佳 for a Tibetan woman, from achak: right?",
    "PB-C09": "The clerk greeting the player at midday on the square: natural?",
}
ASK_DEFAULT = {"bo": "Spelled right? Would a Kham Tibetan say it so, here, in 1903?",
               "zh": "Natural Sichuanese for this speaker in 1903? Characters right?"}
EACH_OTHER = {"anyone": "Townspeople", "young_man": "Young men", "child": "Children", "drover": "Drovers",
              "host": "The hostess and the house's woman"}  # a line said among one role: "... to each other"
SCENE_FILES = ["world/tea.gd", "world/message.gd", "world/roof_sang.gd", "world/castle_gate.gd", "world/boots.gd"] + sorted(  # and the story's scenes: the talks overheard, the conversations
    os.path.relpath(p, ROOT) for p in glob.glob(os.path.join(ROOT, "data", "talks", "*.json")) + glob.glob(os.path.join(ROOT, "data", "conversations", "*.json")))


def hh(h):
    return "%d:%02d" % (int(h), round((h - int(h)) * 60))


def moment(b):
    if b["id"] in MOMENT:
        return MOMENT[b["id"]]
    who = " or ".join(WHO[r] for r in b["who"])
    who = who[0].upper() + who[1:]
    at, hours = WHERE[b["where"]], "%s-%s" % (hh(b["hours"][0]), hh(b["hours"][1]))
    how = b["how"]
    if how == "greet":
        return "%s, greeting the player %s (once a day), %s" % (who, at, hours)
    if how == "near":
        return "%s, to the player standing by, %s, %s" % (who, at, hours)
    if how == "pass":
        return "%s, squeezing past the player %s, %s" % (who, at, hours)
    if how == "overheard" and b["who"] == b["with"] and b["who"][0] in EACH_OTHER:
        return "%s to each other, overheard %s, %s" % (EACH_OTHER[b["who"][0]], at, hours)
    if how == "overheard":
        return "%s to %s, overheard %s, %s" % (who, " or ".join(WHO[r] for r in b["with"]), at, hours)
    return "%s, %s, %s" % (who, at, hours)


def lines_of(barks, pb, lang):
    rows = []
    for b in barks:
        if b["lang"] != lang:
            continue
        p = pb[b["id"]]
        note = p["note"] if p["note"] not in ("—", "") else ""
        rows.append({"id": b["id"], "script": b["script"], "roman": p["roman"], "english": b["english"], "moment": moment(b),
                     "note": note, "ask": ASK.get(b["id"], ASK_DEFAULT[lang])})
    return rows


def unshadded(rows):
    return [r["script"] for r in rows if not r["script"].endswith("།")]


# --- the record: docs/culture/bark-lines-check.md ---

def kept_checks():
    """The Check cells of the file as it stands, by line id."""
    got = {}
    if os.path.exists(MD):
        for ln in open(MD, encoding="utf-8"):
            cells = [c.strip() for c in ln.strip().strip("|").split("|")]
            if len(cells) >= 8 and re.match(r"PB-[TC]\d+$", cells[1]):
                got[cells[1]] = cells[-1]
    return got


def write_md(bo, zh):
    keep = kept_checks()
    out = ["# The bark lines: the language check", "",
           "_What this is: every Tibetan and Chinese line the slice's townspeople say (M1 sprint 7, step 8), in its script, with the plan's Wylie or pinyin (a working notation for this check only: never shown in the game), the English the player reads under it, who says it and when, and a question. Chapter 07, 8.1: every line passes a native speaker before it ships. How to use it: put ✓ in a line's Check cell, or the correction; a correction goes into chapter 07's phrasebook ([07-culture.md](../plan/07-culture.md), 8.5 and 8.6), then `python3 tools/culture/barks.py` rebuilds the game's lines (`data/barks.json`; the scenes and the town take them from there), then `tools/py tools/culture/bark_sheet.py` rebuilds this file (the Check cells are kept) and the pages to print (`tests/culture/out/bark_sheet.pdf`)._", "",
           "## For the reviewer, first", "",
           "1. The lines are in standard spelling; the voices will speak southern Kham (Rockhill heard Batang keep \"nga\" where Lhasa says \"na\", and a sh-sound for ཕྱ and བྱ). Mark any line a Kham speaker of 1903 would say differently.",
           "2. The final ། is left off after ཀ and ག in %d lines: %s. Right in each?" % (len(unshadded(bo)), ", ".join(unshadded(bo))),
           "3. Hosts use the honorific to the player, a guest lodging with them (ཕེབས, བཞུགས, མཆོད); people who are not his hosts wait to be spoken to, but greet him by situation (\"You've come?\", \"Where are you going?\"). Does that match what a traveller would hear?",
           "4. The English is what the player reads under each line: say if it misses the sense or the tone.", "",
           "## Tibetan: %d lines" % len(bo), "",
           "| # | ID | Line | Wylie | English in the game | Who, where, when | Question | Check |", "|---|---|---|---|---|---|---|---|"]
    for k, r in enumerate(bo, 1):
        q = r["ask"] + (" (Kham note: %s)" % r["note"] if r["note"] and r["note"] not in r["ask"] and "Rockhill" not in r["ask"] and "plan" not in r["ask"] else "")
        out.append("| %d | %s | %s | %s | %s | %s | %s | %s |" % (k, r["id"], r["script"], r["roman"], r["english"], r["moment"], q, keep.get(r["id"], "")))
    out += ["", "## Chinese: %d lines" % len(zh), "",
            "Greg checks these himself. The Sichuanese features are general ones (chapter 07, 8.4 and 8.6), not recorded speech of 1903; traditional characters.", "",
            "| # | ID | Line | Pinyin | English in the game | Who, where, when | Question | Check |", "|---|---|---|---|---|---|---|---|"]
    for k, r in enumerate(zh, 1):
        q = r["ask"] + (" (Sichuanese note: %s)" % r["note"] if r["note"] else "")
        out.append("| %d | %s | %s | %s | %s | %s | %s | %s |" % (k, r["id"], r["script"], r["roman"], r["english"], r["moment"], q, keep.get(r["id"], "")))
    os.makedirs(os.path.dirname(MD), exist_ok=True)
    open(MD, "w", encoding="utf-8").write("\n".join(out) + "\n")


# --- the pages ---

W, H = 2200, 1556  # A4 landscape at 190 dpi
M = 64
COLS = [("#", 46), ("Line", 520), ("roman", 300), ("English in the game", 300), ("Who, where, when", 400), ("Question", 364), ("Check", 146)]
INK = (38, 30, 24)
SOFT = (110, 96, 84)
RULE = (196, 184, 164)


def font(path, size, index=0):
    return ImageFont.truetype(path, size, index=index, layout_engine=ImageFont.Layout.RAQM)


RUNS = re.compile(r"[\u0F00-\u0FFF]+|[\u3000-\u303F\u4E00-\u9FFF\uFF00-\uFFEF]+|[^\u0F00-\u0FFF\u3000-\u303F\u4E00-\u9FFF\uFF00-\uFFEF]+")


class Face:
    """A size of the sheet's text: Latin, with the Tibetan and Chinese in it drawn in their own fonts on its baseline."""

    def __init__(self, size, lh, ink):
        # Jomolhari's letters stand about 0.27 em above its baseline (room for the subjoined letters and vowels) and are
        # smaller than the Latin: drawn 1.4 times the size and set down onto the Latin's baseline
        self.la, self.bo, self.zh = font(LA, size), font(BO, round(size * 1.4)), font(ZH, round(size * 1.1))
        self.lh, self.ink, self.asc, self.drop = lh, ink, self.la.getmetrics()[0], round(size * 1.4 * 0.27)

    def _f(self, run):
        c = ord(run[0])
        return self.bo if 0x0F00 <= c <= 0x0FFF else (self.zh if c >= 0x3000 else self.la)

    def length(self, text):
        return sum(self._f(r).getlength(r) for r in RUNS.findall(text))

    def wrap(self, text, width):
        out, cur = [], ""
        for w in text.split(" "):
            t = (cur + " " + w) if cur else w
            if cur and self.length(t) > width:
                out.append(cur)
                cur = w
            else:
                cur = t
        return out + [cur] if cur else out or [""]

    def draw(self, d, x, y, text):
        for r in RUNS.findall(text):
            f = self._f(r)
            d.text((x, y + self.asc + (self.drop if f is self.bo else 0)), r, font=f, fill=self.ink, anchor="ls")
            x += f.getlength(r)


class Script:
    """A line in its own script, wrapped at its syllables (Tibetan) or characters (Chinese)."""

    def __init__(self, lang):
        self.f = font(BO, 46) if lang == "bo" else font(ZH, 42)
        self.lh, self.lang, self.ink = (86 if lang == "bo" else 60), lang, INK

    def wrap(self, text, width):
        toks = re.findall(r"[^་]*་|[^་]+$", text) if self.lang == "bo" else list(text)
        out, cur = [], ""
        for t in toks:
            if cur and self.f.getlength(cur + t) > width:
                out.append(cur)
                cur = t
            else:
                cur += t
        return out + [cur] if cur else out or [""]

    def draw(self, d, x, y, text):
        d.text((x, y), text, font=self.f, fill=self.ink)


def pages(rows, lang, part, note):
    script, body, small, soft = Script(lang), Face(23, 32, INK), Face(20, 28, INK), Face(20, 28, SOFT)
    head, title, lead = Face(21, 28, INK), Face(34, 44, INK), Face(23, 34, SOFT)
    cells = []
    for k, r in enumerate(rows, 1):
        col = [(soft, [str(k)]), (script, script.wrap(r["script"], COLS[1][1] - 24)),
               (soft, soft.wrap(r["roman"], COLS[2][1] - 24)), (body, body.wrap(r["english"], COLS[3][1] - 24)),
               (small, small.wrap(r["moment"], COLS[4][1] - 24)), (soft, soft.wrap(r["ask"], COLS[5][1] - 24)), (small, [""])]
        cells.append((col, max(len(ls) * f.lh for f, ls in col) + 22))
    lead_lines = [ln for t in note for ln in lead.wrap(t, W - 2 * M)]
    y_first = 104 + (len(lead_lines) * lead.lh + 16 if lead_lines else 0) + 44
    out, page, y = [], [], y_first
    for c in cells:
        if page and y + c[1] > H - 80:
            out.append(page)
            page, y = [], 104 + 44
        page.append(c)
        y += c[1]
    out.append(page)
    imgs = []
    for n, pg in enumerate(out):
        im = Image.new("RGB", (W, H), (252, 249, 242))
        d = ImageDraw.Draw(im)
        title.draw(d, M, 44, "Dungkardo, a Kham trading town in 1903: what its people say  ·  %s" % part)
        y = 104
        if n == 0:
            for ln in lead_lines:
                lead.draw(d, M, y, ln)
                y += lead.lh
            y += 16 if lead_lines else 0
        d.rectangle([M, y, W - M, y + 44], fill=(234, 224, 204))
        x = M
        for name, w in COLS:
            head.draw(d, x + 10, y + 8, ("Wylie" if lang == "bo" else "Pinyin") if name == "roman" else name)
            x += w
        y += 44
        for i, (col, h) in enumerate(pg):
            if i % 2:
                d.rectangle([M, y, W - M, y + h], fill=(246, 241, 230))
            x = M
            for (f, ls), (_, w) in zip(col, COLS):
                ty = y + 11
                for ln in ls:
                    f.draw(d, x + 10, ty, ln)
                    ty += f.lh
                x += w
            y += h
            d.line([M, y, W - M, y], fill=RULE, width=1)
        imgs.append(im)
    return imgs


def main():
    d = json.load(open(os.path.join(ROOT, "data", "barks.json"), encoding="utf-8"))
    pb = json.load(open(os.path.join(ROOT, "data", "phrasebook.json"), encoding="utf-8"))["lines"]
    src = "".join(open(os.path.join(ROOT, f), encoding="utf-8").read() for f in SCENE_FILES)
    for b in d["barks"]:
        assert b["how"] != "event" or ('"%s"' % b["id"]) in src, "%s: no scene says it" % b["id"]
    bo, zh = lines_of(d["barks"], pb, "bo"), lines_of(d["barks"], pb, "zh")
    write_md(bo, zh)
    note = ["Each line is shown in its script with the English the player reads under it. Please check the spelling; whether a Kham speaker would say it so, to this person, at this moment; and the English. Write OK or the correction in the last column. The voices will speak southern Kham.",
            "The final ། is left off after ཀ and ག in %d lines, as the plan has them: right in each?" % len(unshadded(bo))]
    imgs = pages(bo, "bo", "Tibetan, %d lines" % len(bo), note)
    imgs += pages(zh, "zh", "Chinese (Sichuanese), %d lines" % len(zh), ["Traditional characters; the Sichuanese features are general ones, not recorded speech of 1903."])
    os.makedirs(OUT, exist_ok=True)
    for n, im in enumerate(imgs, 1):
        Face(20, 28, SOFT).draw(ImageDraw.Draw(im), W - M - 130, H - 56, "page %d of %d" % (n, len(imgs)))
        im.save(os.path.join(OUT, "bark_sheet_%d.jpg" % n), quality=90)
    imgs[0].save(os.path.join(OUT, "bark_sheet.pdf"), save_all=True, append_images=imgs[1:], resolution=190.0)
    print("bark_sheet: %d Tibetan and %d Chinese lines; %s; %d pages in %s" % (len(bo), len(zh), os.path.relpath(MD, ROOT), len(imgs), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
