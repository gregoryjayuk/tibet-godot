# Terrain base report: the real ground against chapter 02's design

_Written by `tools/terrain/terrain_check.py` from the shaped ground (`valley_padded_1m`, `ring_shaped_30m`: `tools/terrain/build.sh`, passes 2-6 on the Copernicus GLO-30 base; the column headed "real ground" is that ground). Positions are chapter 02's town grid (x east, y north, metres from Tsongra), laid on the real ground where `data/terrain/site.json` puts it: Tsongra at 29.973° N, 101.017° E, the design turned -15° (true north lies at the design's bearing 015°; every bearing here is the design's), the real ground lowered by 15 m so the real river meets the design's. Angles include the earth's curvature and refraction (k = 0.13). Regenerate by running both scripts._

## 1. Control points: real ground against designed height

| Point | x, y | Designed z | Real ground | Real − 15 − designed |
|---|---|---|---|---|
| T Tsongra | +0, +0 | 2662 | 2676 | -1 |
| C confluence pool | +210, -95 | 2660 | 2671 | -4 |
| X slot exit | -190, -118 | 2593 | 2607 | -1 |
| M Dungchu mouth | -487, -172 | 2541 | 2555 | -1 |
| Gate Chorten | +170, -175 | 2692 | 2707 | +0 |
| Samkha Khar base | -130, -78 | 2640 | 2665 | +10 |
| South Gate | +465, +65 | 2882 | 2898 | +1 |
| Tsokchen court | +535, +110 | 2928 | 2943 | +0 |
| Labrang floor | +620, +215 | 2990 | 2998 | -8 |
| Gorge Rim Lookout | +258, +245 | 2781 | 2796 | +0 |
| Guru Drubphuk | +1080, +400 | 3360 | 3375 | -0 |
| Durtro | +1160, -1040 | 3150 | 3280 | +115 |
| Pharkha dues house | -700, -140 | 2620 | 2635 | +0 |
| Laptse La | +4760, +2750 | 4480 | 4179 | -316 |

Below the Laptse La (the last row, a high-zone design), the RMS of the last column is 32 m.

## 2. Where the real Yalong runs

Designed: centreline x = −525 + 0.04y, water 2,541 m at y = −170, +0.5 m per 100 m upstream. Real: the lowest ground across each line of y, x from −1,350 to +700.

| y | Designed x | Real lowest x | Real east of designed | Real lowest z − 15 | Designed water |
|---|---|---|---|---|---|
| -1090 | -569 | 35 | +604 m | 2538 | 2536 |
| -1000 | -565 | 60 | +625 m | 2529 | 2537 |
| -500 | -545 | -580 | -35 m | 2534 | 2539 |
| -170 | -532 | -550 | -18 m | 2533 | 2541 |
| +0 | -525 | -505 | +20 m | 2533 | 2542 |
| +500 | -505 | -515 | -10 m | 2494 | 2544 |
| +1000 | -485 | -325 | +160 m | 2542 | 2547 |
| +1090 | -481 | -290 | +191 m | 2532 | 2547 |

## 3. Horizons that decide what is seen

| From | Bearing | Needed | Real horizon | Verdict |
|---|---|---|---|---|
| Tsongra (+0, +0; real ground 2676 m, designed 2662) | 033° | Dungri Karpo (11.9° up, 13.0 km) hidden: the ground before it over 11.9° | 28.1° at 0.3 km (2854 m) | as designed |
| Gorge Rim Lookout V-13 (+258, +245; real ground 2796 m, designed 2781) | 033° | Dungri Karpo (11.7° up, 12.7 km) in the notch: the ground before it under 11.7° | 10.4° at 4.4 km (3607 m) | as designed |
| Tsokchen roof V-05 (+540, +150; real ground 2947 m, designed 2952) | 031° | Dungri Karpo (10.9° up, 12.6 km) visible over the gorge: the ground before it under 10.9° | 15.2° at 0.2 km (3049 m) | **differs** |
| Tsongra (+0, +0; real ground 2676 m, designed 2662) | 250° | the western ridge (crest about 3,560 m at 3.9 km): 12–16° | 15.1° at 3.2 km (3532 m) | as designed |
| Conch Eddy V-02 (+190, -90; real ground 2679 m, designed 2666) | 110° | first sun down the Serchu: horizon about 8° | 19.1° at 0.1 km (2712 m) | **differs** |
| Tsongra (+0, +0) | 121–141° | Minya Konka (at 131°) hidden: horizon ≥ 5° on every bearing within 10° of it | lowest 19.1° | as designed |
| Tsokchen roof (+540, +150) | 122–142° | Minya Konka (at 132°) hidden: horizon ≥ 5° on every bearing within 10° of it | lowest 15.0° | as designed |
| Tathang (+300, +700) | 122–142° | Minya Konka (at 132°) hidden: horizon ≥ 5° on every bearing within 10° of it | lowest 11.8° | as designed |
| Laptse La V-08 (+4760, +2750; real ground 4179 m, designed 4480) | 135° | Minya Konka (1.7° over the real ground, 91.6 km) visible: horizon lower | 5.2° at 0.1 km (4190 m) | **differs** |
| Laptse La V-08 at its designed 4,480 m, ground beyond 2 km | 135° | Minya Konka (1.5°) visible: horizon lower | 0.5° at 15.4 km (4640 m) | as designed |

## 4. Minya Konka, as a check on the reprojection

Chapter 02 gives the summit as 29°35′45″ N, 101°52′45″ E, 7,509 m: at this site (+69889, -61708) in the design's grid, 93.2 km from Tsongra at the design's bearing 131°. The highest real ground within 3 km of that point: 7420 m at (+69859, -61828), 0.1 km from it (a 90 m grid rounds a needle summit down).
