extends Node
## Calendar (plan chapter 11, 15; spike S13): the season's dates from data/calendar_1903.json (tools/calendar/build.py)
## and the sun and moon at any game minute, by the formulas the tool uses (tools/calendar/sky.py, which the tool's
## tests hold to chapter 02's table 2.8). Game time is local mean solar time at the site, in minutes from 00:00 on
## 21 October 1903, the season's first day (15.1); negative minutes reach back to Losar. A Tibetan day begins at dawn,
## 05:00 (Janson, section 2), so before 05:00 the Tibetan date is the previous civil day's.
## Directions are in Godot's frame (east +X, up +Y, north -Z); the design's north is the sun's (docs/DECISIONS.md).

const DATA := "res://data/calendar_1903.json"
const EPOCH_JD := 2416409  ## the Julian day number of 21 October 1903, game day 0
const DAWN := 300.0  ## minutes: the Tibetan day begins at 05:00
const D2R := PI / 180.0

var lat := 29.973167
var lon := 101.01746
var year := {}
var months := {}
var weekdays: Array = []
var _days: Array = []  ## rows of the JSON, one per civil day
var _first_jd := 0  ## the Julian day number of _days[0]


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if d == null:
		push_error("Calendar: %s missing or unreadable (run tools/py tools/calendar/build.py)" % DATA)
		return
	lat = d["site"]["lat"]
	lon = d["site"]["lon"]
	year = d["year"]
	months = d["months"]
	weekdays = d["weekdays"]
	_days = d["days"]
	_first_jd = jd_number(_date_parts(_days[0]["date"]))


# ---------------------------------------------------------------- dates
## The civil day's row (Tibetan date, flags, sun and moon events) of a game minute, or {} outside the year.
func day_row(minute: float) -> Dictionary:
	var i := EPOCH_JD + int(floor(minute / 1440.0)) - _first_jd
	return _days[i] if i >= 0 and i < _days.size() else {}


## The Tibetan date of a game minute: {year, month, leap_month, day, doubled}; before 05:00 it is the previous day's.
func tibetan_date(minute: float) -> Dictionary:
	var m := minute - DAWN if fposmod(minute, 1440.0) < DAWN else minute
	var row := day_row(m)
	return row.get("tibetan", {})


## The Qing date of a game minute: {year, month, leap, day, term} (the civil day; a Chinese day begins at midnight),
## or {} for the days of 1904, whose table is not in.
func chinese_date(minute: float) -> Dictionary:
	var row := day_row(minute)
	return row["chinese"] if row.has("chinese") and row["chinese"] != null else {}


func flags(minute: float) -> Array:
	var m := minute - DAWN if fposmod(minute, 1440.0) < DAWN else minute
	return day_row(m).get("flags", [])


## "HH:MM" of a game minute, local mean time.
func clock(minute: float) -> String:
	var m := int(floor(fposmod(minute, 1440.0)))
	return "%02d:%02d" % [m / 60, m % 60]


## The game minute of a civil date's LMT hour and minute.
func minute_of(y: int, mo: int, d: int, hh: int = 0, mm: int = 0) -> float:
	return (jd_number([y, mo, d]) - EPOCH_JD) * 1440.0 + hh * 60 + mm


static func jd_number(ymd: Array) -> int:
	var a := (14 - int(ymd[1])) / 12
	var y := int(ymd[0]) + 4800 - a
	var m := int(ymd[1]) + 12 * a - 3
	return int(ymd[2]) + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045


static func _date_parts(iso: String) -> Array:
	var p := iso.split("-")
	return [int(p[0]), int(p[1]), int(p[2])]


## The Julian date (UT) of a game minute.
func jd_ut(minute: float) -> float:
	return EPOCH_JD - 0.5 + minute / 1440.0 - lon / 360.0


# ---------------------------------------------------------------- the sun (sky.py's sun and sun_alt_az)
## (declination, right ascension, equation of time in minutes, ecliptic longitude), degrees.
func _sun(jd: float) -> Array:
	var n := jd - 2451545.0
	var L := fposmod(280.460 + 0.9856474 * n, 360.0)
	var g := fposmod(357.528 + 0.9856003 * n, 360.0)
	var lam := L + 1.915 * sin(g * D2R) + 0.020 * sin(2.0 * g * D2R)
	var eps := 23.439 - 0.0000004 * n
	var ra := fposmod(rad_to_deg(atan2(cos(eps * D2R) * sin(lam * D2R), cos(lam * D2R))), 360.0)
	var dec := rad_to_deg(asin(sin(eps * D2R) * sin(lam * D2R)))
	var eot := (fposmod(L - ra + 180.0, 360.0) - 180.0) * 4.0
	return [dec, ra, eot, fposmod(lam, 360.0)]


## The sun's altitude and azimuth (clockwise from north), degrees, at a game minute.
func sun_alt_az(minute: float) -> Vector2:
	var s := _sun(jd_ut(minute))
	var ast := fposmod(minute, 1440.0) / 60.0 + float(s[2]) / 60.0  # apparent solar time, hours
	var H := (ast - 12.0) * 15.0 * D2R
	return _alt_az(H, float(s[0]) * D2R)


func _alt_az(H: float, dec: float) -> Vector2:
	var phi := lat * D2R
	var alt := asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H))
	var az := atan2(sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi))
	return Vector2(rad_to_deg(alt), fposmod(rad_to_deg(az) + 180.0, 360.0))


## The unit vector towards the sun in Godot's frame; a DirectionalLight3D shines along its negative.
func sun_direction(minute: float) -> Vector3:
	return direction(sun_alt_az(minute))


static func direction(alt_az: Vector2) -> Vector3:
	var a := alt_az.x * D2R
	var z := alt_az.y * D2R
	return Vector3(cos(a) * sin(z), sin(a), -cos(a) * cos(z))


# ---------------------------------------------------------------- the moon (sky.py's moon, Meeus 47, truncated)
const _LR := [[0, 0, 1, 0, 6288774, -20905355], [2, 0, -1, 0, 1274027, -3699111], [2, 0, 0, 0, 658314, -2955968],
	[0, 0, 2, 0, 213618, -569925], [0, 1, 0, 0, -185116, 48888], [0, 0, 0, 2, -114332, -3149],
	[2, 0, -2, 0, 58793, 246158], [2, -1, -1, 0, 57066, -152138], [2, 0, 1, 0, 53322, -170733],
	[2, -1, 0, 0, 45758, -204586], [0, 1, -1, 0, -40923, -129620], [1, 0, 0, 0, -34720, 108743],
	[0, 1, 1, 0, -30383, 104755], [2, 0, 0, -2, 15327, 10321], [0, 0, 1, 2, -12528, 0], [0, 0, 1, -2, 10980, 79661],
	[4, 0, -1, 0, 10675, -34782], [0, 0, 3, 0, 10034, -23210], [4, 0, -2, 0, 8548, -21636], [2, 1, -1, 0, -7888, 24208]]
const _B := [[0, 0, 0, 1, 5128122], [0, 0, 1, 1, 280602], [0, 0, 1, -1, 277693], [2, 0, 0, -1, 173237],
	[2, 0, -1, 1, 55413], [2, 0, -1, -1, 46271], [2, 0, 0, 1, 32573], [0, 0, 2, 1, 17198], [2, 0, 1, -1, 9266],
	[0, 0, 2, -1, 8822]]


## (ecliptic longitude, latitude, distance in km), geocentric.
func _moon(jd: float) -> Array:
	var T := (jd - 2451545.0) / 36525.0
	var Lp := 218.3164477 + 481267.88123421 * T
	var D := 297.8501921 + 445267.1114034 * T
	var M := 357.5291092 + 35999.0502909 * T
	var Mp := 134.9633964 + 477198.8675055 * T
	var Fa := 93.2720950 + 483202.0175233 * T
	var E := 1.0 - 0.002516 * T
	var sl := 0.0
	var sr := 0.0
	var sb := 0.0
	for t in _LR:
		var arg: float = (t[0] * D + t[1] * M + t[2] * Mp + t[3] * Fa) * D2R
		var e := pow(E, absi(t[1]))
		sl += t[4] * e * sin(arg)
		sr += t[5] * e * cos(arg)
	for t in _B:
		sb += t[4] * pow(E, absi(t[1])) * sin((t[0] * D + t[1] * M + t[2] * Mp + t[3] * Fa) * D2R)
	return [fposmod(Lp + sl / 1e6, 360.0), sb / 1e6, 385000.56 + sr / 1000.0]


## The moon's topocentric altitude (parallax taken off) and azimuth, degrees, at a game minute.
func moon_alt_az(minute: float) -> Vector2:
	var jd := jd_ut(minute)
	var m := _moon(jd)
	var eps := (23.439 - 0.0000004 * (jd - 2451545.0)) * D2R
	var l: float = m[0] * D2R
	var b: float = m[1] * D2R
	var ra := atan2(sin(l) * cos(eps) - tan(b) * sin(eps), cos(l))
	var dec := asin(sin(b) * cos(eps) + cos(b) * sin(eps) * sin(l))
	var T := (jd - 2451545.0) / 36525.0
	var gmst := fposmod(280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * T * T, 360.0)
	var aa := _alt_az((gmst + lon) * D2R - ra, dec)
	var par := rad_to_deg(asin(6378.14 / float(m[2])))
	return Vector2(aa.x - par * cos(aa.x * D2R), aa.y)


func moon_direction(minute: float) -> Vector3:
	return direction(moon_alt_az(minute))


## Local sidereal time at the site, degrees: the Greenwich sidereal time (Meeus 12.4) plus the longitude.
func lst(minute: float) -> float:
	var jd := jd_ut(minute)
	var T := (jd - 2451545.0) / 36525.0
	return fposmod(280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * T * T + lon, 360.0)


## The moon's illuminated fraction (0 new, 1 full), from the sun-moon elongation.
func moon_illumination(minute: float) -> float:
	var jd := jd_ut(minute)
	var elong := fposmod(float(_moon(jd)[0]) - float(_sun(jd)[3]), 360.0)
	return (1.0 - cos(elong * D2R)) / 2.0
