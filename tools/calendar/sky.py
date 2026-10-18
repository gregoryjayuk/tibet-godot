"""Sun and moon for the calendar (plan chapter 11, 6.1 and 15.2), the formulas the game also runs (autoload/calendar.gd).

Sun: the standard low-precision formulas chapter 02 used for its table 2.8 (mean longitude and anomaly, the equation of
centre to two terms, obliquity; declination, right ascension and the equation of time; about 0.01 deg). Moon: the
largest terms of Meeus's lunar series (Astronomical Algorithms, chapter 47: 20 in longitude, 10 in latitude, 6 in
distance; better than about 0.1 deg), made topocentric with the horizontal parallax. Angles in degrees; times in local
mean time (LMT) at the site's longitude; JD is the Julian date in UT. Refraction is added only to rise and set, as
h0 = -0.833 deg for the upper limb of the sun and of the (topocentric) moon (Meeus, chapter 15).
"""
import math

D2R = math.pi / 180.0


def jd_ut(year, month, day, hour_ut=0.0):
    """Julian date of a Gregorian date and UT hour."""
    y, m = (year - 1, month + 12) if month <= 2 else (year, month)
    a = y // 100
    b = 2 - a + a // 4
    return math.floor(365.25 * (y + 4716)) + math.floor(30.6001 * (m + 1)) + day + b - 1524.5 + hour_ut / 24.0


def sun(jd):
    """(declination, right ascension, equation of time in minutes, ecliptic longitude), degrees."""
    n = jd - 2451545.0
    L = (280.460 + 0.9856474 * n) % 360.0
    g = (357.528 + 0.9856003 * n) % 360.0
    lam = L + 1.915 * math.sin(g * D2R) + 0.020 * math.sin(2 * g * D2R)
    eps = 23.439 - 0.0000004 * n
    ra = math.degrees(math.atan2(math.cos(eps * D2R) * math.sin(lam * D2R), math.cos(lam * D2R))) % 360.0
    dec = math.degrees(math.asin(math.sin(eps * D2R) * math.sin(lam * D2R)))
    eot = ((L - ra + 180.0) % 360.0 - 180.0) * 4.0
    return dec, ra, eot, lam % 360.0


# Meeus, table 47.A (longitude and distance) and 47.B (latitude): the largest terms. (D, M, M', F, sum_l in 1e-6 deg,
# sum_r in 0.001 km); terms with M are multiplied by E.
_LR = [(0, 0, 1, 0, 6288774, -20905355), (2, 0, -1, 0, 1274027, -3699111), (2, 0, 0, 0, 658314, -2955968),
       (0, 0, 2, 0, 213618, -569925), (0, 1, 0, 0, -185116, 48888), (0, 0, 0, 2, -114332, -3149),
       (2, 0, -2, 0, 58793, 246158), (2, -1, -1, 0, 57066, -152138), (2, 0, 1, 0, 53322, -170733),
       (2, -1, 0, 0, 45758, -204586), (0, 1, -1, 0, -40923, -129620), (1, 0, 0, 0, -34720, 108743),
       (0, 1, 1, 0, -30383, 104755), (2, 0, 0, -2, 15327, 10321), (0, 0, 1, 2, -12528, 0), (0, 0, 1, -2, 10980, 79661),
       (4, 0, -1, 0, 10675, -34782), (0, 0, 3, 0, 10034, -23210), (4, 0, -2, 0, 8548, -21636), (2, 1, -1, 0, -7888, 24208)]
_B = [(0, 0, 0, 1, 5128122), (0, 0, 1, 1, 280602), (0, 0, 1, -1, 277693), (2, 0, 0, -1, 173237), (2, 0, -1, 1, 55413),
      (2, 0, -1, -1, 46271), (2, 0, 0, 1, 32573), (0, 0, 2, 1, 17198), (2, 0, 1, -1, 9266), (0, 0, 2, -1, 8822)]


def moon(jd):
    """(ecliptic longitude, latitude, distance in km), geocentric, of date."""
    T = (jd - 2451545.0) / 36525.0
    Lp = 218.3164477 + 481267.88123421 * T
    D = 297.8501921 + 445267.1114034 * T
    M = 357.5291092 + 35999.0502909 * T
    Mp = 134.9633964 + 477198.8675055 * T
    Fa = 93.2720950 + 483202.0175233 * T
    E = 1.0 - 0.002516 * T
    sl = sr = sb = 0.0
    for d, m, mp, f, l, r in _LR:
        arg = (d * D + m * M + mp * Mp + f * Fa) * D2R
        e = E ** abs(m)
        sl += l * e * math.sin(arg)
        sr += r * e * math.cos(arg)
    for d, m, mp, f, b in _B:
        sb += b * (E ** abs(m)) * math.sin((d * D + m * M + mp * Mp + f * Fa) * D2R)
    return (Lp + sl / 1e6) % 360.0, sb / 1e6, 385000.56 + sr / 1000.0


def ecl_to_eq(lam, beta, jd):
    eps = (23.439 - 0.0000004 * (jd - 2451545.0)) * D2R
    l, b = lam * D2R, beta * D2R
    ra = math.atan2(math.sin(l) * math.cos(eps) - math.tan(b) * math.sin(eps), math.cos(l))
    dec = math.asin(math.sin(b) * math.cos(eps) + math.cos(b) * math.sin(eps) * math.sin(l))
    return math.degrees(ra) % 360.0, math.degrees(dec)


def gmst(jd):
    T = (jd - 2451545.0) / 36525.0
    return (280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * T * T) % 360.0


def alt_az(ra, dec, jd, lat, lon):
    """Altitude and azimuth (from north, clockwise) of an equatorial position, degrees."""
    H = (gmst(jd) + lon - ra) * D2R
    phi, d = lat * D2R, dec * D2R
    alt = math.asin(math.sin(phi) * math.sin(d) + math.cos(phi) * math.cos(d) * math.cos(H))
    az = math.atan2(math.sin(H), math.cos(H) * math.sin(phi) - math.tan(d) * math.cos(phi))
    return math.degrees(alt), (math.degrees(az) + 180.0) % 360.0


def sun_alt_az(jd, lat, lon):
    """The sun's altitude and azimuth as chapter 02 computed them: from the apparent solar time (LMT plus the equation
    of time), so noon falls exactly at the meridian."""
    dec, ra, eot, _ = sun(jd)
    lmt = ((jd + 0.5) % 1.0) * 24.0 + lon / 15.0
    H = ((lmt + eot / 60.0) - 12.0) * 15.0 * D2R
    phi, d = lat * D2R, dec * D2R
    alt = math.asin(math.sin(phi) * math.sin(d) + math.cos(phi) * math.cos(d) * math.cos(H))
    az = math.atan2(math.sin(H), math.cos(H) * math.sin(phi) - math.tan(d) * math.cos(phi))
    return math.degrees(alt), (math.degrees(az) + 180.0) % 360.0


def moon_alt_az(jd, lat, lon):
    """The moon's topocentric altitude (parallax taken off) and azimuth, degrees."""
    lam, beta, dist = moon(jd)
    ra, dec = ecl_to_eq(lam, beta, jd)
    alt, az = alt_az(ra, dec, jd, lat, lon)
    par = math.degrees(math.asin(6378.14 / dist))
    return alt - par * math.cos(alt * D2R), az


def moon_phase(jd):
    """(illuminated fraction, age in days since new moon, waxing), from the sun-moon elongation."""
    lm = moon(jd)[0]
    ls = sun(jd)[3]
    elong = (lm - ls) % 360.0
    return (1.0 - math.cos(elong * D2R)) / 2.0, elong / 360.0 * 29.530589, elong < 180.0


def lmt_to_jd(date, minutes_lmt, lon):
    """Julian date (UT) of a local-mean-time minute of a civil date."""
    return jd_ut(date.year, date.month, date.day, minutes_lmt / 60.0 - lon / 15.0)


def crossing(f, date, lon, h0, start, end, step=10.0):
    """First LMT minute in [start, end) at which altitude f(jd) crosses h0, rising (sign +1) or setting (-1): (rise, set)."""
    out = {}
    prev_m, prev_a = start, f(lmt_to_jd(date, start, lon)) - h0
    m = start + step
    while m <= end:
        a = f(lmt_to_jd(date, m, lon)) - h0
        if (prev_a < 0.0) != (a < 0.0):
            lo, hi = prev_m, m
            for _ in range(30):
                mid = (lo + hi) / 2.0
                am = f(lmt_to_jd(date, mid, lon)) - h0
                if (am < 0.0) == (prev_a < 0.0):
                    lo = mid
                else:
                    hi = mid
            key = "rise" if prev_a < 0.0 else "set"
            out.setdefault(key, (lo + hi) / 2.0)
        prev_m, prev_a = m, a
        m += step
    return out.get("rise"), out.get("set")


def sun_events(date, lat, lon):
    """LMT minutes of sunrise, sunset, the end of civil twilight, and the noon altitude, on a flat horizon."""
    alt = lambda jd: sun_alt_az(jd, lat, lon)[0]
    rise, sset = crossing(alt, date, lon, -0.833, 0.0, 1440.0)
    _, dusk = crossing(alt, date, lon, -6.0, 720.0, 1440.0)
    dawn, _ = crossing(alt, date, lon, -6.0, 0.0, 720.0)
    dec, _, eot, _ = sun(lmt_to_jd(date, 720.0, lon))
    return {"rise": rise, "set": sset, "civil_dawn": dawn, "civil_dusk": dusk, "noon": 720.0 - eot,
            "noon_alt": 90.0 - lat + dec, "dec": dec, "eot": eot}


def moon_events(date, lat, lon):
    alt = lambda jd: moon_alt_az(jd, lat, lon)[0]
    return crossing(alt, date, lon, -0.833, 0.0, 1440.0, step=15.0)  # the upper limb, topocentric (parallax already off)
