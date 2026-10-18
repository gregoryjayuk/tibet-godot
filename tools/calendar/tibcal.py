"""The Tibetan Phugpa calendar (plan chapter 11, 15.2; chapter 01, 3.1-3.2), from Janson's formulas.

Svante Janson, *Tibetan Calendar Mathematics* (https://www2.math.uu.se/~svantejs/papers/calendars/tibet.pdf): the
epoch E806 with beta* = 61, the true month count, the mean date m0 = 2015501 + 4783/5656, the mean sun and the moon's
anomaly, the moon table of 28 steps and the sun table of 12, and the true date whose integer part is the Julian day
number on which a lunar day ends. A lunar day that ends twice in one civil day skips a date; a civil day in which no
lunar day ends repeats one (the first of the pair is the doubled day). The civil day begins at dawn, about 05:00
local mean time (Janson, section 2); the game's Calendar applies that, this module counts whole civil days.
The arithmetic is the program chapter 01 used on 24 Sep 2026, which reproduced every Losar of Janson's Table 1 for
1927-2046 then (that table is not in the repository yet: IMPROVEMENTS, IMP-005).
"""
import datetime
import math
from fractions import Fraction as F

Y0, M0, BSTAR = 806, 3, 61
m1 = F(167025, 5656)
m2 = m1 / 30
m0 = 2015501 + F(4783, 5656)
s1 = F(65, 804)
s2 = s1 / 30
s0 = F(743, 804)
a1 = F(253, 3528)
a2 = F(1, 28)
a0 = F(475, 3528)
MOON = [0, 5, 10, 15, 19, 22, 24, 25]
SUN = [0, 6, 10, 11]


def _table(values, period, x):
    """Janson's symmetric step tables (moon: 28 steps from 0 to 25; sun: 12 steps from 0 to 11), linearly interpolated."""
    q = period // 4

    def base(k):
        k %= period
        if k <= q:
            return values[k]
        if k <= 2 * q:
            return values[2 * q - k]
        if k <= 3 * q:
            return -values[k - 2 * q]
        return -values[period - k]

    x %= period
    fl = math.floor(x)
    return base(fl) + (base(fl + 1) - base(fl)) * (x - fl)


def true_date(d, n):
    """The true date of lunar day d of true month n: its integer part is the Julian day number on which that lunar day ends."""
    frac = lambda x: x - math.floor(x)
    md = n * m1 + d * m2 + m0
    ms = n * s1 + d * s2 + s0
    am = n * a1 + d * a2 + a0
    return md + F(_table(MOON, 28, 28 * frac(am))) / 60 - F(_table(SUN, 12, 12 * frac(ms - F(1, 4)))) / 60


def month_n(Y, M, leap=False):
    """The true month count of Tibetan year Y, month M (the leap month, when there is one, comes first)."""
    return math.floor(F(67 * (12 * (Y - Y0) + M - M0) + BSTAR + 17, 65)) - (1 if leap else 0)


def month_from_n(n):
    """(year, month, is_leap) of true month count n."""
    beta = 184 - BSTAR
    x = math.ceil(F(65 * n + beta, 67))
    M = x % 12 or 12
    Y = math.ceil(F(x, 12)) - 1 + Y0
    return Y, M, ((65 * n + beta) % 67) in (1, 2)


def jd_to_date(jd):
    a = jd + 32044
    b = (4 * a + 3) // 146097
    c = a - 146097 * b // 4
    d = (4 * c + 3) // 1461
    e = c - 1461 * d // 4
    m = (5 * e + 2) // 153
    return datetime.date(100 * b + d - 4800 + m // 10, m + 3 - 12 * (m // 10), e - (153 * m + 2) // 5 + 1)


def date_to_jd(dt):
    a = (14 - dt.month) // 12
    y, m = dt.year + 4800 - a, dt.month + 12 * a - 3
    return dt.day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045


def month_days(n):
    """{Julian day number: (lunar day, doubled)} for true month n. `doubled` marks the first civil day of a doubled date."""
    ends = [math.floor(true_date(d, n)) for d in range(0, 31)]  # d = 0 is the end of the previous month's 30th
    out = {}
    for d in range(1, 31):
        if ends[d] == ends[d - 1]:
            continue  # the lunar day began and ended within one civil day: this date is skipped
        for jd in range(ends[d - 1] + 1, ends[d] + 1):
            out[jd] = (d, jd != ends[d])
    return out


def skipped(n):
    ends = [math.floor(true_date(d, n)) for d in range(0, 31)]
    return [d for d in range(1, 31) if ends[d] == ends[d - 1]]


def losar(Y):
    """The Gregorian date of Losar, the first day of Tibetan year Y (of its leap first month, if it has one)."""
    n = month_n(Y, 1)
    if month_from_n(n - 1)[:2] == (Y, 1):
        n -= 1
    return jd_to_date(min(month_days(n)))


# ---- names (chapter 01, 3.1-3.2; Janson, sections 5.1 and appendices B and E) ----
# Months by the Kalachakra (Indian) names; 9 (tha skar) is confirmed by chapter 01, the others are the standard list
# and wait for a check of their spelling (chapter 16's open questions): the data carries `names_checked`.
MONTHS_KALACHAKRA = [("མཆུ", "mchu", "Māgha"), ("དབོ", "dbo", "Phālguna"), ("ནག་པ", "nag pa", "Caitra"),
                     ("ས་ག", "sa ga", "Vaiśākha"), ("སྣྲོན", "snron", "Jyeṣṭha"), ("ཆུ་སྟོད", "chu stod", "Āṣāḍha"),
                     ("གྲོ་བཞིན", "gro bzhin", "Śrāvaṇa"), ("ཁྲུམས་སྟོད", "khrums stod", "Bhādrapada"),
                     ("ཐ་སྐར", "tha skar", "Āśvina"), ("སྨིན་དྲུག", "smin drug", "Kārttika"),
                     ("མགོ", "mgo", "Mārgaśīrṣa"), ("རྒྱལ", "rgyal", "Pauṣa")]
ANIMALS = [("བྱི་བ", "byi ba", "Mouse"), ("གླང", "glang", "Ox"), ("སྟག", "stag", "Tiger"), ("ཡོས", "yos", "Hare"),
           ("འབྲུག", "'brug", "Dragon"), ("སྦྲུལ", "sbrul", "Snake"), ("རྟ", "rta", "Horse"), ("ལུག", "lug", "Sheep"),
           ("སྤྲེལ", "sprel", "Monkey"), ("བྱ", "bya", "Bird"), ("ཁྱི", "khyi", "Dog"), ("ཕག", "phag", "Pig")]
ELEMENTS = [("ཤིང", "shing", "Wood"), ("མེ", "me", "Fire"), ("ས", "sa", "Earth"), ("ལྕགས", "lcags", "Iron"), ("ཆུ", "chu", "Water")]
# Weekdays as the planets, Monday first (Python's weekday()); Wednesday is gza' lhag pa (chapter 01, 3.2).
WEEKDAYS = [("གཟའ་ཟླ་བ", "gza' zla ba", "Moon"), ("གཟའ་མིག་དམར", "gza' mig dmar", "Mars"),
            ("གཟའ་ལྷག་པ", "gza' lhag pa", "Mercury"), ("གཟའ་ཕུར་བུ", "gza' phur bu", "Jupiter"),
            ("གཟའ་པ་སངས", "gza' pa sangs", "Venus"), ("གཟའ་སྤེན་པ", "gza' spen pa", "Saturn"),
            ("གཟའ་ཉི་མ", "gza' nyi ma", "Sun")]


def phugpa_animal_month(M):
    """Phugpa almanacs name the 9th month the Mouse month (chapter 01, 3.2), so the 1st is the Dragon."""
    return ANIMALS[(M + 3) % 12]


def year_name(Y):
    """Element, gender and animal of Tibetan year Y, and its place in the sixty-year rab byung (the 1st began 1027)."""
    k = (Y - 4) % 60
    element = ELEMENTS[(k % 10) // 2]
    return {"element": element, "female": k % 2 == 1, "animal": ANIMALS[k % 12],
            "rabjung": (Y - 1027) // 60 + 1, "year_of_rabjung": (Y - 1027) % 60 + 1}
