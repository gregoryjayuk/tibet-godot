# Sun report: first and last sun through the horizon map

_Written by `tools/terrain/horizon.py` (spike S12, art step A8) from the horizon map it bakes over the shaped ground (`valley_padded_1m`, `ring_shaped_30m`: `tools/terrain/build.sh`, passes 2-6; `docs/terrain/sculpt-report.md`, `horizons-report.md`, `pads-report.md`). The day is 1903-10-28, the site 29.973° N, 101.017° E; times are local mean time, to the second; the sun's centre against the terrain's horizon, curvature and refraction included, no refraction on the sun. "Direct" marches one ray at the sun's own azimuth; "map" reads the baked map as the shaders do. Regenerate: `tools/py tools/terrain/horizon.py`._

| Place | x, y | Sculpted ground − shift (m) | Map grid | First sun, design | Direct | Map | Last sun, design | Direct | Map | Map − direct, first / last (min) | Sculpted − design, first / last (min) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Dungri Karpo summit | +7081, +10956 | 5368 | ring | 06:10 | 06:17:32 | 09:19:11 | 17:17 | 17:17:15 | 16:01:06 | +181.7 / -76.1 | +8 / +0 |
| Laptse La | +4760, +2750 | 4164 | ring | 06:12 | 06:23:15 | 06:22:15 | 17:15 | 15:10:55 | 15:19:36 | -1.0 / +8.7 | +11 / -124 |
| Ritro (Guru Drubphuk, RIT-01) | +1080, +400 | 3360 | core | 06:28 | 06:58:39 | 06:57:20 | 16:59 | 16:50:12 | 16:50:15 | -1.3 / +0.0 | +31 / -9 |
| Labrang and the gilded roofs | +620, +215 | 2982 | core | 06:38 | 07:22:08 | 07:23:32 | 16:40 | 16:34:51 | 16:35:43 | +1.4 / +0.9 | +44 / -5 |
| Upper Tödé, Tathang | +300, +700 | 3045 | core | 06:48 | 07:46:15 | 07:49:05 | 16:35 | 16:24:34 | 16:25:46 | +2.8 / +1.2 | +58 / -10 |
| Confluence pool, Pema Ö | +210, -95 | 2656 | fine | 06:52 | 07:46:42 | 07:46:53 | 16:15 | 16:12:22 | 16:11:19 | +0.2 / -1.0 | +55 / -3 |
| Tsongra | +0, +0 | 2661 | core | 07:02 | 07:39:10 | 07:42:38 | 16:10 | 16:07:52 | 16:07:26 | +3.5 / -0.4 | +37 / -2 |
| Hejie River Street (the Water Gate, HEJ-03) | -463, -95 | 2559 | core | 07:17 | 07:55:23 | 07:57:26 | 16:00 | 15:49:28 | 15:43:58 | +2.1 / -5.5 | +38 / -11 |
| The Landing (FER-01) | -480, -60 | 2540 | core | 07:17 | 08:34:03 | 08:31:19 | 15:55 | 15:38:20 | 15:40:18 | -2.7 / +2.0 | +77 / -17 |
| Pharkha bluff (V-03) | -760, -120 | 2645 | valley | 06:52 | 07:40:13 | 07:37:46 | 15:34 | 15:35:14 | 15:36:30 | -2.5 / +1.3 | +48 / +1 |

**The map's own error** against the direct rays, the worst first or last sun per grid: fine 1.0 min; core 5.5 min; valley 2.5 min; ring 181.7 min. The S12 criterion is a minute for the map, and two minutes against chapter 02's times once the ground is sculpted. The ring's 128 m grid is for the mountains' light at a distance, not for timing a point: the Laptse La gets its own map with the high zone (chapter 11, 8.1).

**Art step A8's gates** (chapter 09, 16):
- Labrang and the gilded roofs: last sun 16:35:43 through the map, the design's 16:40: -4 min, **outside the gate** (±3 min).
- Tsongra: last sun 16:07:26 through the map, the design's 16:10: -3 min, within the gate (±3 min).

The last column is the sculpted ground's, through the direct rays.
