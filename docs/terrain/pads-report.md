# Pads report: terrain passes 4-5

_Written by `tools/terrain/pads.py` from `valley_shaped_1m` (plan chapter 11, 8.2; chapter 03, 3.8). A pad's level is the gazetteer's height; cut is how far the ground stood above it on the footprint (uphill, the retaining wall behind), fill how far below (downhill, the wall in front). Over 8 m either way, the design has put a house on a cliff or in a hole: for the next review of chapter 02._

493 pads; an apron of 1.5 m and a batter of 2 m; the town builder's 155 houses each with a level yard of 3.4-4.6 m before its front and walled edges (24043 m² of yards and aprons). The worst cuts and fills:

| Pad | x, y | Level | Cut | Fill |
|---|---|---|---|---|
| MON-01 | +540, +150 | 2932 | 14.7 m | 5.8 m |
| SHL-07 | +110, +20 | 2670 | 13.8 m | -1.8 m |
| SHL-11 | +166, -56 | 2670 | 12.9 m | -2.7 m |
| RNG-10 | +270, -64 | 2684 | 12.1 m | 7.5 m |
| TOD-25 | -10, +270 | 2784 | 12.0 m | -4.3 m |
| FER-11 | -455, +785 | 2584 | -3.6 m | 11.8 m |
| SHL-08 | +6, +95 | 2705 | -1.4 m | 11.3 m |
| SHL-28 | +140, +60 | 2700 | 10.9 m | -2.4 m |
| PHK-02 | -700, -140 | 2620 | 10.0 m | -3.5 m |
| MON-04 | +585, +160 | 2945 | 9.7 m | 1.4 m |
| PHK-03 | -850, -90 | 2675 | -5.7 m | 9.4 m |
| SHL-19 | -95, +27 | 2655 | 0.5 m | 9.3 m |
| HEJ-33 | -455, -20 | 2560 | -6.9 m | 8.7 m |
| MON-05 | +500, +150 | 2930 | 8.3 m | -0.4 m |
| H-TOD-063 | -297, +514 | 2924 | 5.5 m | 8.1 m |
| MON-23 | +720, +140 | 2974 | 7.5 m | 0.3 m |
| SHL-01.1 | +0, +8 | 2662 | 7.4 m | -0.1 m |
| SHL-24 | +70, +30 | 2678 | 7.2 m | -3.7 m |
| MON-17 | +465, +65 | 2883 | 7.1 m | -2.6 m |
| SHL-21 | -30, +40 | 2680 | -3.3 m | 7.0 m |
| FER-03 | -470, -30 | 2546 | 1.5 m | 7.0 m |
| FER-09 | -462, +30 | 2550 | 2.6 m | 6.9 m |
| SHL-04 | -75, -40 | 2650 | 6.7 m | 5.1 m |
| MON-13 | +480, +67 | 2898 | 6.6 m | 6.0 m |
| RIT-03 | +1130, +445 | 3380 | -4.7 m | 6.6 m |

15 pads cut or fill more than 8 m; 0 more than 20 m.

**Road beds:** SHL-15 Sky Stair (R-05), its ground moved at most 7.3 m to its bed (the grade, or 0.4 m under its ramps where they dip under it; 1.77 m under the grade at most); SHL-11 Pema Ö's steps, its ground moved at most 4.6 m to an even 20.4°; R-08 down to Pema Ö's forecourt, its ground moved at most 2.7 m to an even 15.0°; SHL-10 the lingkor's west side, its ground moved at most 8.0 m to an even 25.1°; 53 side lanes (the builder's), 15 flights between yards and 5 down from the lanes' mouths (IMP-023), the Mani Lane and the ramps' 972 lanes (Samkha's two, the garden lane to the Gorge Rim Lookout, the Caravan Ramp, Hejie's River Street, the Castle Ramp, the Serchu road from its Zampa).

**The arrival** (pass 5c, tools/terrain/arrival.py; its check docs/terrain/arrival-report.md): the gallery's rock: raised up to 29.4 m (the face and the crest behind it), the ground under its deck 2.5-12.1 m below it; the nose: raised up to 40.5 m over the hollow, its cutting 109 m long; R-01's bed: 427 m of road and the row's platform, the ground moved at most 18.9 m; the shelf for the south ramp's approach: the slot's rim cut down up to 19.6 m to 2655-2652 m; V-01's near ground: lowered up to 5.8 m in its cone (bearings 262-300, 8-140 m); 24458 cells of 1 m changed, from -19.6 m down to 40.5 m up.

**Samkha** (pass 5d, tools/terrain/samkha.py; its check docs/terrain/samkha-report.md): Samkha Khar's ward levelled at 2649.0 m (the ground moved 10.6 m at most; it had stood 2638.4-2656.6 m); under the chain bridge (x -130, y -95 to -143, its deck 2650.5-2647.8-2655.0 m): the rims cut up to 5.8 m to clear it; the gate passage's floor at 2650.5 m through the castle from the deck's end (y -95) to its inner door (y -78.2), then 5 steps down to the ward (2649.0 m) by y -76.1; the south pavilion's floor levelled at 2655.0 m (the ground moved 4.9 m at most); 1605 cells of 1 m changed (x -152 to -108, y -152 to -66).

**The confluence** (pass 5e, tools/terrain/confluence.py; the rivers' check docs/terrain/rivers-report.md): Dungchu gorge's last or first 75 m, its water 2657.8-2672.1 m; Samkha slot's last or first 75 m, its water 2642.5-2657.8 m; Serchu's last or first 75 m, its water 2657.8-2669.6 m; the pool at C at 2657.8 m, its basin 18 x 14 m; 2112 cells of 1 m cut, up to 8.5 m at (176, -92).
