# The sun tables: the Tsokchen's lantern windows

_Written by `tools/town/sun_table.py` (plan chapter 04, 8.5; the game's M3 sprint 5, step 4). Each opening's sun through the day: the sun's centre over the terrain's horizon along its azimuth (`tools/terrain/horizon.py`'s direct ray over the padded ground), in front of the window's wall, and not behind another building within 300 m (each a box from its kit type's bounds); its shaft followed from the window through the hall's rooms (the kit's hollows) to where it ends. Rerun it after a change to the ground, the hall or the monastery's buildings._

## 28 October 1903 (the default day, chapter 02's table 2.8)

| window | faces | sun from | sun until | on the hall's floor | on the gallery's floor | on a wall, minutes |
|---|---|---|---|---|---|---|
| MON-01:SHAFT_1 | south | 07:25 | 16:32 | 11:03-13:32 | 10:24-14:43 | 289 |
| MON-01:SHAFT_2 | south | 07:25 | 16:32 | 09:56-12:25 | 08:46-13:04 | 290 |
| MON-01:SHAFT_3 | west | 11:44 | 16:31 | — | — | 288 |
| MON-01:SHAFT_4 | west | 11:44 | 16:31 | — | 11:44-15:05 | 86 |
| MON-01:SHAFT_5 | west | 11:44 | 16:32 | 12:13-12:35 | 13:40-15:05 | 181 |
| MON-01:SHAFT_6 | west | 11:44 | 16:32 | 11:44-13:55 | 13:56-15:05 | 87 |
| MON-01:SHAFT_7 | east | 07:25 | 11:43 | 09:33-11:43 | 08:22-09:32 | 57 |
| MON-01:SHAFT_8 | east | 07:25 | 11:43 | 10:53-11:15 | 08:22-09:48 | 150 |
| MON-01:SHAFT_9 | east | 07:25 | 11:43 | — | 08:22-11:43 | 57 |
| MON-01:SHAFT_10 | east | 07:25 | 11:43 | — | — | 259 |
| MON-04:SHAFT_1 | south | 07:25 | 16:20 | — | — | 536 |

## Against chapter 04's card (3.1)

| the card | its time | the ground's |
|---|---|---|
| the first shaft through the east windows | 06:38 (the card); the gilded roofs' first sun 07:22 on the terrain (2.8) | 07:25 |
| the east shafts slide down the west gallery but never reach the hall's floor | the morning | on the floor 09:33-11:43 |
| the south windows take over, their shaft on the aisle at noon | from about 10:30 | on the floor 09:56-13:32 |
| the west windows' shafts onto the east capitals | by 14:30 | lit from 11:44; on the floor 11:44-13:55 |
| no sun after | 16:40 (the card); the gilded roofs' last sun 16:35 on the terrain | 16:32 |

At noon the sun stands 47.1 degrees up at 185.7 degrees; through MON-01:SHAFT_1, 15.6 m over the hall's floor, its shaft runs 21.7 m and ends at the hall's (-0.5, 2.4, 0.1) (the nave from the door at y -15.3 to the inner chapel's wall at 6.6, the central aisle between x -1.5 and 1.5; chapter 04 wants it on the aisle about three-quarters of the way to the chapel, where the tea is carried).

## V-30: the Jampa Lhakhang's lantern window on Maitreya's face

Its sun at noon, where its ray from the window's middle crosses the face's plane (the face 1.0 m across, its chin at 5.75 m and its brow at 6.85 m over the floor; chapter 08: the patch from chin to brow between 21 October and 11 November, across the face from 11:15 to 12:10):

| day | time | lit | across (m) | up (m) | on the face |
|---|---|---|---|---|---|
| 21 Oct | 11:15 | 1.00 | -0.94 | 5.46 | no |
| 21 Oct | 11:40 | 1.00 | -0.15 | 5.45 | no |
| 21 Oct | 12:00 | 1.00 | +0.47 | 5.45 | yes |
| 21 Oct | 12:10 | 1.00 | +0.79 | 5.46 | no |
| 28 Oct | 11:15 | 1.00 | -0.86 | 5.92 | no |
| 28 Oct | 11:40 | 1.00 | -0.12 | 5.91 | yes |
| 28 Oct | 12:00 | 1.00 | +0.47 | 5.91 | yes |
| 28 Oct | 12:10 | 1.00 | +0.77 | 5.92 | no |
| 05 Nov | 11:15 | 1.00 | -0.80 | 6.37 | no |
| 05 Nov | 11:40 | 1.00 | -0.10 | 6.35 | yes |
| 05 Nov | 12:00 | 1.00 | +0.45 | 6.36 | yes |
| 05 Nov | 12:10 | 1.00 | +0.73 | 6.37 | no |
| 11 Nov | 11:15 | 1.00 | -0.78 | 6.65 | no |
| 11 Nov | 11:40 | 1.00 | -0.11 | 6.63 | yes |
| 11 Nov | 12:00 | 1.00 | +0.43 | 6.64 | yes |
| 11 Nov | 12:10 | 1.00 | +0.70 | 6.65 | no |
