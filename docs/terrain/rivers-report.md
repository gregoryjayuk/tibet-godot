# The rivers on the built ground

_Written by `tools/terrain/rivers.py` from `valley_padded_1m` (M2 sprint 5, step 1): each river's water (`data/rivers.json`) fitted to the ground as built: its line moved onto the built trough across each section, its level the design's (tools/terrain/sculpt.py, chapter 02) or the trough plus the bed's depth where lower, held 0.3 m under the lower bank 1.5 m beyond the water's edge; a point is wet where that water stands 0.15 m or more over the ground under its middle (the game draws water only there)._

| River | Points | Wet | Lowered at most | Lowered, median | Moved onto its trough, at most |
|---|---|---|---|---|---|
| Yalong | 441 | 75% | 51.0 m | 10.7 m | 35.0 m |
| Dungchu gorge | 263 | 48% | 12.1 m | 0.6 m | 9.0 m |
| Samkha slot | 87 | 93% | 3.4 m | 0.0 m | 1.1 m |
| Dungchu fan | 61 | 84% | 3.4 m | 0.4 m | 9.7 m |
| Serchu | 417 | 90% | 49.8 m | 2.4 m | 12.3 m |

Dry stretches are where the built ground stands over the design's water: the Conch terrace's pad over the slot's head (SHL-12, levelled at 2,664 m across the river: M2 sprint 5, step 4's ground pass), the map's edges where the sculpt hands over to the real ground, and the Yalong where its design line leaves the real river's trench (ISS-031). Large lowerings are the Yalong's and the gorge's, where the ground beside the design's line is lower than its water.

**Summary:** Yalong 75% wet; Dungchu gorge 48% wet; Samkha slot 93% wet; Dungchu fan 84% wet; Serchu 90% wet; the pool at the confluence 18 x 14 m, its water at 2657.15 m (the ground round its rim from 2658.09 m).
