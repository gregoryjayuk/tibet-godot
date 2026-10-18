# The gazetteer as data: report

_Written by `tools/town/gazetteer.py`, which reads chapter 02's tables (2.2, 2.5, 4.2, 5.2) into `data/town.json`. Regenerate with `tools/py tools/town/gazetteer.py` after any edit to those tables._

23 control points, 42 levels, 260 buildings and structures (203 with a position, 7 of them without a height), 26 routes.

| District | Rows | With a position |
|---|---|---|
| dungrong | 14 | 12 |
| durtro | 2 | 2 |
| ferry | 11 | 11 |
| gonpa | 41 | 30 |
| hejie | 39 | 35 |
| laptse | 7 | 2 |
| pharkha | 11 | 6 |
| ritro | 9 | 7 |
| samkha | 16 | 14 |
| serchu | 19 | 15 |
| serchu/gonpa | 1 | 0 |
| shol | 40 | 31 |
| tathang | 10 | 6 |
| tode | 26 | 18 |
| tsonggar | 14 | 14 |

## Rows with no position (57)

They name a place in words; the town builder places them from their district and note.

- HEJ-01, Hejie wall: "circuit"
- HEJ-34, Pigsties: "various"
- HEJ-37, Houses H-HEJ-01 to H-HEJ-32: "along River Street and lanes"
- HEJ-38, Houses H-HEJ-33 to H-HEJ-40: "back lanes"
- SAM-14, Retainers' houses H-SAM-01 to H-SAM-08: "Castle Lane and the rim"
- SAM-15, Poor houses H-SAM-09 to H-SAM-12: "under the castle rock"
- SHL-30, Rooftop Way plank bridges (4): "between roofs"
- SHL-31, Shöl leat: "down the Mani Lane"
- SHL-33, Walled gardens and orchards: "upper Shöl"
- SHL-34, Town houses H-SHL-001 to 055: "lower Shöl"
- SHL-35, Log-storey houses H-SHL-056 to 110: "upper Shöl"
- SHL-36, Ngakpa quarter H-SHL-111 to 135: "round Pema Ö"
- SHL-37, West-edge houses H-SHL-136 to 150: "above Hejie's wall"
- SHL-38, House latrine boxes: "on lane walls"
- SHL-39, Roof sang burners: "every roof"
- TOD-03, Bön households H-TOD-045 to 048: "round TOD-02"
- TOD-10, Tödé leat: "intake to (+120, +640)"
- TOD-16, Tower-houses H-TOD-001 to 014: "upper Tödé"
- TOD-17, Log-storey houses H-TOD-015 to 044: "lower and east Tödé"
- TOD-18, Rammed-earth houses H-TOD-049 to 064: "west Tödé"
- TOD-19, Poor houses H-TOD-065 to 068: "field edges"
- TOD-22, Byres and hay stores: "various"
- TOD-24, Maize and turnip racks: "on roofs and fields"
- RNG-06, Gorge prayer-flag spans (6): "y +120 to +260"
- RNG-13, Steps chortens (2) and rest house: "landings 12 and 23"
- MON-21, Monastery wall: "circuit"
- MON-22, Gönkor prayer-wheel gallery: "south and east walls"
- MON-26, Khamtsen halls (4): "round the lower zone"
- MON-27, Monks' houses H-MON-001 to 060: "west face and south flank"
- MON-28, Monks' houses H-MON-061 to 104: "lower and middle zones"
- MON-29, Khamtsen ranges H-MON-105 to 112: "lower zone"
- MON-35, Cham mask store: "in MON-05, upper floor"
- MON-36, Roof victory banners and wheel with deer: "Tsokchen roof"
- MON-37, Three gilded roofs: "MON-01 inner chapel, MON-04, MON-09"
- MON-38, Monastery dogs' kennel: "by MON-19"
- MON-39, Dungri Karpo's shrine in the Gönkhang: "in MON-05"
- SER-02, Eight chortens: "+60 to +130, −150, 2,684"
- SER-09, Serchu water prayer wheels (2): "+420, −195 and +575, −252"
- SER-16, The Shade Wood: "south ridge above the slot"
- SER-17, Monastery barley terraces: "spur south flank"
- SER-18, Yak Road: "mills to the East Gate"
- THG-02, Nomad autumn camp (5 tents): "−100 to +100, +950 to +1,020, 3,080"
- THG-07, Juniper slope: "above +1,050"
- THG-09, Hay barns (3): "lower edge"
- THG-10, Stone mantra (added from chapter 07): "about +450, +1,060, 3,115"
- RIT-02, Retreat huts (7): "ledges 3,320–3,400"
- RIT-06, Cliff flag lines: "across the cliff"
- PHK-05, Houses H-PHK-01 to 16: "the bluff"
- PHK-06, Houses H-PHK-17 to 22: "the bluff"
- PHK-07, Threshing floors (2): "−800, −200 and −900, −20"
- PHK-08, Buckwheat terraces: "the bluff"
- PHK-11, Swim-out beach (added from chapter 06): "about −595, −480, 2,540"
- LAP-03, False-summit lhatse: "4,300 m on the path"
- LAP-04, Yarsa summer huts and corrals (4): "3,960 m on the path"
- LAP-05, Rest cairns (2): "3,700 and 4,150 m"
- LAP-06, Marmot colony: "4,150–4,300 m"
- LAP-07, Dungtso, (invented; added from chapter 08): "centre +4,950, +3,150, 4,380"

## Rows placed outside the valley map (2)

- LAP-01, Laptse La cairn at [4760, 2750, 4480]
- LAP-02, Pass sang burner at [4755, 2745, 4480]

## In the valley map but outside the core (13)

SER-04, SER-12, SER-13, SER-14, SER-19, DUR-01, DUR-02, PHK-01, PHK-02, PHK-03, PHK-04, PHK-09, PHK-10

## Footprints that overlap (9)

Laid square to the grid (the gazetteer gives no rotation), overlapping by more than a metre each way. Some are meant (a shrine in a courtyard, a stall on a square); the rest are for the next review of chapter 02.

- FER-01 and FER-02: 18 × 6 m
- GAR-01 and GAR-03: 59 × 38 m
- GAR-01 and GAR-04: 4 × 12 m
- GAR-01 and GAR-06: 34 × 3 m
- GAR-01 and GAR-09: 45 × 20 m
- SHL-01 and SHL-02: 10 × 6 m
- SHL-08 and SHL-09: 7 × 7 m
- MON-01 and MON-40: 27 × 33 m
- MON-02 and MON-25: 8 × 4 m
