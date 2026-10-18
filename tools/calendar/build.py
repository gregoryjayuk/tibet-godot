#!/usr/bin/env python3
"""Build data/calendar_1903.json, the season's calendar the game reads (plan chapter 11, 15.2; spike S13).

Every civil day of the Tibetan year, from Losar (Saturday 28 February 1903) to its last day (Tuesday 16 February 1904;
Losar 1904 is the 17th): the Tibetan date (Phugpa,
tibcal.py) with its doubled and skipped days, the day's flags (good days, festivals, court days, the scripted days),
and the sun and moon at the site (sky.py: rise, set, civil twilight, noon, phase), for the almanac page and the
runtime's checks. The site's latitude and longitude come from data/terrain/site.json, since the valley moved (the
design's north is the sun's, so no turn applies to the sky). The Chinese (Qing) dates come from the Hong Kong
Observatory's conversion table for 1903 (~/.cache/dungkardo/downloads/T1903c.txt, docs/VENDOR.md): the Guangxu year,
month (with the leap fifth month), day, the solar terms, Hejie's market days (the 3rd, 6th and 9th of every ten) and
the two Chinese festivals of the season; days of 1904 have `chinese` null (that year's table is not fetched).
Run: tools/py tools/calendar/build.py
"""
import datetime
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sky  # noqa: E402
import tibcal as tc  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "data", "calendar_1903.json")
YEAR = 1903
# Chapter 07 (3.1) and chapter 11 (15.2): the Tibetan days that carry a flag, and the season's two dated festivals.
GOOD_DAYS = {1, 8, 15, 25}
FESTIVALS = {(9, 22): "lhabab_duchen", (10, 25): "ganden_ngamcho"}
EVENTS = {datetime.date(1903, 10, 28): "EV-DD", datetime.date(1903, 11, 11): "EV-LB"}
HKO = os.path.expanduser("~/.cache/dungkardo/downloads/T1903c.txt")
CN_DIGITS = {"一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9, "十": 10}
CN_MONTHS = {"正": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9, "十": 10, "十一": 11, "十二": 12}
CN_FESTIVALS = {(8, 15): "mid_autumn", (9, 9): "double_ninth"}


def cn_day(s):
    """初一..初十, 十一..十九, 二十, 廿一..廿九, 三十 -> 1..30."""
    if s.startswith("初"):
        return CN_DIGITS[s[1]]
    if s == "二十":
        return 20
    if s == "三十":
        return 30
    if s.startswith("廿"):
        return 20 + CN_DIGITS[s[1]]
    if s.startswith("十"):
        return 10 + CN_DIGITS[s[1]]
    raise ValueError(s)


def qing_days(path=HKO):
    """{date: {"year", "month", "leap", "day", "term", "text"}} from the Hong Kong Observatory's table for 1903."""
    out = {}
    if not os.path.exists(path):
        return out
    month, leap, year = 12, False, "光緒二十八年"
    for line in open(path, encoding="utf-8-sig"):
        parts = line.split()
        if len(parts) < 3 or not parts[0][:4].isdigit():
            continue
        y, rest = parts[0].split("年")
        m, rest = rest.split("月")
        d = int(rest.rstrip("日"))
        date = datetime.date(int(y), int(m), d)
        lunar = parts[1]
        if lunar.endswith("月"):
            leap = lunar.startswith("閏")
            month = CN_MONTHS[lunar.lstrip("閏").rstrip("月")]
            if month == 1:
                year = "光緒二十九年"
            day = 1
        else:
            day = cn_day(lunar)
        term = parts[3] if len(parts) > 3 else None
        out[date] = {"year": year, "month": month, "leap": leap, "day": day, "term": term}
    return out


def hhmm(m):
    if m is None:
        return None
    m = int(round(m))
    return "%02d:%02d" % (m // 60 % 24, m % 60)


def flags_for(M, d):
    f = []
    if d in GOOD_DAYS:
        f.append("good_day")
    if d == 10:
        f.append("good_day_pema_o")  # the Guru's day, kept at Pema Ö
    if d == 29:
        f.append("good_day_gonkhang")  # the protectors' day, in the Gönkhang
    if d in (5, 20):
        f.append("court_day")  # the Pönpo's great-court days (design, chapter 07)
    if (M, d) in FESTIVALS:
        f.append(FESTIVALS[(M, d)])
    return f


def build():
    qing = qing_days()
    site = json.load(open(os.path.join(ROOT, "data", "terrain", "site.json"), encoding="utf-8"))
    lat, lon = site["tsongra_lat"], site["tsongra_lon"]
    start, end = tc.losar(YEAR), tc.losar(YEAR + 1)
    n0 = tc.month_n(YEAR, 1)
    if tc.month_from_n(n0 - 1)[:2] == (YEAR, 1):
        n0 -= 1
    days, skipped, months = {}, [], {}
    n = n0
    while True:
        Y, M, leap = tc.month_from_n(n)
        md = tc.month_days(n)
        for jd, (d, doubled) in md.items():
            days[jd] = (Y, M, leap, d, doubled)
        for d in tc.skipped(n):
            skipped.append({"month": M, "leap_month": leap, "day": d})
        months.setdefault(str(M), {"kalachakra": tc.MONTHS_KALACHAKRA[M - 1], "phugpa_animal": tc.phugpa_animal_month(M),
                                   "leap": leap})
        if tc.jd_to_date(max(md)) >= end:
            break
        n += 1
    rows = []
    jd = tc.date_to_jd(start)
    while tc.jd_to_date(jd) < end:
        date = tc.jd_to_date(jd)
        Y, M, leap, d, doubled = days[jd]
        second = (jd - 1) in days and days[jd - 1][1:4] == (M, leap, d)
        s = sky.sun_events(date, lat, lon)
        illum, age, waxing = sky.moon_phase(sky.lmt_to_jd(date, 1200.0, lon))  # at 20:00, the evening sky
        mrise, mset = sky.moon_events(date, lat, lon)
        q = qing.get(date)
        cflags = []
        if q:
            if q["day"] % 10 in (3, 6, 9):
                cflags.append("market_zh")  # Hejie's market days (chapter 02, 8.2)
            if not q["leap"] and (q["month"], q["day"]) in CN_FESTIVALS:
                cflags.append(CN_FESTIVALS[(q["month"], q["day"])])
        rows.append({
            "date": date.isoformat(), "weekday": date.weekday(),
            "tibetan": {"year": Y, "month": M, "leap_month": leap, "day": d,
                        "doubled": "first" if doubled else ("second" if second else None)},
            "chinese": q,
            "flags": flags_for(M, d) + cflags + ([EVENTS[date]] if date in EVENTS else []),
            "sun": {"rise": hhmm(s["rise"]), "set": hhmm(s["set"]), "civil_dawn": hhmm(s["civil_dawn"]),
                    "civil_dusk": hhmm(s["civil_dusk"]), "noon": hhmm(s["noon"]), "noon_alt": round(s["noon_alt"], 1),
                    "dec": round(s["dec"], 2), "eot_min": round(s["eot"], 1)},
            "moon": {"illum_20h": round(illum, 3), "age_20h": round(age, 1), "waxing": waxing, "rise": hhmm(mrise), "set": hhmm(mset)},
        })
        jd += 1
    yn = tc.year_name(YEAR)
    out = {
        "about": "The season's calendar, built by tools/calendar/build.py (plan chapter 11, 15.2; spike S13). Times are local mean time at the site. Tibetan dates are Phugpa (Janson's formulas); a Tibetan day begins at dawn, about 05:00, which the game's Calendar applies. `doubled` marks the two civil days of a doubled date; `skipped` lists the dates no civil day carries. `chinese` is the Qing date from the Hong Kong Observatory's 1903 table (null for the days of 1904). Month names other than the 9th (tha skar) wait for a spelling check. Transliterations here are developer notes: the game shows script and English only (Greg, 25 Sep 2026).",
        "site": {"lat": lat, "lon": lon, "clock": "local mean time, UT + %.4f h" % (lon / 15.0)},
        "year": {"gregorian": YEAR, "tibetan_losar": start.isoformat(), "next_losar": end.isoformat(),
                 "element": yn["element"], "female": yn["female"], "animal": yn["animal"],
                 "rabjung": yn["rabjung"], "year_of_rabjung": yn["year_of_rabjung"],
                 "script": "རབ་བྱུང་བཅོ་ལྔ་པའི་ཆུ་མོ་ཡོས་ལོ", "wylie": "rab byung bco lnga pa'i chu mo yos lo",
                 "qing": "光緒二十九年", "qing_cycle": "癸卯"},
        "months": months,
        "names_checked": {"months_kalachakra": [9]},
        "weekdays": tc.WEEKDAYS,
        "skipped": skipped,
        "days": rows,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return out


if __name__ == "__main__":
    o = build()
    print("calendar: %d days, %s to %s; %d skipped dates -> %s" % (len(o["days"]), o["days"][0]["date"], o["days"][-1]["date"], len(o["skipped"]), OUT))
