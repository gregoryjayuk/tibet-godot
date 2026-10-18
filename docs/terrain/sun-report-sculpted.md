# Sun report: first and last sun through the horizon map

_Written by `tools/terrain/horizon.py` (spike S12, art step A8) from the horizon map it bakes over the sculpted ground (passes 2-3, `docs/terrain/sculpt-report.md`). The day is 1903-10-28, the site 29.973° N, 101.017° E; times are local mean time, to the second; the sun's centre against the terrain's horizon, curvature and refraction included, no refraction on the sun. "Direct" marches one ray at the sun's own azimuth; "map" reads the baked map as the shaders do. Regenerate: `tools/py tools/terrain/horizon.py`._

| Place | x, y | Sculpted ground − shift (m) | Map grid | First sun, design | Direct | Map | Last sun, design | Direct | Map | Map − direct, first / last (min) | Sculpted − design, first / last (min) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Laptse La | +4760, +2750 | 4164 | ring | 06:12 | 06:23:15 | 06:22:15 | 17:15 | 15:10:55 | 15:19:36 | -1.0 / +8.7 | +11 / -124 |
| Ritro (Guru Drubphuk, RIT-01) | +1080, +400 | 3360 | core | 06:28 | 06:58:39 | 06:57:20 | 16:59 | 16:50:12 | 16:50:15 | -1.3 / +0.0 | +31 / -9 |
| Labrang and the gilded roofs | +620, +215 | 2986 | core | 06:38 | 07:21:57 | 07:23:42 | 16:40 | 16:35:00 | 16:35:53 | +1.7 / +0.9 | +44 / -5 |
| Upper Tödé, Tathang | +300, +700 | 3056 | core | 06:48 | 08:03:41 | 07:59:48 | 16:35 | 15:38:15 | 15:41:41 | -3.9 / +3.4 | +76 / -57 |
| Confluence pool, Pema Ö | +210, -95 | 2658 | core | 06:52 | 07:46:30 | 08:14:28 | 16:15 | 16:15:16 | 16:14:38 | +28.0 / -0.6 | +54 / +0 |
| Tsongra | +0, +0 | 2662 | core | 07:02 | 07:39:05 | 07:48:11 | 16:10 | 16:07:55 | 16:07:30 | +9.1 / -0.4 | +37 / -2 |
| Hejie River Street (the Water Gate, HEJ-03) | -463, -95 | 2559 | core | 07:17 | 08:03:56 | 08:08:17 | 16:00 | 15:22:57 | 15:25:30 | +4.3 / +2.6 | +47 / -37 |
| The Landing (FER-01) | -480, -60 | 2540 | core | 07:17 | 08:03:27 | 08:03:32 | 15:55 | 15:14:06 | 15:14:36 | +0.1 / +0.5 | +46 / -41 |
| Pharkha bluff (V-03) | -760, -120 | 2645 | valley | 06:52 | 07:46:48 | 07:43:08 | 15:34 | 14:51:21 | 14:52:19 | -3.7 / +1.0 | +55 / -43 |

**The map's own error** against the direct rays, the worst first or last sun per grid: core 28.0 min; valley 3.7 min; ring 8.7 min. The S12 criterion is a minute for the map, and two minutes against chapter 02's times once the ground is sculpted. The ring's 128 m grid is for the mountains' light at a distance, not for timing a point: the Laptse La gets its own map with the high zone (chapter 11, 8.1).

**Art step A8's gates** (chapter 09, 16):
- Labrang and the gilded roofs: last sun 16:35:53 through the map, the design's 16:40: -4 min, **outside the gate** (±3 min).
- Tsongra: last sun 16:07:30 through the map, the design's 16:10: -3 min, within the gate (±3 min).

The last column is the sculpted ground's, through the direct rays.
