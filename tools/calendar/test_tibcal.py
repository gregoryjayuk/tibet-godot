#!/usr/bin/env python3
"""Checks for the calendar tool (plan chapter 11, 15.4): the season's dates from chapter 01 (3.1-3.3); every Losar of
Janson's Table 1 (1927-2046) with its year's name; the Qing dates of the season against the Hong Kong Observatory's
table; the sun of chapter 02's table 2.8; and the sun and moon against Skyfield with JPL's DE421 (within 0.2 and
0.5 deg, and the sun's rising and setting within a minute). Files: docs/VENDOR.md.
Run: tools/py tools/calendar/test_tibcal.py   (exits non-zero on a failure)
"""
import datetime
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sky  # noqa: E402
import tibcal as tc  # noqa: E402

FAILS = []


def check(ok, what):
    print(("ok    " if ok else "FAIL  ") + what)
    if not ok:
        FAILS.append(what)


def tib(date):
    """(month, day, leap_month, doubled first) of a civil date."""
    jd = tc.date_to_jd(date)
    for k in range(-2, 3):
        n = tc.month_n(date.year if date.month > 2 else date.year - 1, 1) + (date.month - 2) + k
        md = tc.month_days(n)
        if jd in md:
            Y, M, leap = tc.month_from_n(n)
            return M, md[jd][0], leap, md[jd][1]
    for n in range(tc.month_n(date.year - 1, 1), tc.month_n(date.year + 1, 1)):
        md = tc.month_days(n)
        if jd in md:
            Y, M, leap = tc.month_from_n(n)
            return M, md[jd][0], leap, md[jd][1]
    return None


D = datetime.date
# ---- the Tibetan year and season (chapter 01, 3.1-3.2)
check(tc.losar(1903) == D(1903, 2, 28) and D(1903, 2, 28).weekday() == 5, "Losar 1903 is Saturday 28 February")
check(tc.losar(1904) == D(1904, 2, 17) and D(1904, 2, 16).weekday() == 1, "the year ends on Tuesday 16 February 1904 (chapter 01, 3.1); Losar 1904 is the 17th")
check(not any(tc.month_from_n(n)[2] for n in range(tc.month_n(1903, 1) - 1, tc.month_n(1904, 1))), "no leap month in 1903")
for date, want, what in [(D(1903, 10, 5), (8, 14), "Mid-Autumn"), (D(1903, 10, 21), (9, 1), "the season opens"),
                         (D(1903, 10, 24), (9, 4), "Frost's Descent"), (D(1903, 10, 28), (9, 8), "the default day"),
                         (D(1903, 11, 5), (9, 15), "the full moon"), (D(1903, 11, 11), (9, 22), "Lhabab Düchen"),
                         (D(1903, 12, 13), (10, 25), "Ganden Ngamchö")]:
    got = tib(date)
    check(got is not None and got[:2] == want, "%s is %d/%d (%s): got %s" % (date, want[0], want[1], what, got and "%d/%d" % got[:2]))
a, b = tib(D(1903, 11, 1)), tib(D(1903, 11, 2))
check(a[:2] == (9, 12) and b[:2] == (9, 12) and a[3] and not b[3], "9/12 is doubled on 1-2 November (the first of the pair marked)")
n9 = tc.month_n(1903, 9)
check(tc.skipped(n9) == [18], "9/18 is skipped, and no other date of the 9th month: %s" % tc.skipped(n9))
yn = tc.year_name(1903)
check((yn["element"][2], yn["female"], yn["animal"][2], yn["rabjung"], yn["year_of_rabjung"]) == ("Water", True, "Hare", 15, 37),
      "1903 is the female Water-Hare, 37th year of the 15th rab byung")
check(tc.phugpa_animal_month(9)[2] == "Mouse", "Phugpa calls the 9th month the Mouse month")
check(tc.WEEKDAYS[D(1903, 10, 28).weekday()][1] == "gza' lhag pa", "Wednesday 28 October is gza' lhag pa")

# ---- the sun on the default day (chapter 02, table 2.8: 30.03 N, 101.01 E, LMT; within 0.2 deg and one minute)
LAT, LON = 30.03, 101.01
day = D(1903, 10, 28)
ev = sky.sun_events(day, LAT, LON)
for key, want in (("rise", 6 * 60 + 10), ("set", 17 * 60 + 17), ("civil_dusk", 17 * 60 + 42), ("noon", 11 * 60 + 43)):
    check(abs(ev[key] - want) <= 1.0, "sun %s at %02d:%02d LMT: computed %02d:%02d" % (key, want // 60, want % 60, int(ev[key]) // 60, int(ev[key]) % 60))
check(abs(ev["noon_alt"] - 47.3) <= 0.2, "noon altitude 47.3: computed %.2f" % ev["noon_alt"])
table = [(7, 0, 9.5, 111), (8, 0, 21.3, 120), (9, 0, 31.9, 131), (10, 0, 40.5, 146), (11, 0, 46.0, 164),
         (13, 0, 43.5, 206), (14, 0, 36.1, 222), (15, 0, 26.3, 235), (16, 0, 15.0, 245), (17, 0, 2.9, 253)]
worst = (0.0, 0.0)
for h, m, alt, az in table:
    a_, z_ = sky.sun_alt_az(sky.lmt_to_jd(day, h * 60 + m, LON), LAT, LON)
    worst = (max(worst[0], abs(a_ - alt)), max(worst[1], abs(z_ - az)))
# the table gives azimuths to the whole degree, so they are checked within 0.5 plus the 0.2 tolerance
check(worst[0] <= 0.2 and worst[1] <= 0.7, "the sun's hourly altitudes and azimuths: worst %.2f deg and %.2f deg" % worst)
for (h, m), az in (((6, 10), 104), ((17, 17), 256)):
    z_ = sky.sun_alt_az(sky.lmt_to_jd(day, h * 60 + m, LON), LAT, LON)[1]
    check(abs(z_ - az) <= 0.7, "the sun's azimuth at %02d:%02d is %d: computed %.1f" % (h, m, az, z_))

# ---- the moon (chapter 01, 3.3): new moon 20 October 22:15 LMT, half lit on the default evening, setting about 23:40,
# full on 5 November. Chapter 01 used Meeus's series too; Skyfield's check waits (IMP-005).
illum, age, waxing = sky.moon_phase(sky.lmt_to_jd(day, 20 * 60, LON))
check(0.45 <= illum <= 0.57 and waxing, "the moon on the default evening is half lit and waxing: %.0f%%" % (100 * illum))
check(abs(age - (8.0 - 0.1)) <= 0.6, "and about 8 days old: %.1f" % age)
_, mset = sky.moon_events(day, LAT, LON)
check(mset is not None and abs(mset - (23 * 60 + 40)) <= 15, "it sets at about 23:40: computed %s" % (mset and "%02d:%02d" % (int(mset) // 60, int(mset) % 60)))
full = max((sky.moon_phase(sky.lmt_to_jd(D(1903, 11, dd), hh * 60, LON))[0], dd) for dd in range(3, 8) for hh in range(0, 24))
check(full[1] == 5, "the moon is fullest on 5 November: %d November (%.3f)" % (full[1], full[0]))


# ---- Janson, Table 1: Losar (Phugpa) and the year's name for 1927-2046, transcribed from tibet.pdf, page 2
TABLE1 = """
4/3 1927 28/2 1987 Fire-Rabbit | 2/3 1957 27/2 2017 Fire-Bird
22/2 1928 18/2 1988 Earth-Dragon | 19/2 1958 16/2 2018 Earth-Dog
10/2 1929 7/2 1989 Earth-Snake | 8/2 1959 5/2 2019 Earth-Pig
1/3 1930 26/2 1990 Iron-Horse | 27/2 1960 24/2 2020 Iron-Mouse
18/2 1931 15/2 1991 Iron-Sheep | 16/2 1961 12/2 2021 Iron-Ox
7/2 1932 5/3 1992 Water-Monkey | 5/2 1962 3/3 2022 Water-Tiger
25/2 1933 22/2 1993 Water-Bird | 24/2 1963 21/2 2023 Water-Rabbit
14/2 1934 11/2 1994 Wood-Dog | 14/2 1964 10/2 2024 Wood-Dragon
4/2 1935 2/3 1995 Wood-Pig | 4/3 1965 28/2 2025 Wood-Snake
23/2 1936 19/2 1996 Fire-Mouse | 21/2 1966 18/2 2026 Fire-Horse
12/2 1937 8/2 1997 Fire-Ox | 10/2 1967 7/2 2027 Fire-Sheep
3/3 1938 27/2 1998 Earth-Tiger | 29/2 1968 26/2 2028 Earth-Monkey
20/2 1939 17/2 1999 Earth-Rabbit | 17/2 1969 14/2 2029 Earth-Bird
9/2 1940 6/2 2000 Iron-Dragon | 7/2 1970 5/3 2030 Iron-Dog
26/2 1941 24/2 2001 Iron-Snake | 26/2 1971 22/2 2031 Iron-Pig
16/2 1942 13/2 2002 Water-Horse | 15/2 1972 12/2 2032 Water-Mouse
5/2 1943 3/3 2003 Water-Sheep | 5/3 1973 2/3 2033 Water-Ox
24/2 1944 21/2 2004 Wood-Monkey | 22/2 1974 19/2 2034 Wood-Tiger
13/2 1945 9/2 2005 Wood-Bird | 11/2 1975 9/2 2035 Wood-Rabbit
4/3 1946 28/2 2006 Fire-Dog | 1/3 1976 27/2 2036 Fire-Dragon
21/2 1947 18/2 2007 Fire-Pig | 19/2 1977 15/2 2037 Fire-Snake
10/2 1948 7/2 2008 Earth-Mouse | 8/2 1978 6/3 2038 Earth-Horse
28/2 1949 25/2 2009 Earth-Ox | 27/2 1979 23/2 2039 Earth-Sheep
17/2 1950 14/2 2010 Iron-Tiger | 17/2 1980 13/2 2040 Iron-Monkey
7/2 1951 5/3 2011 Iron-Rabbit | 5/2 1981 3/3 2041 Iron-Bird
26/2 1952 22/2 2012 Water-Dragon | 24/2 1982 21/2 2042 Water-Dog
14/2 1953 11/2 2013 Water-Snake | 13/2 1983 10/2 2043 Water-Pig
4/2 1954 2/3 2014 Wood-Horse | 3/3 1984 29/2 2044 Wood-Mouse
23/2 1955 19/2 2015 Wood-Sheep | 20/2 1985 17/2 2045 Wood-Ox
12/2 1956 9/2 2016 Fire-Monkey | 9/2 1986 6/2 2046 Fire-Tiger
"""
losars, names = {}, {}
for row in TABLE1.strip().splitlines():
    for half in row.split("|"):
        d1, y1, d2, y2, name = half.split()
        for d, y in ((d1, y1), (d2, y2)):
            dd, mm = d.split("/")
            losars[int(y)] = D(int(y), int(mm), int(dd))
            names[int(y)] = name.replace("Rabbit", "Hare")  # this project's word for the year of the rabbit
bad = [y for y in sorted(losars) if tc.losar(y) != losars[y]]
check(len(losars) == 120 and not bad, "every Losar of Janson's Table 1, 1927-2046, %d years: %s" % (len(losars), bad or "all match"))
bad = [y for y in sorted(names) if "%s-%s" % (tc.year_name(y)["element"][2], tc.year_name(y)["animal"][2]) != names[y]]
check(not bad, "and every year's name: %s" % (bad or "all match"))

# ---- the Qing dates of the season against the Hong Kong Observatory's table (chapter 01, 3.2)
import build  # noqa: E402
qing = build.qing_days()
if not qing:
    check(False, "the Hong Kong Observatory's table is in ~/.cache/dungkardo/downloads/T1903c.txt")
else:
    for date, (m, d), term in [(D(1903, 10, 5), (8, 15), None), (D(1903, 10, 21), (9, 2), None), (D(1903, 10, 24), (9, 5), "霜降"),
                               (D(1903, 10, 28), (9, 9), None), (D(1903, 11, 5), (9, 17), None), (D(1903, 11, 8), (9, 20), "立冬"),
                               (D(1903, 11, 11), (9, 23), None), (D(1903, 12, 13), (10, 25), None)]:
        q = qing[date]
        check((q["month"], q["day"]) == (m, d) and (term is None or q["term"] == term) and q["year"] == "光緒二十九年",
              "%s is Qing %d/%d%s" % (date, m, d, " and " + term if term else ""))
    check(qing[D(1903, 6, 25)]["leap"] and qing[D(1903, 6, 25)]["month"] == 5, "the leap fifth month begins on 25 June 1903")
    check(qing[D(1903, 1, 29)]["month"] == 1 and qing[D(1903, 1, 29)]["day"] == 1, "the Qing new year is 29 January 1903")

# ---- the sun and moon against Skyfield and JPL's DE421, at the site (chapter 11, 15.4)
try:
    import json as _json
    from skyfield.api import load_file, wgs84, load
    eph = load_file(os.path.expanduser("~/.cache/dungkardo/downloads/de421.bsp"))
    ts = load.timescale()
    site = _json.load(open(os.path.join(HERE, "..", "..", "data", "terrain", "site.json")))
    SLAT, SLON = site["tsongra_lat"], site["tsongra_lon"]
    here = eph["earth"] + wgs84.latlon(SLAT, SLON, elevation_m=2662.0 + site["shift_m"])
    worst_s = worst_m = 0.0
    n = 0
    for day in range(0, 54, 3):  # 21 October to 13 December, every third day
        date = D(1903, 10, 21) + datetime.timedelta(days=day)
        for minute in range(0, 1440, 90):
            jd = sky.lmt_to_jd(date, minute, SLON)
            t = ts.ut1_jd(jd)
            for body, ours, worst_name in (("sun", sky.sun_alt_az, "s"), ("moon", sky.moon_alt_az, "m")):
                alt, az, _ = here.at(t).observe(eph[body]).apparent().altaz()
                if alt.degrees < 5.0:
                    continue  # refraction and the horizon make low positions a different question
                a, z = ours(jd, SLAT, SLON)
                err = max(abs(a - alt.degrees), abs(((z - az.degrees + 180.0) % 360.0) - 180.0) * math.cos(math.radians(alt.degrees)))
                if worst_name == "s":
                    worst_s = max(worst_s, err)
                else:
                    worst_m = max(worst_m, err)
                n += 1
    check(worst_s <= 0.2, "the sun against Skyfield: worst %.3f deg over the season's positions above 5 deg" % worst_s)
    check(worst_m <= 0.5, "the moon against Skyfield: worst %.3f deg (%d positions of sun and moon)" % (worst_m, n))
    from skyfield import almanac
    t0, t1 = ts.ut1_jd(sky.lmt_to_jd(D(1903, 10, 28), 0, SLON)), ts.ut1_jd(sky.lmt_to_jd(D(1903, 10, 29), 0, SLON))
    f = almanac.sunrise_sunset(eph, wgs84.latlon(SLAT, SLON))
    tt, ev = almanac.find_discrete(t0, t1, f)
    ev_min = {("rise" if e else "set"): (t.ut1 - sky.lmt_to_jd(D(1903, 10, 28), 0, SLON)) * 1440.0 for t, e in zip(tt, ev)}
    ours = sky.sun_events(D(1903, 10, 28), SLAT, SLON)
    check(abs(ev_min["rise"] - ours["rise"]) <= 1.0 and abs(ev_min["set"] - ours["set"]) <= 1.0,
          "sunrise and sunset on 28 October against Skyfield: %.1f and %.1f minutes apart" % (ev_min["rise"] - ours["rise"], ev_min["set"] - ours["set"]))
except ImportError:
    check(False, "Skyfield is installed in the tools' Python (docs/VENDOR.md)")

print("%d failed" % len(FAILS))
sys.exit(1 if FAILS else 0)
