# Terrain base report: the real ground against chapter 02's design

_Written by `tools/terrain/terrain_check.py` from the Copernicus GLO-30 base pass (`tools/terrain/fetch.py`), before any sculpting. Positions are chapter 02's town grid (x east, y north, metres from Tsongra), laid on the real ground where `data/terrain/site.json` puts it: Tsongra at 29.973° N, 101.017° E, the design turned -15° (true north lies at the design's bearing 015°; every bearing here is the design's), the real ground lowered by 15 m so the real river meets the design's. Angles include the earth's curvature and refraction (k = 0.13). Regenerate by running both scripts._

## 1. Control points: real ground against designed height

| Point | x, y | Designed z | Real ground | Real − 15 − designed |
|---|---|---|---|---|
| T Tsongra | +0, +0 | 2662 | 2704 | +27 |
| C confluence pool | +210, -95 | 2660 | 2811 | +136 |
| X slot exit | -190, -118 | 2593 | 2590 | -18 |
| M Dungchu mouth | -487, -172 | 2541 | 2731 | +175 |
| Gate Chorten | +170, -175 | 2692 | 2751 | +44 |
| Samkha Khar base | -130, -78 | 2640 | 2625 | -30 |
| South Gate | +465, +65 | 2882 | 3083 | +186 |
| Tsokchen court | +535, +110 | 2928 | 3126 | +183 |
| Labrang floor | +620, +215 | 2990 | 3196 | +191 |
| Gorge Rim Lookout | +215, +215 | 2778 | 2908 | +115 |
| Guru Drubphuk | +1080, +400 | 3360 | 3287 | -88 |
| Durtro | +1160, -1040 | 3150 | 3299 | +134 |
| Pharkha dues house | -700, -140 | 2620 | 2866 | +231 |
| Laptse La | +4760, +2750 | 4480 | 4179 | -316 |

Below the Laptse La (the last row, a high-zone design), the RMS of the last column is 139 m.

## 2. Where the real Yalong runs

Designed: centreline x = −525 + 0.04y, water 2,541 m at y = −170, +0.5 m per 100 m upstream. Real: the lowest ground across each line of y, x from −1,350 to +700.

| y | Designed x | Real lowest x | Real east of designed | Real lowest z − 15 | Designed water |
|---|---|---|---|---|---|
| -1090 | -569 | 35 | +604 m | 2541 | 2536 |
| -1000 | -565 | 60 | +625 m | 2543 | 2537 |
| -500 | -545 | 70 | +615 m | 2540 | 2539 |
| -170 | -532 | -245 | +287 m | 2550 | 2541 |
| +0 | -525 | -240 | +285 m | 2554 | 2542 |
| +500 | -505 | -305 | +200 m | 2539 | 2544 |
| +1000 | -485 | -255 | +230 m | 2531 | 2547 |
| +1090 | -481 | -290 | +191 m | 2532 | 2547 |

## 3. Horizons that decide what is seen

| From | Bearing | Needed | Real horizon | Verdict |
|---|---|---|---|---|
| Tsongra (+0, +0; real ground 2704 m, designed 2662) | 040° | Dungri Karpo (11.9°) hidden: horizon ≥ 11.9° | 37.8° at 0.5 km (3066 m) | as designed |
| Gorge Rim Lookout V-13 (+215, +215; real ground 2908 m, designed 2778) | 040° | Dungri Karpo (11.7°) in the notch: horizon < 11.7° | 48.4° at 0.0 km (2943 m) | **differs** |
| Tsokchen roof V-05 (+540, +150; real ground 3129 m, designed 2952) | 039° | Dungri Karpo (11°) visible: horizon < 11° | 37.2° at 0.3 km (3359 m) | **differs** |
| Tsongra (+0, +0; real ground 2704 m, designed 2662) | 250° | the western ridge (crest about 3,560 m at 3.9 km): 12–16° | 14.7° at 3.2 km (3534 m) | as designed |
| Conch Eddy V-02 (+190, -90; real ground 2797 m, designed 2666) | 110° | first sun down the Serchu: horizon about 8° | 46.0° at 0.1 km (2907 m) | **differs** |
| Tsongra (+0, +0) | 121–141° | Minya Konka (at 131°) hidden: horizon ≥ 5° on every bearing within 10° of it | lowest 21.4° | as designed |
| Tsokchen roof (+540, +150) | 122–142° | Minya Konka (at 132°) hidden: horizon ≥ 5° on every bearing within 10° of it | lowest 30.0° | as designed |
| Tathang (+300, +700) | 122–142° | Minya Konka (at 132°) hidden: horizon ≥ 5° on every bearing within 10° of it | lowest 40.7° | as designed |
| Laptse La V-08 (+4760, +2750; real ground 4179 m, designed 4480) | 135° | Minya Konka (1.7° over the real ground, 91.6 km) visible: horizon lower | 5.2° at 0.1 km (4190 m) | **differs** |
| Laptse La V-08 at its designed 4,480 m, ground beyond 2 km | 135° | Minya Konka (1.5°) visible: horizon lower | 0.5° at 15.4 km (4640 m) | as designed |

## 4. Minya Konka, as a check on the reprojection

Chapter 02 gives the summit as 29°35′45″ N, 101°52′45″ E, 7,509 m: at this site (+69889, -61708) in the design's grid, 93.2 km from Tsongra at the design's bearing 131°. The highest real ground within 3 km of that point: 7420 m at (+69859, -61828), 0.1 km from it (a 90 m grid rounds a needle summit down).

## 5. Where the designed valley fits the real ground best

`tools/terrain/site_fit.py` slid and turned chapter 02's design over the real 30 m ground within ±9 km of this site, scoring 27 designed points (rivers counted double) by their weighted RMS height error after one vertical shift, held within 30 m of the site's +15 m so the designed river stays at the real river's level.

| Placement | Tsongra at (x, y) in this site's grid | Latitude, longitude | Turned from this site | Vertical shift | RMS error |
|---|---|---|---|---|---|
| This site | 0, 0 | 29.973° N, 101.017° E | 0° | +45 m | 179 m |
| Best 1 | -60, +0 | 29.973° N, 101.017° E | +0° | +45 m | 177 m |
| Best 2 | +2280, -4920 | 29.936° N, 101.053° E | -57° | +45 m | 179 m |
| Best 3 | +1080, +2940 | 30.001° N, 101.020° E | +24° | +45 m | 181 m |
| Best 4 | +3120, -9000 | 29.902° N, 101.073° E | -6° | +45 m | 187 m |
| Best 5 | +480, +1560 | 29.988° N, 101.018° E | +30° | +45 m | 207 m |

Read the RMS as how far, on average, the real ground sits from the design's heights at the scored points. A few tens of metres would mean the real valley has the design's shape and the sculpting passes only refine it; a few hundred mean the design is carved into ground of another shape, which is the case everywhere within 9 km: the valley map is authored either way (chapter 11, 8.1), and the site decides how its edges meet the real rings.

History: the first search (25 Sep 2026, from the old anchor at 30.03° N, 101.01° E) let the shift float up to ±400 m and ranked this site first at 133 m with a shift of +178 m (the old anchor: 416 m at +128 m). Greg chose it (MOVE, 25 Sep, 15:04). A shift that large puts the designed river 164 m above the real one. Held to the river, this site still ranks first within 9 km (179 m; 201 m at the +15 m it uses), and the old anchor scores 423 m.
