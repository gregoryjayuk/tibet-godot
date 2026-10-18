# The Gorge Stair R-07 (tools/town/gorge_stair.py)

_What this is: the planner's report, rewritten each run (M3 sprint 2, step 1). The way from the Gorge Rim Lookout's gap down the gorge's west wall, over the upper bridge RNG-02 and up the east face to the West Gate MON-18; each flight's and landing's fit to the ground (the shaped raster before the pads): the mean height of the ground over its middle, the deepest cut and the highest fill across its 1.8 m band._

- The bridge RNG-02: its middle (335.1, 199.3) over the water at 2710.5 m, its axis 119.1 degrees, its deck at 2716.5 m (6 m over the water; chapter 02: 10 m, but the gorge there is 43 m wide at 10 m), 24 m between its abutments' faces.
- The Lookout's gap at (258.5, 242.2), 2781.5 m; the West Gate's top landing at (443.6, 160.5), 2888.2 m.

## The west leg: 342 steps of 0.190 m in 9 flights (cost 6427)

| leg | piece | steps | bearing | mean | cut | fill |
|---|---|---|---|---|---|---|
| 1 | approach  |  | 297 | 0.6 | 0.1 | 1.2 |
| 1 | flight 1 | 38 | 297 | 0.2 | 0.4 | 0.6 |
| 1 | landing 1 |  | 297 | 0.0 | 0.3 | 0.3 |
| 1 | flight 2 | 38 | 297 | 0.5 | 1.0 | 0.0 |
| 2 | flight 3 | 38 | 355 | 0.6 | 1.9 | 0.9 |
| 2 | landing 3 |  | 355 | 0.2 | 0.6 | 1.0 |
| 2 | flight 4 | 38 | 355 | 1.2 | 0.6 | 3.1 |
| 3 | flight 5 | 38 | 325 | 2.2 | 0.0 | 2.7 |
| 3 | landing 5 |  | 325 | 1.8 | 0.0 | 2.5 |
| 3 | flight 6 | 38 | 325 | 0.6 | 1.2 | 1.5 |
| 4 | flight 7 | 38 | 226 | 1.1 | 3.5 | 3.2 |
| 4 | landing 7 |  | 226 | 2.2 | 0.0 | 3.5 |
| 4 | flight 8 | 38 | 226 | 4.5 | 0.0 | 8.1 |
| 5 | flight 9 | 38 | 264 | 6.6 | 0.0 | 7.5 |

## The east leg: 903 steps of 0.190 m in 24 flights (cost 19924)

| leg | piece | steps | bearing | mean | cut | fill |
|---|---|---|---|---|---|---|
| 1 | approach  |  | 48 | 0.3 | 1.3 | 0.8 |
| 1 | flight 1 | 38 | 48 | 0.5 | 1.6 | 0.5 |
| 1 | landing 1 |  | 48 | 0.6 | 1.5 | 0.2 |
| 1 | flight 2 | 38 | 48 | 1.0 | 2.1 | 0.2 |
| 2 | flight 3 | 38 | 177 | 1.7 | 4.9 | 1.7 |
| 2 | landing 3 |  | 177 | 0.5 | 1.1 | 2.0 |
| 2 | flight 4 | 38 | 177 | 2.3 | 0.9 | 5.4 |
| 3 | flight 5 | 38 | 38 | 0.4 | 1.9 | 2.4 |
| 3 | landing 5 |  | 38 | 0.7 | 1.1 | 2.4 |
| 3 | flight 6 | 38 | 38 | 1.0 | 1.2 | 3.2 |
| 4 | flight 7 | 38 | 182 | 1.2 | 4.4 | 2.5 |
| 4 | landing 7 |  | 182 | 0.9 | 1.0 | 2.8 |
| 4 | flight 8 | 38 | 182 | 2.5 | 0.8 | 5.9 |
| 5 | flight 9 | 38 | 33 | 0.6 | 3.0 | 2.7 |
| 5 | landing 9 |  | 33 | 0.7 | 1.4 | 2.8 |
| 5 | flight 10 | 38 | 33 | 1.5 | 1.4 | 4.5 |
| 6 | flight 11 | 38 | 187 | 1.4 | 5.0 | 2.7 |
| 6 | landing 11 |  | 187 | 0.7 | 1.6 | 3.0 |
| 6 | flight 12 | 38 | 187 | 2.5 | 1.4 | 6.4 |
| 7 | flight 13 | 38 | 30 | 0.9 | 4.2 | 2.8 |
| 7 | landing 13 |  | 30 | 0.6 | 1.9 | 3.0 |
| 7 | flight 14 | 38 | 30 | 1.8 | 1.8 | 5.4 |
| 8 | flight 15 | 38 | 188 | 1.6 | 5.7 | 2.5 |
| 8 | landing 15 |  | 188 | 0.3 | 2.1 | 2.8 |
| 8 | flight 16 | 37 | 188 | 2.1 | 1.9 | 6.1 |
| 9 | flight 17 | 37 | 27 | 1.0 | 4.6 | 3.0 |
| 9 | landing 17 |  | 27 | 0.6 | 2.0 | 3.1 |
| 9 | flight 18 | 37 | 27 | 1.9 | 1.7 | 5.7 |
| 10 | flight 19 | 37 | 185 | 1.9 | 6.1 | 2.2 |
| 10 | landing 19 |  | 185 | 0.1 | 2.5 | 2.4 |
| 10 | flight 20 | 37 | 185 | 2.0 | 2.1 | 5.9 |
| 11 | flight 21 | 37 | 24 | 0.9 | 4.4 | 2.8 |
| 11 | landing 21 |  | 24 | 0.4 | 2.0 | 2.8 |
| 11 | flight 22 | 37 | 24 | 1.5 | 1.8 | 5.0 |
| 12 | flight 23 | 37 | 178 | 2.2 | 5.8 | 1.4 |
| 12 | landing 23 |  | 178 | 0.7 | 2.9 | 1.5 |
| 12 | flight 24 | 37 | 178 | 1.2 | 2.5 | 4.5 |

The galleries' places (the east leg's flights standing highest over the ground on their outer side): flights 12, 16, 20.
