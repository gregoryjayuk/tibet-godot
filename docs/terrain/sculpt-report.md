# Sculpt report: terrain passes 2-3

_Written by `tools/terrain/sculpt.py` (plan chapter 11, 8.2; ISS-031). Heights are the design's (the game's): real ground minus the site's shift of 15 m._

## The named places

182 floors and control points (the gazetteer's and chapter 02, 2.2's; bridges, boats and ranges left out). Before: the real ground's RMS 144 m off the design; now 14.6 m (median 3.3 m, worst 115 m). The pads (pass 4) level each footprint to its floor.

| Place | x, y | Design z | Sculpted | Off |
|---|---|---|---|---|
| control | +1160, -1040 | 3150 | 3265 | +115 |
| durtro | +1160, -1040 | 3150 | 3265 | +115 |
| tathang | -380, +900 | 3060 | 2985 | -75 |
| durtro | +1120, -1000 | 3165 | 3212 | +47 |
| tathang | +0, +900 | 3065 | 3038 | -27 |
| dungrong | +318, +172 | 2716 | 2706 | -10 |
| dungrong | +345, +230 | 2735 | 2725 | -10 |
| gonpa | +480, +70 | 2888 | 2897 | +9 |

## The Yalong

The design's centreline x = −525 + 0.04y in the core, bent onto the real river from y = +950 northwards and from y = −350 southwards.

| y | Design x | Real x | Carved x | Water, design | Water, real | Carved |
|---|---|---|---|---|---|---|
| +1095 | -481 | -280 | -281 | 2547.3 | 2536.8 | 2536.8 |
| +900 | -489 | -287 | -489 | 2546.3 | 2533.8 | 2546.3 |
| +500 | -505 | -303 | -505 | 2544.3 | 2542.1 | 2544.3 |
| +0 | -525 | -258 | -525 | 2541.8 | 2559.7 | 2541.8 |
| -170 | -532 | -216 | -532 | 2541.0 | 2550.8 | 2541.0 |
| -500 | -545 | 62 | -482 | 2539.3 | 2542.2 | 2539.6 |
| -800 | -557 | 112 | -123 | 2537.8 | 2542.9 | 2541.1 |
| -1095 | -569 | 42 | 42 | 2536.4 | 2543.6 | 2543.6 |

## Constraints

named 182, bank 409, valley 966, district 804, real 899; a 20 m grid, thin plate λ 0.05; the real relief under 30 m kept.

