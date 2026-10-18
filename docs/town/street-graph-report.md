# The street graph (chapter 11, 12.3)

_Written by `tools/town/graph.py` (M1 sprint 4, step 4; days since sprint 6, step 1): the slice's walkable ground on a 1 m lattice, its flights, the Mani Lane one way, and the walkers' days and routes. Times at the reference pace (1.1 m/s, 0.75 s a step up, 0.50 down)._

245404 nodes (245125 on the 1 m lattice, 33 on the stair's axis, 251 anchors), 1354686 edges, one way on the Mani Lane; 73 flights (the Sky Stair's 17, the talkers' and Tsongra's steps, 55 side lanes'). Of 222 house doors, 198 reach the town, 4 of them only to ground up to 4 m off (the apron before them walled in by its neighbours' pads: H-HEJ-01, H-HEJ-02, H-HEJ-03, H-HEJ-37), and 24 do not (H-SHL-055, H-SHL-099, H-SHL-100, H-SHL-137, H-SHL-139, H-SHL-140, H-SHL-146, H-SHL-149, H-SHL-113, H-SHL-115, H-SHL-118, H-SHL-119, H-SHL-120, H-SHL-122, H-SHL-124, H-SHL-125, H-SHL-126, H-SHL-129, H-SHL-130, H-SHL-131, H-SHL-132, H-SHL-134, H-HEJ-35, HEJ-25); the workshops stood in for: turner, saddler, hejie_square, HEJ-09, HEJ-13, HEJ-21. 245 walkers, 863 routes, 163527 m in all, the longest 811 m.

| Walker | Kind | Pace (m/s) | Home | Out at | The day | Home for the night | Walked (m) |
|---|---|---|---|---|---|---|---|
| 1 | achak dolkar | 1.05 | dechen | 13:40 | 13:50 home, 14:12 home, 14:32 home, 15:00 yak_gate, 16:25 home, 17:00 home, 17:26 home, 17:40 home | 18:20 | 49 |
| 2 | yang shouren | 0.95 | dechen | 13:19 | 13:20 home, 13:42 home | 19:10 | 0 |
| 3 | sonam wangyal | 1.00 | headman | 06:35 | 06:42 home, 07:30 castle_door, 12:15 home, 12:52 home, 15:25 castle_door, 16:25 talkers, 18:00 home | 20:10 | 749 |
| 4 | pasang carver | 0.72 | H-SHL-020 | 04:40 | 06:10 mani, 08:00 pitch, 16:25 mani | 18:45 | 735 |
| 5 | kalsang drolma | 1.05 | H-SHL-078 | 04:10 | 05:30 spring, 06:45 home, 08:05 stalls, 13:20 home, 15:30 spring | 16:45 | 1340 |
| 6 | tsomo nomad | 1.00 | stair_top | 07:35 | 08:30 stalls | 13:10 | 561 |
| 7 | ngodrup dedpon | 1.15 | yak_gate | 10:00 | 10:20 dechen, 11:45 home, 13:35 dechen, 16:30 home, 21:06 dechen, 21:58 dechen | 23:15 | 148 |
| 8 | nyima boy | 1.20 | H-SHL-044 | 05:55 | 06:15 tailor, 06:35 saddler, 06:55 turner, 07:20 home, 08:00 stalls, 10:10 yak_gate, 11:05 talkers, 13:20 home, 14:45 pitch, 16:00 tsongra | 17:25 | 1269 |
| 9 | stall man | 1.00 | H-SHL-012 | 07:20 | 07:35 stalls, 12:15 home, 13:35 stalls | 17:25 | 84 |
| 10 | stall woman | 1.00 | H-SHL-044 | 07:35 | 07:55 stalls, 12:25 home, 13:45 stalls | 17:20 | 259 |
| 11 | porter | 0.95 | H-SHL-039 | 07:58 | 08:08 dechen, 08:42 stalls, 09:08 dechen, 09:45 tsongra, 10:13 dechen, 10:33 home, 13:10 dechen, 14:45 stair_top, 16:05 dechen, 16:37 stalls | 16:55 | 1674 |
| 12 | porter woman | 0.90 | H-SHL-042 | 08:35 | 08:45 dechen, 10:25 stair_top, 11:48 dechen, 12:12 home, 13:55 dechen, 15:31 stair_top, 16:27 tsongra, 16:57 dechen | 17:18 | 1917 |
| 13 | elder man | 0.65 | H-SHL-002 | 04:30 | 05:45 mani, 08:02 home, 11:40 talkers, 13:02 home, 16:30 talkers | 17:32 | 749 |
| 14 | elder woman | 0.60 | H-SHL-052 | 05:10 | 05:53 mani, 08:00 home, 14:45 mani | 17:10 | 259 |
| 15 | boy | 1.25 | H-SHL-001 | 06:40 | 06:52 basin, 07:15 home, 08:15 stalls, 10:10 yak_gate, 11:05 talkers, 13:20 home, 14:32 tsongra, 16:02 basin, 16:30 tsongra_lower | 17:40 | 919 |
| 16 | girl | 1.15 | H-SHL-003 | 06:18 | 06:37 basin, 07:11 home, 08:37 tsongra, 11:05 talkers, 13:23 home, 14:51 tsongra, 16:05 basin | 16:49 | 952 |
| 17 | drover | 1.10 | yak_gate | 24:00 |  | 00:00 | 0 |
| 18 | drover b | 1.10 | yak_gate | 24:00 |  | 00:00 | 0 |
| 19 | nomad woman | 1.00 | stair_top | 07:20 | 08:20 tsongra | 13:22 | 514 |
| 20 | han man | 1.00 | yak_gate | 09:40 | 10:00 dechen, 12:00 stalls, 12:38 tsongra, 13:40 dechen, 16:50 tsongra | 17:30 | 580 |
| 21 | cook | 0.90 | dechen | 05:30 | 05:40 home | 21:15 | 0 |
| 22 | kitchen woman | 1.05 | dechen | 05:45 | 05:55 home, 13:30 home, 16:58 home, 17:30 home, 21:06 home | 21:52 | 0 |
| 23 | house grandmother | 0.55 | H-SHL-007 | 05:40 | 05:50 home, 09:10 mani, 12:10 home | 20:45 | 323 |
| 24 | house mother | 1.00 | H-SHL-054 | 05:30 | 05:40 home, 09:05 stalls, 11:35 home | 21:05 | 613 |
| 25 | house man | 0.95 | H-SHL-004 | 05:50 | 06:00 home, 08:10 tsongra, 12:30 home | 21:15 | 234 |
| 26 | poor grandmother | 0.50 | H-SHL-142 | 04:54 | 05:00 home, 17:40 west_mani, 20:42 home | 22:00 | 245 |
| 27 | ama yudron | 0.80 | chang | 05:50 | 09:00 tsongra, 11:00 home | 23:10 | 222 |
| 28 | yudron daughter | 1.00 | chang | 10:00 | 10:10 home | 23:00 | 0 |
| 29 | jiang deshun | 1.05 | yak_gate | 15:30 | 16:30 chang | 18:20 | 367 |
| 30 | post soldier | 1.10 | yak_gate | 16:15 | 17:05 chang | 19:30 | 367 |
| 31 | post soldier b | 1.00 | yak_gate | 16:10 | 17:08 chang | 19:30 | 367 |
| 32 | drover | 1.10 | yak_gate | 16:55 | 17:45 chang | 22:00 | 367 |
| 33 | drover b | 1.00 | yak_gate | 16:50 | 17:50 chang | 22:00 | 367 |
| 34 | drakpa bard | 0.75 | dechen | 09:30 | 10:00 talkers, 12:40 home, 19:30 chang, 21:02 home | 22:00 | 696 |
| 35 | novice | 1.20 | stair_top | 13:42 | 14:12 lhakhang, 14:56 tsongra | 16:40 | 535 |
| 36 | novice b | 1.15 | stair_top | 13:40 | 14:30 dechen, 15:05 tsongra | 16:43 | 804 |
| 37 | ngakpa man | 1.00 | H-SHL-128 | 07:15 | 07:50 pema_o, 10:00 home, 11:30 tsongra, 13:20 home, 17:00 conch_terrace | 18:00 | 582 |
| 38 | ngakpa man b | 0.85 | H-SHL-111 | 07:05 | 07:40 pema_o, 10:05 home, 15:00 pema_o | 16:40 | 1070 |
| 39 | townswoman b | 0.95 | H-SHL-133 | 05:45 | 06:20 conch_terrace, 07:05 home, 10:50 tsongra, 12:50 home, 15:30 pema_o | 16:30 | 586 |
| 40 | townswoman | 0.90 | H-SHL-116 | 06:05 | 06:40 conch_terrace, 07:35 home, 11:50 tsongra | 14:00 | 1227 |
| 41 | porter | 1.00 | H-SHL-142 | 06:40 | 07:30 west_way | 18:00 | 411 |
| 42 | porter woman | 0.95 | H-SHL-142 | 05:45 | 06:37 west_way, 07:55 home, 08:55 west_way | 17:25 | 823 |
| 43 | girl | 1.10 | H-SHL-142 | 07:00 | 07:46 west_way | 17:16 | 411 |
| 44 | boy | 1.20 | H-SHL-142 | 07:00 | 10:00 west_edge, 12:28 home, 15:00 west_mani | 16:30 | 517 |
| 45 | water woman | 1.00 | H-SHL-108 | 05:18 | 05:40 spring, 06:14 home, 06:40 spring, 07:11 home, 15:30 spring | 16:04 | 417 |
| 46 | water woman b | 0.95 | H-SHL-056 | 05:02 | 05:40 spring, 06:31 home, 07:10 spring, 07:54 home, 15:35 spring | 16:24 | 855 |
| 47 | water woman c | 0.80 | H-SHL-081 | 05:27 | 05:57 spring, 06:43 home, 07:16 spring, 07:53 home, 15:40 spring | 16:28 | 653 |
| 48 | water woman d | 1.05 | H-SHL-072 | 05:19 | 05:41 spring, 06:20 home, 06:46 spring, 07:18 home, 15:46 spring | 16:24 | 581 |
| 49 | water girl | 1.10 | H-SHL-076 | 05:17 | 05:41 spring, 06:24 home, 06:54 spring, 07:28 home, 15:50 spring | 16:33 | 710 |
| 50 | water girl b | 1.15 | H-SHL-109 | 05:03 | 05:42 spring, 06:38 home, 15:32 spring | 16:20 | 657 |
| 51 | lookout woman | 0.60 | H-SHL-095 | 15:52 | 16:52 lookout | 18:34 | 518 |
| 52 | yangchen drolma | 0.95 | headman | 05:20 | 05:30 home, 06:22 home, 06:50 home, 08:00 tsongra, 12:15 home, 12:52 home, 15:00 home, 17:08 home, 18:00 home | 20:10 | 233 |
| 53 | pema wife | 1.05 | headman | 05:40 | 05:50 home, 06:50 home, 07:35 home, 12:15 home, 12:52 home, 15:00 home, 18:00 home | 20:10 | 0 |
| 54 | younger son | 1.10 | headman | 06:40 | 06:50 home, 07:50 home, 12:15 home, 12:52 home, 17:10 home, 18:00 home | 20:10 | 0 |
| 55 | headman grandmother | 0.60 | headman | 05:30 | 05:38 home, 06:50 home, 09:00 mani, 12:15 home, 12:55 home, 15:25 home, 18:00 home | 20:10 | 462 |
| 56 | headman grandchild | 0.70 | headman | 06:40 | 06:50 home, 08:00 home, 12:15 home, 13:10 home, 18:00 home | 19:50 | 0 |
| 57 | headman steward | 1.00 | headman | 05:00 | 05:05 home, 08:00 tsongra, 12:15 home, 18:00 home | 21:00 | 233 |
| 58 | headman groom | 1.05 | headman | 04:40 | 04:45 home, 06:50 home, 07:35 home, 12:15 home, 12:52 home, 18:00 home, 20:30 home | 21:00 | 0 |
| 59 | headman kitchen girl | 1.10 | headman | 04:40 | 04:45 home, 05:35 home, 10:30 home, 10:50 home, 11:30 home, 12:15 home, 12:50 home, 13:30 home, 13:48 home, 14:30 home, 14:48 home, 18:00 home | 21:00 | 0 |
| 60 | tashi phuntsok | 0.85 | stair_top | 08:30 | 09:58 headman | 17:00 | 736 |
| 61 | hejie trader | 1.00 | yak_gate | 14:20 | 15:05 headman | 17:20 | 334 |
| 62 | dechen lama | 0.70 | dechen | 06:10 | 06:32 home, 09:52 home, 17:36 home | 18:26 | 0 |
| 63 | dechen steward | 1.00 | dechen | 10:00 | 11:19 stair_top, 12:48 home, 21:02 home | 21:57 | 802 |
| 64 | porter | 1.00 | dechen | 10:01 | 11:20 stair_top | 12:49 | 802 |
| 65 | drover | 1.00 | dechen | 10:02 | 11:21 stair_top, 12:50 home, 21:04 home | 21:55 | 802 |
| 66 | elder man | 0.85 | dechen | 07:50 | 08:00 home, 12:15 home, 13:05 home, 16:40 home, 21:03 home | 21:56 | 0 |
| 67 | porter | 0.95 | dechen | 07:55 | 08:05 home, 12:15 home, 13:10 home, 16:40 home, 21:03 home | 21:58 | 0 |
| 68 | pieman | 0.90 | yak_gate | 08:10 | 08:40 dechen | 15:30 | 49 |
| 69 | drover b | 1.00 | H-SHL-018 | 09:20 | 09:40 dechen | 13:00 | 255 |
| 70 | stall man | 1.00 | H-SHL-046 | 10:00 | 10:10 dechen | 14:30 | 160 |
| 71 | townsman | 1.09 | H-SHL-141 | 06:16 | 07:13 dechen, 09:55 home, 12:05 river_street, 13:55 home, 17:18 a neighbour's, 20:02 home, 21:14 tsongra, 21:49 talkers | 23:02 | 2857 |
| 72 | porter woman | 1.12 | stair_top | 08:52 | 09:33 tsongra_lower, 10:20 basin, 11:43 river_street, 13:40 basin, 13:54 tsongra_lower | 15:17 | 1713 |
| 73 | han man | 0.99 | tsongra | 05:45 | 06:05 dechen, 07:26 chang, 08:35 home, 09:58 lhakhang, 10:22 home, 11:14 dechen, 12:57 turner, 13:56 dechen, 15:25 tailor, 16:17 dechen, 17:31 home | 17:52 | 1540 |
| 74 | elder man, old | 0.64 | tsongra | 05:39 | 06:08 dechen, 08:20 chang, 09:41 saddler, 10:47 dechen, 12:22 home, 13:28 dechen, 15:06 chang, 16:48 dechen, 17:59 tailor | 18:55 | 1527 |
| 75 | porter | 1.08 | tsongra | 06:07 | 06:24 dechen, 08:19 stalls, 08:54 dechen, 11:08 saddler, 12:02 tailor, 12:44 dechen, 14:07 home, 15:08 dechen | 17:25 | 1131 |
| 76 | stall man | 1.17 | west_way | 06:23 | 07:47 court_wait, 08:26 castle_door, 10:08 stalls, 10:34 dechen, 11:32 MKT-07, 11:50 tsongra_lower | 13:50 | 1563 |
| 77 | post soldier | 1.05 | H-HEJ-27 | 08:15 | 10:01 saddler, 11:00 MKT-11, 11:26 dechen | 14:28 | 1170 |
| 78 | han man, old | 0.79 | H-HEJ-31 | 06:10 | 06:39 HEJ-10, 08:02 east_gate_in, 09:07 water_gate_in, 09:33 HEJ-13, 10:32 river_street, 11:08 HEJ-14, 11:54 HEJ-10, 12:51 home, 14:01 HEJ-10, 14:41 water_gate_in, 15:28 HEJ-14, 16:44 water_gate_in, 17:31 HEJ-14 | 18:52 | 1983 |
| 79 | han man | 1.17 | HEJ-09 | 05:56 | 05:57 home, 07:55 HEJ-08, 08:17 home, 09:46 HEJ-14, 10:33 home, 12:19 river_street, 13:02 home, 15:01 HEJ-14, 15:41 river_street, 16:44 hejie_square, 17:10 HEJ-08, 17:33 home, 19:24 HEJ-14 | 21:29 | 614 |
| 80 | han man | 1.16 | HEJ-14 | 05:55 | 06:01 river_street, 06:58 hejie_square, 07:46 home, 08:31 HEJ-05, 09:24 home, 11:54 river_street, 12:31 home, 14:32 river_street, 15:03 home, 15:28 home | 19:23 | 643 |
| 81 | hejie trader | 1.08 | HEJ-15 | 06:30 | 07:56 court_wait, 08:26 castle_door, 09:54 dechen, 11:43 MKT-12, 12:18 tailor, 13:12 stalls | 14:41 | 1316 |
| 82 | hejie trader | 1.02 | HEJ-29 | 05:38 | 06:11 hejie_square, 06:53 HEJ-14, 07:51 home, 09:15 HEJ-14, 10:05 HEJ-08, 10:29 river_street, 10:58 home, 13:45 hejie_square, 14:31 HEJ-14, 15:08 home, 18:22 water_gate_in, 18:50 home, 20:18 HEJ-14 | 21:18 | 1386 |
| 83 | post soldier b | 1.17 | HEJ-05 | 09:21 | 11:12 MKT-06, 11:30 basin, 11:41 tsongra, 12:41 stalls, 14:05 river_street | 14:46 | 1349 |
| 84 | townswoman | 1.12 | HEJ-05 | 06:43 | 06:51 water_gate_in, 07:36 river_street, 08:04 water_gate_in, 08:54 HEJ-08, 09:37 water_gate_in, 10:15 river_street, 10:55 home, 11:40 home, 12:36 water_gate_in, 13:16 river_street, 14:02 hejie_square, 15:01 water_gate_in, 15:44 river_street, 16:34 HEJ-08, 17:12 home | 17:38 | 1718 |
| 85 | girl | 1.22 | HEJ-05 | 07:14 | 07:31 river_street, 08:18 east_gate_in, 09:15 home, 11:42 hejie_square, 12:27 home, 14:16 hejie_square, 14:43 river_street, 15:27 water_gate_in, 16:01 river_street, 16:37 water_gate_in, 17:07 river_street, 17:43 water_gate_in | 18:20 | 1857 |
| 86 | han man | 1.06 | HEJ-19 | 06:02 | 06:02 home, 08:25 hejie_square, 09:00 river_street, 09:59 home, 11:37 home, 12:29 home, 17:40 hejie_square | 18:27 | 953 |
| 87 | drover b | 0.91 | stair_top | 07:33 | 08:22 stalls, 08:51 tsongra, 09:56 stalls, 10:12 MKT-04, 10:35 stalls, 10:55 MKT-06, 12:18 mani | 14:38 | 1171 |
| 88 | townsman | 1.13 | H-SHL-105 | 06:27 | 07:33 dechen, 10:21 home, 11:55 talkers, 12:28 a neighbour's, 14:37 a neighbour's, 16:25 talkers, 17:51 home, 19:49 talkers | 21:35 | 3027 |
| 89 | townsman | 1.18 | H-SHL-003 | 06:42 | 07:18 dechen, 08:59 tsongra, 09:41 dechen, 10:56 tsongra_lower, 11:43 tsongra, 12:50 a neighbour's, 14:24 dechen, 16:15 a neighbour's | 19:03 | 1973 |
| 90 | townsman | 1.15 | H-SHL-010 | 06:34 | 07:09 dechen, 08:29 home, 10:27 river_street, 12:20 MKT-10, 12:35 tsongra, 13:26 talkers, 14:42 mani, 16:25 tsongra, 17:30 home, 18:25 mani, 19:38 home, 20:01 talkers, 20:29 dechen | 23:08 | 3469 |
| 91 | porter | 1.14 | H-SHL-110 | 06:30 | 07:34 saddler, 08:03 MKT-11, 08:23 MKT-08, 08:47 saddler, 09:42 dechen, 13:17 home, 15:44 talkers | 17:49 | 2045 |
| 92 | townsman b | 1.00 | H-SHL-069 | 06:01 | 07:21 MKT-07, 07:39 talkers, 08:02 tailor, 08:32 talkers, 09:17 saddler, 09:56 tsongra_lower, 10:30 talkers, 10:50 MKT-03, 11:27 turner, 13:17 home, 15:29 tsongra, 16:28 dechen | 19:19 | 2340 |
| 93 | house man | 1.04 | H-SHL-031 | 07:10 | 07:25 tsongra_lower, 08:02 tsongra, 08:58 dechen, 12:12 a neighbour's, 14:34 home, 16:02 lhakhang, 17:16 mani, 18:42 home, 18:52 chang | 19:21 | 2290 |
| 94 | house man | 0.91 | H-SHL-089 | 06:20 | 08:30 river_street, 10:49 talkers, 12:49 home, 15:21 dechen, 18:49 home, 19:11 mani | 20:06 | 2595 |
| 95 | townsman | 1.14 | H-SHL-006 | 06:32 | 07:03 dechen, 08:18 home, 09:29 MKT-12, 10:19 dechen, 12:01 a neighbour's, 13:52 lhakhang, 14:13 talkers, 14:54 a neighbour's, 16:11 dechen, 18:37 home, 19:13 mani, 20:27 home, 20:47 talkers | 21:26 | 2277 |
| 96 | townsman | 1.03 | tsongra | 05:54 | 06:05 saddler, 06:47 headman, 07:47 saddler, 08:38 home, 09:46 lhakhang, 10:13 stalls, 10:46 saddler, 11:26 tailor, 12:26 dechen, 13:28 home, 14:00 tailor, 15:13 chang | 16:28 | 1203 |
| 97 | stall man | 1.18 | H-SHL-024 | 06:51 | 08:24 a neighbour's, 10:51 talkers, 11:32 tsongra, 12:35 talkers, 13:36 a neighbour's, 15:58 mani, 17:20 home, 19:08 chang, 20:05 talkers | 21:05 | 2225 |
| 98 | townsman b | 1.16 | H-SHL-071 | 07:06 | 08:04 tsongra_lower, 09:38 river_street, 11:18 dechen, 12:51 tsongra, 13:31 talkers, 13:59 tsongra, 15:26 mani, 16:37 dechen, 19:51 home, 20:14 mani | 21:06 | 2823 |
| 99 | porter | 0.91 | H-SHL-035 | 07:10 | 07:55 dechen, 09:56 headman, 11:32 tsongra_lower, 12:29 a neighbour's, 13:44 talkers, 14:27 dechen, 16:02 talkers | 17:04 | 1193 |
| 100 | stall man | 1.13 | stair_top | 09:13 | 10:13 court_wait, 10:47 castle_door, 12:15 stalls, 12:52 turner, 13:53 stalls | 15:18 | 1084 |
| 101 | stall man | 0.96 | stair_top | 08:23 | 09:33 court_wait, 09:52 castle_door, 11:24 turner, 12:42 mani | 14:56 | 1376 |
| 102 | house man | 0.96 | H-SAM-02 | 06:10 | 06:10 home, 07:02 castle_gate, 07:21 home, 08:39 castle_lane, 09:41 east_gate_out, 10:52 ramp_head, 11:04 castle_lane, 11:36 home, 12:48 home, 13:18 castle_lane, 13:43 samkha_ward, 14:51 ula_yard, 16:02 castle_gate, 16:33 home, 17:54 castle_gate, 18:54 east_gate_out | 20:01 | 1453 |
| 103 | porter | 1.11 | castle_door | 08:49 | 09:46 river_street, 11:38 tsongra, 12:40 basin | 13:13 | 1201 |
| 104 | porter | 1.07 | stair_top | 08:28 | 09:08 tsongra, 09:41 basin, 11:08 river_street, 13:05 turner | 14:43 | 1698 |
| 105 | house man | 1.10 | west_way | 08:43 | 10:30 tsongra, 11:41 stalls, 12:26 turner | 14:21 | 1009 |
| 106 | porter | 0.92 | west_way | 07:09 | 09:16 basin, 10:56 river_street | 12:05 | 1196 |
| 107 | townsman b | 1.18 | yak_gate | 09:25 | 10:20 river_street, 12:12 tsongra_lower, 12:52 tsongra, 13:53 tsongra_lower | 14:33 | 1166 |
| 108 | stall man | 1.04 | west_way | 08:11 | 10:07 MKT-06, 10:31 MKT-11, 10:56 tsongra, 11:43 chang, 12:36 basin | 14:19 | 1244 |
| 109 | house man | 1.15 | yak_gate | 09:10 | 09:24 tailor, 10:02 MKT-01, 10:22 MKT-01, 10:44 stalls, 12:19 river_street, 14:17 stalls, 14:41 tsongra_lower | 15:16 | 1378 |
| 110 | townsman b | 1.18 | yak_gate | 09:23 | 10:19 mani, 11:19 MKT-05, 12:47 a neighbour's, 14:18 stalls | 15:00 | 1374 |
| 111 | townsman | 0.93 | yak_gate | 07:16 | 07:37 MKT-01, 08:04 tailor, 09:06 a neighbour's, 10:30 lhakhang | 11:14 | 649 |
| 112 | townsman b | 1.17 | west_way | 09:22 | 11:00 stalls, 11:25 saddler, 11:53 a neighbour's, 13:16 stalls | 14:55 | 1052 |
| 113 | porter | 1.11 | stair_top | 08:49 | 09:30 MKT-14, 09:58 dechen, 11:00 tsongra_lower, 12:11 a neighbour's | 14:38 | 977 |
| 114 | house man | 1.12 | west_way | 08:53 | 10:06 a neighbour's, 12:52 stalls, 13:25 dechen | 15:48 | 1166 |
| 115 | house man | 0.91 | west_way | 07:07 | 09:16 MKT-05, 09:46 stalls, 10:12 tsongra, 11:02 turner, 11:59 a neighbour's | 14:46 | 1120 |
| 116 | townsman b | 0.93 | yak_gate | 07:14 | 08:26 mani, 09:40 tsongra, 10:53 stalls, 11:09 tsongra, 11:35 tsongra_lower, 12:54 a neighbour's | 15:00 | 983 |
| 117 | townsman b | 1.18 | west_way | 09:23 | 11:20 chang, 13:07 river_street | 13:51 | 1464 |
| 118 | townsman | 1.08 | yak_gate | 08:35 | 08:56 basin, 09:21 tailor, 09:52 MKT-03, 10:34 dechen, 12:31 stalls | 13:13 | 639 |
| 119 | house man | 1.07 | west_way | 08:26 | 10:16 MKT-05, 10:36 tsongra, 11:15 basin, 11:37 stalls | 13:32 | 984 |
| 120 | townswoman b | 1.10 | H-SHL-046 | 07:07 | 07:22 MKT-07, 12:00 home, 13:17 basin, 14:59 a neighbour's, 17:44 home, 18:39 mani | 19:47 | 1676 |
| 121 | porter woman | 1.04 | tsongra | 05:57 | 06:15 dechen, 07:44 stalls, 08:24 turner, 09:13 tailor, 10:01 saddler, 10:51 stalls, 11:22 headman, 12:56 dechen, 14:19 home, 15:11 turner, 16:03 stalls, 16:37 home | 17:31 | 1149 |
| 122 | water woman | 1.12 | H-SHL-002 | 06:20 | 06:35 MKT-06, 12:05 home, 13:27 tsongra, 14:42 lhakhang, 15:33 a neighbour's | 17:51 | 1105 |
| 123 | house mother | 0.95 | H-SHL-086 | 06:23 | 07:34 MKT-05, 13:22 home, 15:44 tsongra | 18:29 | 1426 |
| 124 | townswoman | 1.13 | H-SHL-116 | 06:21 | 08:52 spring, 11:34 home, 14:12 tsongra, 14:52 basin, 15:55 mani, 16:58 basin | 18:09 | 2720 |
| 125 | stall woman | 0.96 | H-SHL-004 | 06:55 | 08:10 mani, 10:13 tsongra, 11:15 MKT-04, 12:01 home, 14:24 mani, 15:40 basin, 16:26 a neighbour's, 18:34 home, 19:01 a neighbour's | 20:07 | 2000 |
| 126 | water woman | 1.19 | H-SHL-010 | 06:34 | 06:55 MKT-01, 11:52 tsongra, 12:21 basin, 13:52 a neighbour's, 16:44 lhakhang, 17:33 home, 18:22 mani | 19:33 | 1936 |
| 127 | water woman | 1.18 | H-SHL-086 | 06:41 | 07:38 MKT-02, 13:08 home, 15:16 basin, 15:33 stalls, 16:23 a neighbour's | 18:19 | 1665 |
| 128 | stall woman | 0.96 | H-SHL-044 | 07:08 | 07:24 MKT-04, 11:52 tsongra, 13:13 mani, 14:38 a neighbour's, 15:48 a neighbour's, 17:03 mani | 18:14 | 945 |
| 129 | townswoman b | 0.94 | H-SHL-083 | 05:44 | 07:13 basin, 09:22 home, 10:36 mani, 12:54 home, 15:42 lhakhang, 17:01 mani, 18:28 home, 19:01 a neighbour's, 20:03 a neighbour's | 21:24 | 2912 |
| 130 | townswoman b | 0.94 | H-SHL-106 | 05:43 | 08:35 spring, 11:43 home, 13:53 a neighbour's, 16:07 mani, 18:54 home, 19:45 talkers | 21:14 | 3071 |
| 131 | porter woman | 0.92 | H-SHL-144 | 07:05 | 08:18 basin, 08:33 MKT-01, 08:53 MKT-12, 09:14 MKT-13, 09:35 stalls, 09:55 MKT-06, 10:11 tsongra_lower, 11:55 river_street, 14:48 a neighbour's, 17:00 mani, 19:31 home, 21:09 mani | 23:14 | 2960 |
| 132 | townswoman | 0.91 | H-SHL-028 | 05:37 | 05:49 basin, 06:11 home, 06:56 tsongra, 07:33 tsongra_lower, 07:54 MKT-10, 08:15 tsongra, 09:43 lhakhang, 10:21 a neighbour's, 11:12 MKT-11, 11:41 home, 13:15 lhakhang, 13:41 tsongra, 15:46 mani, 17:14 home, 18:47 mani, 20:40 home, 20:53 tsongra, 21:39 talkers | 22:27 | 2059 |
| 133 | porter woman | 0.98 | stair_top | 07:39 | 08:24 stalls, 08:49 MKT-13, 09:08 MKT-12, 09:37 MKT-03, 09:57 basin, 10:07 tsongra, 10:51 MKT-14, 12:22 a neighbour's | 15:04 | 1138 |
| 134 | porter woman | 1.16 | stair_top | 09:16 | 09:56 MKT-10, 10:26 MKT-05, 10:50 tsongra_lower, 11:31 MKT-14, 11:49 stalls, 12:30 chang, 13:18 tsongra_lower | 14:51 | 854 |
| 135 | stall woman | 1.01 | stair_top | 06:05 | 07:12 court_wait, 07:35 castle_door, 08:59 a neighbour's, 10:14 a neighbour's, 11:42 tsongra | 13:12 | 1218 |
| 136 | water woman c | 0.94 | H-SAM-04 | 06:07 | 06:07 home, 06:47 castle_gate, 07:22 castle_lane, 08:00 samkha_poor, 08:37 home, 09:53 samkha_ward, 10:45 home, 11:20 castle_lane, 11:37 home, 12:20 castle_lane, 12:37 home, 13:34 samkha_poor, 14:01 home, 15:12 castle_lane, 15:44 castle_gate, 16:13 home, 17:17 samkha_ward, 18:21 castle_lane | 18:53 | 691 |
| 137 | water woman | 0.95 | castle_door | 06:10 | 06:23 castle_lane, 06:45 samkha_poor, 07:07 castle_gate, 07:31 samkha_ward, 08:16 castle_lane, 08:46 samkha_ward, 09:30 castle_gate, 09:56 samkha_ward, 10:52 castle_lane, 11:35 castle_gate, 12:06 home, 13:21 castle_lane, 14:02 samkha_poor, 14:38 castle_gate, 15:05 samkha_ward, 16:03 castle_gate, 16:34 castle_lane, 17:17 samkha_ward, 17:55 castle_gate | 18:21 | 904 |
| 138 | porter woman | 1.04 | H-SAM-08 | 06:27 | 06:28 home, 07:05 samkha_ward, 07:46 home, 08:55 samkha_ward, 09:54 castle_gate, 10:14 samkha_ward, 10:47 home, 11:37 home, 12:57 castle_lane, 13:17 home, 17:48 samkha_ward | 18:41 | 636 |
| 139 | porter woman | 0.94 | H-SAM-03 | 06:07 | 06:08 home, 07:20 castle_lane, 07:41 samkha_poor, 08:16 home, 11:28 samkha_ward, 12:32 home, 13:15 castle_gate, 13:39 samkha_ward, 14:41 ula_yard, 15:35 home, 16:49 castle_lane, 17:24 home | 18:06 | 520 |
| 140 | stall woman | 1.05 | yak_gate | 08:20 | 08:53 turner, 09:37 dechen, 12:05 a neighbour's, 13:32 tsongra_lower, 14:06 saddler | 14:46 | 866 |
| 141 | water woman | 1.07 | yak_gate | 08:26 | 08:49 MKT-07, 09:23 dechen, 11:35 MKT-06, 13:03 river_street | 14:46 | 1502 |
| 142 | house mother | 0.97 | yak_gate | 07:37 | 08:01 MKT-02, 09:32 a neighbour's, 12:02 turner, 13:07 tailor | 13:53 | 944 |
| 143 | townswoman | 0.94 | stair_top | 06:50 | 07:37 MKT-14, 11:56 tailor, 12:33 dechen, 13:30 tsongra_lower | 15:01 | 831 |
| 144 | stall woman | 1.03 | west_way | 08:09 | 09:45 dechen, 11:06 MKT-07, 11:43 saddler, 12:22 tsongra_lower, 12:54 tsongra | 15:09 | 1293 |
| 145 | water woman c | 0.96 | stair_top | 07:28 | 08:15 MKT-13, 08:42 tsongra_lower, 09:04 tsongra, 11:07 river_street | 14:16 | 1645 |
| 146 | townswoman b | 0.91 | yak_gate | 07:02 | 07:22 MKT-10, 11:53 stalls | 12:34 | 241 |
| 147 | water woman d | 1.13 | yak_gate | 09:00 | 09:11 a neighbour's, 10:15 MKT-11, 11:04 a neighbour's, 12:50 tsongra | 13:43 | 620 |
| 148 | water woman | 1.01 | yak_gate | 07:55 | 08:36 chang, 09:41 MKT-10, 10:05 basin, 10:17 MKT-01, 11:21 a neighbour's | 13:36 | 877 |
| 149 | townswoman b | 1.08 | yak_gate | 07:23 | 07:40 MKT-08, 11:47 stalls, 12:19 basin, 12:45 turner, 13:56 lhakhang, 14:24 stalls | 15:06 | 639 |
| 150 | house mother | 1.09 | west_way | 08:39 | 10:10 dechen, 12:26 stalls | 14:08 | 1026 |
| 151 | stall woman | 0.97 | yak_gate | 07:33 | 07:55 tsongra, 08:52 lhakhang, 09:33 chang, 10:52 stalls, 11:33 lhakhang, 12:18 turner, 13:02 tsongra, 13:54 dechen | 15:11 | 1092 |
| 152 | water woman c | 0.98 | yak_gate | 07:39 | 08:02 tsongra, 09:10 dechen, 11:44 lhakhang, 12:28 turner, 13:26 tsongra | 14:17 | 932 |
| 153 | water woman b | 1.10 | yak_gate | 08:44 | 10:25 a neighbour's, 12:09 MKT-10, 12:42 dechen, 13:59 stalls | 14:23 | 1270 |
| 154 | townswoman b | 1.03 | yak_gate | 07:22 | 07:40 MKT-13, 11:53 tsongra, 12:33 basin, 12:51 stalls | 13:30 | 273 |
| 155 | water woman d | 0.98 | yak_gate | 07:09 | 07:27 MKT-12, 11:59 tailor, 12:34 dechen | 14:26 | 309 |
| 156 | townswoman b | 1.03 | west_way | 08:09 | 10:23 chang, 11:40 stalls, 12:51 mani | 14:42 | 1385 |
| 157 | water woman c | 1.18 | stair_top | 09:25 | 10:02 MKT-05, 10:21 tsongra, 11:35 MKT-06, 12:11 chang, 13:04 tsongra_lower, 13:24 tsongra | 15:24 | 771 |
| 158 | water woman | 1.20 | yak_gate | 09:34 | 09:48 MKT-08, 10:08 MKT-14, 10:25 MKT-07, 10:47 basin, 12:11 river_street, 13:58 basin | 14:23 | 1420 |
| 159 | house mother | 1.19 | west_way | 09:29 | 11:09 MKT-03, 11:28 tsongra_lower, 12:11 tsongra, 13:08 turner | 14:56 | 1055 |
| 160 | townswoman b | 1.09 | stair_top | 06:49 | 07:31 MKT-11, 11:50 tsongra_lower, 12:53 lhakhang | 13:37 | 589 |
| 161 | elder man, old | 0.73 | stair_top | 08:40 | 09:42 tsongra_lower, 10:11 stalls, 10:38 MKT-02, 11:05 tsongra, 12:07 tsongra_lower | 13:56 | 648 |
| 162 | lookout woman, old | 0.69 | west_way | 24:00 |  | 00:00 | 0 |
| 163 | elder man, old | 0.66 | stair_top | 07:44 | 08:51 MKT-02, 09:43 dechen, 11:19 stalls | 13:23 | 789 |
| 164 | elder man, old | 0.63 | yak_gate | 07:25 | 09:09 river_street, 11:56 dechen, 13:08 stalls | 13:54 | 1095 |
| 165 | elder man, old | 0.63 | west_way | 07:19 | 10:59 lhakhang, 11:35 tsongra | 14:36 | 1134 |
| 166 | boy | 1.03 | H-SHL-042 | 06:41 | 07:52 stair_top, 08:47 tsongra, 09:35 talkers, 09:55 tsongra, 10:31 talkers, 10:55 stalls, 11:26 home, 12:31 talkers, 13:06 tsongra, 13:51 talkers, 15:01 stair_top, 15:40 lhakhang, 16:05 basin, 16:30 home, 19:06 talkers, 19:53 dechen | 22:30 | 1709 |
| 167 | boy | 1.08 | H-SHL-102 | 06:52 | 07:22 stalls, 07:41 tsongra, 08:40 talkers, 09:04 basin, 09:23 talkers, 09:50 tsongra, 10:27 talkers, 10:46 stalls, 11:07 tsongra, 12:29 lhakhang, 12:52 tsongra, 14:52 stair_top, 16:00 talkers | 17:17 | 1191 |
| 168 | boy | 1.10 | H-SHL-079 | 06:55 | 07:53 talkers, 08:19 tsongra, 09:16 talkers, 10:37 mani, 12:12 home, 14:24 talkers, 14:43 basin, 14:59 talkers, 16:20 stair_top, 18:30 home, 18:53 mani | 20:05 | 2208 |
| 169 | boy | 1.23 | H-SHL-054 | 07:21 | 08:09 tsongra, 09:15 talkers, 10:28 stair_top, 11:13 tsongra, 12:43 home, 15:15 lhakhang, 15:35 tsongra | 17:25 | 1994 |
| 170 | boy | 1.23 | H-SHL-059 | 07:21 | 08:19 tsongra, 09:37 mani, 11:14 talkers, 13:05 home, 15:07 talkers, 16:20 stair_top, 17:57 mani | 19:11 | 2513 |
| 171 | boy | 1.07 | H-SHL-082 | 06:49 | 07:54 tsongra, 08:53 basin, 09:10 talkers, 09:29 tsongra, 10:33 talkers, 10:57 tsongra, 13:22 home, 15:52 talkers | 17:49 | 1570 |
| 172 | boy | 1.27 | stair_top | 09:20 | 10:09 dechen, 11:31 MKT-06, 11:44 basin, 12:06 tailor, 12:54 chang, 13:52 basin | 14:48 | 1147 |
| 173 | boy | 1.13 | castle_door | 07:26 | 07:44 ula_yard, 08:48 samkha_ward, 09:34 castle_lane, 10:05 samkha_ward, 10:37 ramp_head, 10:57 ula_yard, 11:49 castle_lane, 12:24 ramp_head, 12:39 castle_lane, 13:06 ula_yard, 13:46 castle_lane, 14:09 ula_yard, 15:00 castle_lane, 15:29 samkha_ward, 16:23 castle_lane, 16:55 ula_yard | 18:05 | 1265 |
| 174 | boy | 1.01 | west_way | 07:04 | 09:19 chang, 10:01 MKT-11, 10:23 tsongra, 11:57 chang, 12:53 basin | 14:43 | 1466 |
| 175 | boy | 1.01 | stair_top | 07:07 | 08:08 turner, 09:26 lhakhang, 09:53 MKT-10, 10:31 lhakhang, 10:57 MKT-05, 11:21 basin, 11:57 chang, 12:42 stalls, 13:03 tsongra_lower, 13:29 tailor | 15:26 | 1510 |
| 176 | boy | 1.08 | yak_gate | 07:43 | 08:03 tsongra, 08:33 tailor, 09:14 MKT-10, 09:45 saddler, 10:34 tsongra_lower, 10:53 MKT-12, 11:21 MKT-06, 11:47 tsongra, 12:20 tsongra_lower, 12:53 basin, 13:18 dechen, 14:06 tailor | 14:33 | 882 |
| 177 | boy | 1.12 | yak_gate | 08:03 | 08:22 tsongra, 09:34 MKT-13, 09:59 MKT-01, 11:05 mani, 12:30 tsongra, 13:18 tsongra_lower, 14:09 chang | 15:13 | 907 |
| 178 | boy | 1.16 | stair_top | 08:23 | 08:58 tsongra, 09:39 stalls, 10:37 mani | 12:48 | 979 |
| 179 | boy | 1.01 | west_way | 07:05 | 09:00 stalls, 09:27 dechen, 11:47 a neighbour's | 14:28 | 1585 |
| 180 | boy | 1.08 | stair_top | 07:43 | 08:23 tsongra, 09:36 tailor, 11:48 a neighbour's, 14:05 tsongra_lower, 14:27 stalls | 15:36 | 1464 |
| 181 | water girl b | 1.05 | H-SHL-145 | 06:39 | 07:39 stalls, 07:57 tsongra, 08:33 talkers, 08:58 basin, 09:10 tsongra, 10:02 talkers, 10:25 stalls, 10:45 tsongra, 12:22 home, 14:38 talkers, 15:13 lhakhang, 15:40 tsongra, 16:04 talkers | 17:22 | 1522 |
| 182 | water girl b | 1.17 | H-SHL-082 | 06:57 | 07:56 tsongra, 09:27 mani, 10:29 tsongra, 12:54 home, 15:13 talkers, 15:44 tsongra, 17:39 home, 18:05 mani | 19:00 | 2322 |
| 183 | water girl | 1.07 | H-SHL-054 | 06:37 | 07:35 basin, 08:52 home, 10:41 stalls, 11:14 basin, 12:32 home, 14:29 tsongra, 15:31 talkers, 16:02 tsongra, 17:38 home, 17:55 mani | 19:04 | 2163 |
| 184 | water girl b | 1.11 | H-SHL-067 | 06:45 | 07:46 basin, 09:09 home, 11:04 tsongra, 11:51 talkers, 12:19 tsongra, 12:59 basin, 13:12 tsongra, 14:20 talkers, 14:39 tsongra, 15:42 lhakhang, 16:06 tsongra | 17:49 | 1701 |
| 185 | water girl | 1.02 | H-SHL-090 | 06:46 | 07:21 talkers, 07:43 tsongra, 08:15 basin, 08:25 tsongra, 09:27 stalls, 09:54 tsongra, 10:34 basin, 10:45 talkers, 11:10 tsongra, 13:07 home, 14:22 lhakhang, 14:45 tsongra, 15:19 basin, 15:33 talkers, 16:16 lhakhang | 16:49 | 928 |
| 186 | water girl b | 1.21 | castle_door | 07:42 | 07:52 castle_lane, 08:21 ula_yard, 09:13 ramp_head, 09:28 castle_lane, 10:18 ramp_landing1, 10:48 castle_lane, 11:15 ramp_head, 11:32 ula_yard, 12:44 home, 13:56 samkha_ward, 14:49 ramp_landing1, 15:22 castle_lane, 15:54 ula_yard, 16:54 ramp_head, 17:07 castle_lane, 17:48 samkha_ward | 18:26 | 1349 |
| 187 | water girl b | 1.09 | stair_top | 07:47 | 08:28 MKT-02, 08:48 tsongra_lower, 09:10 MKT-13, 09:31 basin, 09:44 MKT-02, 10:04 tsongra_lower, 10:50 MKT-01, 11:29 chang | 13:08 | 901 |
| 188 | water girl b | 1.25 | stair_top | 09:08 | 10:22 mani, 11:38 stalls, 12:02 tsongra_lower, 13:06 mani | 15:08 | 1426 |
| 189 | water girl b | 1.24 | stair_top | 09:04 | 09:40 MKT-13, 09:57 tsongra_lower, 10:45 tailor, 11:25 MKT-03, 11:57 dechen, 12:57 tailor | 14:27 | 986 |
| 190 | water girl | 1.00 | yak_gate | 07:02 | 07:21 tsongra_lower, 07:58 tsongra, 08:57 basin, 09:21 saddler, 10:08 dechen, 11:26 stalls, 12:37 a neighbour's | 14:19 | 1053 |
| 191 | water girl b | 1.05 | yak_gate | 07:25 | 07:47 MKT-05, 08:10 MKT-10, 09:06 a neighbour's, 09:53 lhakhang, 10:37 turner, 11:35 MKT-05, 12:08 saddler, 13:06 tsongra | 14:08 | 1033 |
| 192 | water girl b | 1.28 | yak_gate | 09:25 | 09:27 dechen, 11:32 saddler, 12:37 mani, 13:32 basin, 13:57 dechen | 15:15 | 773 |
| 193 | monk | 0.91 | stair_top | 08:27 | 10:31 a neighbour's, 13:39 lhakhang | 14:32 | 1163 |
| 194 | monk | 1.11 | stair_top | 09:10 | 09:38 lhakhang, 10:11 a neighbour's, 13:23 mani | 15:40 | 1035 |
| 195 | monk | 1.02 | stair_top | 08:50 | 10:21 mani, 12:17 a neighbour's | 15:45 | 1090 |
| 196 | monk, old | 0.77 | stair_top | 09:20 | 10:27 a neighbour's | 13:54 | 599 |
| 197 | monk | 1.10 | stair_top | 09:07 | 11:01 a neighbour's, 14:03 tsongra | 15:57 | 1253 |
| 198 | pema monk | 0.96 | pema_o | 08:36 | 10:04 mani, 11:30 a neighbour's | 14:59 | 1210 |
| 199 | pieman | 1.06 | HEJ-13 | 05:55 | 06:05 HEJ-10, 06:24 water_gate_in, 07:28 east_gate_in, 08:19 water_gate_in, 08:56 river_street, 09:59 east_gate_in, 10:51 HEJ-10, 11:28 water_gate_in, 11:53 home, 12:40 HEJ-10, 13:04 water_gate_in, 14:00 east_gate_in, 14:48 water_gate_in, 16:01 east_gate_in, 16:54 water_gate_in, 17:12 home, 18:08 river_street, 19:24 HEJ-14 | 21:51 | 2804 |
| 200 | pieman | 1.15 | HEJ-13 | 06:05 | 06:09 water_gate_in, 06:35 HEJ-10, 07:14 HEJ-14, 08:16 HEJ-10, 08:44 river_street, 09:33 water_gate_in, 10:20 river_street, 10:50 HEJ-10, 11:21 water_gate_in, 11:58 HEJ-14, 12:49 river_street, 13:24 home, 14:34 HEJ-14, 15:15 river_street, 16:16 east_gate_in, 16:57 HEJ-10, 17:32 water_gate_in, 18:23 east_gate_in | 19:12 | 2330 |
| 201 | pieman | 0.97 | HEJ-13 | 07:35 | 09:42 MKT-08, 10:30 lhakhang, 11:15 dechen | 14:24 | 1586 |
| 202 | pieman | 0.91 | HEJ-06 | 05:36 | 05:56 HEJ-10, 07:06 east_gate_in, 08:13 home, 09:37 HEJ-13, 10:49 east_gate_in, 11:50 home, 13:42 east_gate_in, 14:33 HEJ-10, 15:12 water_gate_in, 15:52 HEJ-14, 16:46 water_gate_in, 17:53 east_gate_in | 18:55 | 2647 |
| 203 | townswoman b | 1.18 | H-HEJ-04 | 06:56 | 07:22 water_gate_in, 08:15 home, 09:27 river_street, 10:02 home, 11:41 river_street, 12:23 home, 13:35 river_street, 14:19 home, 15:40 HEJ-08, 16:04 home, 17:17 HEJ-08 | 17:56 | 1296 |
| 204 | townswoman | 1.11 | H-HEJ-17 | 08:49 | 10:44 turner, 11:38 tsongra_lower, 12:01 tsongra, 13:50 river_street | 14:14 | 1323 |
| 205 | townswoman b | 1.13 | H-HEJ-16 | 06:46 | 06:47 home, 08:01 water_gate_in, 08:42 river_street, 09:21 water_gate_in, 09:54 river_street, 10:39 home, 11:40 home, 12:38 river_street, 13:13 home, 14:31 river_street, 15:11 HEJ-08, 15:47 water_gate_in, 16:17 home | 18:26 | 919 |
| 206 | townswoman | 1.17 | HEJ-12 | 06:53 | 07:19 hejie_square, 08:17 water_gate_in, 08:50 river_street, 09:49 hejie_square, 10:33 river_street, 11:27 hejie_square, 11:56 home, 13:05 home, 14:12 river_street, 14:48 hejie_square, 15:39 home, 16:48 river_street, 17:31 water_gate_in | 18:04 | 1435 |
| 207 | townswoman b | 1.09 | H-HEJ-26 | 06:37 | 06:45 river_street, 07:47 hejie_square, 08:44 water_gate_in, 09:15 river_street, 10:12 water_gate_in, 11:03 HEJ-08, 11:43 home, 12:17 home, 13:46 water_gate_in, 14:20 home, 15:23 hejie_square, 15:57 river_street, 16:42 water_gate_in, 17:18 river_street | 18:01 | 1614 |
| 208 | townswoman b | 0.97 | H-HEJ-05 | 06:14 | 06:15 home, 07:10 hejie_square, 08:00 HEJ-08, 08:48 water_gate_in, 09:46 HEJ-08, 10:12 river_street, 11:07 hejie_square, 12:00 water_gate_in, 12:56 home, 13:59 river_street, 15:00 home, 17:51 water_gate_in, 19:24 HEJ-14 | 21:12 | 1640 |
| 209 | townswoman b | 0.91 | H-HEJ-20 | 06:01 | 06:02 home, 11:24 river_street, 11:59 home, 13:12 river_street, 14:03 water_gate_in, 14:34 river_street, 15:19 water_gate_in, 16:04 river_street, 16:38 water_gate_in, 17:10 river_street | 17:53 | 1081 |
| 210 | townswoman b | 0.99 | HEJ-17 | 07:44 | 09:37 chang, 10:55 stalls, 11:28 dechen | 13:49 | 1143 |
| 211 | girl | 1.10 | H-HEJ-34 | 06:50 | 07:09 river_street, 07:41 water_gate_in, 08:42 hejie_square, 09:16 river_street, 10:21 hejie_square, 11:16 river_street, 12:08 home, 14:02 hejie_square, 14:50 water_gate_in, 15:48 hejie_square, 16:48 home, 18:04 water_gate_in | 18:47 | 2131 |
| 212 | boy | 1.02 | H-HEJ-16 | 06:34 | 06:45 river_street, 07:40 water_gate_in, 08:23 river_street, 09:10 east_gate_in, 10:01 river_street, 10:53 water_gate_in, 11:38 river_street, 12:13 home, 13:38 water_gate_in, 14:38 east_gate_in, 15:38 water_gate_in, 16:39 hejie_square, 17:08 river_street, 18:03 water_gate_in | 18:38 | 1955 |
| 213 | boy | 1.13 | H-HEJ-19 | 06:56 | 07:29 hejie_square, 08:22 river_street, 09:17 hejie_square, 10:15 water_gate_in, 10:46 home, 11:38 home, 12:49 river_street, 13:26 water_gate_in, 14:32 hejie_square, 15:26 river_street, 16:04 home, 16:40 water_gate_in, 17:10 river_street | 17:56 | 1514 |
| 214 | boy | 1.05 | H-HEJ-01 | 06:39 | 06:48 hejie_square, 07:56 water_gate_in, 08:39 river_street, 09:38 east_gate_in, 10:38 water_gate_in, 11:36 hejie_square, 12:06 home, 13:17 river_street, 14:04 water_gate_in, 15:02 hejie_square, 15:45 home, 16:52 water_gate_in, 17:35 river_street | 18:36 | 2131 |
| 215 | boy | 1.19 | H-HEJ-36 | 07:08 | 07:45 east_gate_in, 08:44 home, 10:02 hejie_square, 10:48 home, 11:35 home, 13:12 hejie_square, 13:59 water_gate_in, 15:00 hejie_square, 15:37 river_street, 16:17 hejie_square, 16:51 river_street, 17:56 hejie_square | 18:54 | 2186 |
| 216 | boy | 1.26 | H-HEJ-17 | 07:21 | 07:48 hejie_square, 08:43 water_gate_in, 09:10 river_street, 10:17 east_gate_in, 10:53 river_street, 11:19 home, 12:22 home, 13:30 river_street, 14:31 hejie_square, 15:01 river_street, 15:48 east_gate_in, 16:33 home | 18:17 | 1497 |
| 217 | boy | 1.12 | H-HEJ-39 | 08:00 | 09:30 basin, 09:39 MKT-04, 10:09 dechen, 11:35 lhakhang, 12:09 chang, 13:42 mani | 15:31 | 1903 |
| 218 | boy | 1.18 | H-HEJ-32 | 07:06 | 07:06 home, 08:20 river_street, 09:00 water_gate_in, 09:31 river_street, 10:11 east_gate_in, 10:51 river_street, 11:56 east_gate_in, 12:39 river_street, 13:22 hejie_square, 14:12 river_street, 14:45 home, 15:38 hejie_square, 16:16 river_street, 17:12 east_gate_in, 17:59 water_gate_in | 18:39 | 1917 |
| 219 | girl | 1.28 | H-HEJ-08 | 09:24 | 10:45 basin, 12:02 river_street | 12:20 | 1114 |
| 220 | girl | 1.21 | H-HEJ-23 | 08:49 | 10:39 turner, 11:21 tailor, 12:14 stalls, 12:36 basin, 12:54 a neighbour's | 15:09 | 1473 |
| 221 | boy | 1.03 | H-HEJ-14 | 06:36 | 06:48 river_street, 07:53 east_gate_in, 08:23 hejie_square, 08:56 river_street, 09:49 hejie_square, 10:17 river_street, 11:16 hejie_square, 11:57 home, 13:06 river_street, 13:50 hejie_square, 14:32 river_street, 15:29 east_gate_in, 16:07 river_street, 16:41 water_gate_in, 17:13 home | 18:10 | 1592 |
| 222 | boy | 1.16 | H-HEJ-05 | 07:01 | 07:13 river_street, 07:45 water_gate_in, 08:31 hejie_square, 09:27 water_gate_in, 10:21 hejie_square, 10:46 river_street, 11:47 hejie_square, 12:10 home, 13:17 water_gate_in, 14:09 hejie_square, 15:04 water_gate_in, 15:33 river_street, 16:37 hejie_square, 17:20 east_gate_in, 18:05 water_gate_in | 19:06 | 2496 |
| 223 | boy | 1.16 | HEJ-30 | 07:01 | 07:39 east_gate_in, 08:27 home, 09:34 river_street, 10:25 hejie_square, 11:12 east_gate_in, 12:07 home, 13:14 water_gate_in, 13:59 hejie_square, 14:29 river_street, 15:05 water_gate_in, 15:55 hejie_square, 16:30 river_street, 17:08 water_gate_in, 18:00 hejie_square | 18:37 | 2376 |
| 224 | boy | 1.11 | H-HEJ-26 | 06:52 | 06:58 river_street, 07:41 home, 08:59 hejie_square, 09:47 river_street, 10:38 hejie_square, 11:28 river_street, 12:15 home, 13:07 river_street, 14:00 east_gate_in, 14:38 hejie_square, 15:07 river_street, 15:48 east_gate_in, 16:36 home, 17:52 river_street | 18:35 | 1325 |
| 225 | han man | 1.01 | HEJ-19 | 05:53 | 05:54 home, 06:47 river_street, 07:24 home, 08:25 water_gate_in, 08:54 home, 09:47 water_gate_in, 10:34 river_street, 11:37 hejie_square, 12:30 home, 13:16 home, 16:07 river_street, 17:08 home | 17:43 | 1096 |
| 226 | drover b | 1.02 | stair_top | 08:05 | 08:49 stalls, 10:08 mani, 11:17 tsongra, 12:26 dechen | 14:49 | 1273 |
| 227 | drover | 0.98 | stair_top | 07:54 | 08:42 stalls, 09:09 dechen, 10:31 tsongra, 11:20 lhakhang, 12:02 dechen | 14:40 | 1288 |
| 228 | elder man | 1.19 | tsongra | 07:25 | 08:08 mani, 10:35 stair_top, 11:22 lhakhang, 11:46 home, 12:28 lhakhang, 13:22 pema_o, 14:48 mani, 16:27 lhakhang | 16:49 | 2264 |
| 229 | poor grandmother | 1.05 | west_edge | 07:13 | 08:38 tsongra, 09:19 stalls, 09:53 basin, 10:25 dechen, 12:09 stalls, 12:56 dechen, 14:59 tsongra, 16:42 mani | 18:12 | 1517 |
| 230 | elder woman | 1.03 | west_edge | 07:09 | 08:33 tsongra, 09:34 stalls, 10:43 mani, 11:51 stalls, 12:33 dechen, 13:45 stalls, 14:20 dechen, 15:38 tsongra | 17:41 | 1722 |
| 231 | drover | 1.02 | dechen | 05:53 | 06:32 chang, 07:54 home, 09:15 chang, 10:35 saddler, 11:27 home, 13:17 tailor, 13:45 tsongra, 15:08 turner, 15:48 tsongra, 16:26 stalls, 16:52 saddler | 17:45 | 1499 |
| 232 | drover | 0.94 | dechen | 05:33 | 06:02 saddler, 06:56 tsongra, 07:41 home, 10:08 saddler, 11:16 home, 12:42 tsongra, 14:00 saddler, 14:30 stalls, 14:54 tsongra, 16:15 saddler, 16:57 tsongra | 17:37 | 1259 |
| 233 | drover | 1.03 | dechen | 05:55 | 06:16 tsongra, 07:38 turner, 08:26 tsongra, 09:14 chang, 10:25 tailor, 11:00 saddler, 12:00 home, 13:44 tsongra, 14:44 tailor, 15:47 saddler | 16:26 | 1212 |
| 234 | drover | 1.02 | yak_gate | 08:02 | 08:17 tailor, 08:57 dechen, 10:23 MKT-07, 10:44 MKT-12, 11:14 a neighbour's | 12:51 | 599 |
| 235 | drover b | 1.05 | west_way | 08:18 | 10:11 tsongra_lower, 11:09 dechen, 12:26 tsongra_lower | 14:32 | 1455 |
| 236 | drover | 1.13 | yak_gate | 08:57 | 09:57 river_street, 11:38 dechen, 13:42 mani | 15:15 | 1497 |
| 237 | drover b, old | 0.67 | dechen | 05:48 | 06:20 tsongra, 07:39 home, 10:05 lhakhang, 10:50 tailor, 11:20 tsongra, 12:59 lhakhang, 13:58 home, 15:01 tsongra, 16:02 saddler, 16:39 tailor | 17:32 | 1499 |
| 238 | drover | 1.00 | west_way | 07:52 | 09:45 tailor, 10:42 basin, 10:59 MKT-08, 11:27 dechen, 12:32 tsongra | 15:00 | 1398 |
| 239 | drover b | 0.94 | west_way | 07:19 | 09:29 turner, 10:03 MKT-11 | 11:57 | 1165 |
| 240 | drover | 1.15 | yak_gate | 09:11 | 09:27 tsongra_lower, 09:56 tailor, 10:23 MKT-10, 10:49 MKT-08, 11:29 a neighbour's, 13:12 lhakhang, 13:46 saddler | 14:31 | 801 |
| 241 | porter woman | 1.17 | tsongra | 06:28 | 06:34 stalls, 07:16 dechen, 09:21 home, 09:58 saddler, 10:38 dechen, 12:06 saddler, 12:34 stalls, 12:59 dechen, 14:10 stalls, 14:25 home, 15:09 turner, 16:13 tailor | 16:58 | 1197 |
| 242 | porter woman | 1.09 | dechen | 06:08 | 06:29 tsongra, 07:55 chang, 09:20 home, 10:13 tailor, 10:50 tsongra, 11:54 home, 12:43 stalls, 13:14 saddler, 14:20 home, 15:41 chang, 16:48 lhakhang, 17:23 chang | 18:37 | 1816 |
| 243 | nomad woman | 0.93 | tsongra | 05:30 | 05:35 stalls, 06:23 dechen, 08:20 stalls, 09:07 dechen, 09:58 stalls, 10:38 dechen, 11:54 stalls, 12:32 turner, 13:08 home, 13:57 dechen, 15:35 saddler, 16:55 chang | 17:55 | 1437 |
| 244 | porter woman | 0.96 | yak_gate | 07:33 | 07:53 stalls, 08:26 MKT-03, 09:33 mani, 11:11 MKT-13, 11:31 MKT-07, 11:55 tsongra, 13:14 dechen | 15:16 | 834 |
| 245 | water girl | 1.02 | stair_top | 07:37 | 08:21 stalls, 08:59 dechen, 09:55 stalls, 10:22 tsongra, 10:53 stalls, 11:35 dechen, 13:35 stalls | 15:01 | 1051 |

Out of doors (walking, standing, at the wheel or the wall), of 245: 04:30 2, 06:00 44, 07:00 99, 09:00 169, 11:00 192, 13:00 137, 15:00 133, 16:00 121, 17:00 105, 19:00 52, 21:00 25, 00:00 0 (chapter 05, 8.1 has Shöl's 10, 70, 98, 112, 120, 104, 98, -, 102, 52, 24, 6 of about 120).

## The named eight and the twelve generic

_Their days from `data/named_days.json` (M1 sprint 6, step 3; chapter 05, 4.2) and `data/generic_days.json` (step 4): each stop's arrival, what they do there and on which seat; the least time any of them has to spare between leaving one place and being due at the next, at their own pace (TownSim leaves as late as it can: the spare is time to stand at the place first)._

| Who | Pace (m/s) | Home | The day | Least to spare |
|---|---|---|---|---|
| achak dolkar | 1.05 | dechen | 13:50 dechen (talk, room:dechen_tibetan:spot:1.1:1.5:20), 14:12 dechen (talk, room:dechen_chinese:spot:-1.3:2.2:0), 14:32 dechen (talk, room:dechen_tibetan:spot:1.1:1.5:20), 15:00 yak_gate (inside), 16:25 dechen (talk, dechen_gate), 17:00 dechen (talk, roof:-4.3:20.2:270), 17:26 dechen (stand, room:dechen_dolkar:spot:-1.15:3.2:0), 17:40 dechen (cross, room:dechen_tibetan:seat:1), 18:20 dechen (inside) | 0.9 min before dechen at 17:40 |
| yang shouren | 0.95 | dechen | 13:20 dechen (stand, dechen_gate), 13:42 dechen (sit, room:dechen_chinese:seat:3), 19:10 dechen (inside) | 0.9 min before dechen at 13:20 |
| sonam wangyal | 1.00 | headman | 06:42 headman (cross, room:headman_kitchen:seat:4), 07:30 castle_door (inside), 12:15 headman (cross, room:headman_kitchen:seat:4), 12:52 headman (inside), 15:25 castle_door (inside), 16:25 talkers (sit, talkers:2:-4), 18:00 headman (cross, room:headman_kitchen:seat:4), 20:10 headman (inside) | 0.7 min before castle_door at 15:25 |
| pasang carver | 0.72 | H-SHL-020 | 06:10 mani (mani, spot), 08:00 pitch (sit, pitch), 16:25 mani (mani, spot), 18:45 H-SHL-020 (inside) | 3.0 min before mani at 16:25 |
| kalsang drolma | 1.05 | H-SHL-078 | 05:30 spring (stand, spot), 06:45 H-SHL-078 (inside), 08:05 stalls (talk, stall:0), 13:20 H-SHL-078 (stand, door), 15:30 spring (stand, spot), 16:45 H-SHL-078 (inside) | 16.5 min before stalls at 08:05 |
| tsomo nomad | 1.00 | stair_top | 08:30 stalls (talk, stall:2:2.2), 13:10 stair_top (inside) | 13.4 min before stalls at 08:30 |
| ngodrup dedpon | 1.15 | yak_gate | 10:20 dechen (inside), 11:45 yak_gate (inside), 13:35 dechen (cross, room:dechen_tibetan:seat:2), 16:30 yak_gate (inside), 21:06 dechen (cross, dyard:1.5:10.6:248), 21:58 dechen (inside), 23:15 yak_gate (inside) | 6.0 min before dechen at 21:58 |
| nyima boy | 1.20 | H-SHL-044 | 06:15 tailor (stand, spot), 06:35 saddler (stand, spot), 06:55 turner (stand, spot), 07:20 H-SHL-044 (inside), 08:00 stalls (talk, stall:1:0.8), 10:10 yak_gate (inside), 11:05 talkers (crouch, talkers:9:5), 13:20 H-SHL-044 (inside), 14:45 pitch (crouch, pitch_helper), 16:00 tsongra (stand, spot), 17:25 H-SHL-044 (inside) | 0.8 min before stalls at 08:00 |
| stall man | 1.00 | H-SHL-012 | 07:35 stalls (talk, stall:2), 12:15 H-SHL-012 (inside), 13:35 stalls (talk, stall:2), 17:25 H-SHL-012 (inside) | 10.7 min before H-SHL-012 at 12:15 |
| stall woman | 1.00 | H-SHL-044 | 07:55 stalls (talk, stall:1:-0.6), 12:25 H-SHL-044 (inside), 13:45 stalls (talk, stall:1:-0.6), 17:20 H-SHL-044 (inside) | 9.0 min before stalls at 07:55 |
| porter | 0.95 | H-SHL-039 | 08:08 dechen (inside), 08:42 stalls (stand, stall:0:-1.4), 09:08 dechen (inside), 09:45 tsongra (stand, spot:-4:9), 10:13 dechen (inside), 10:33 H-SHL-039 (inside), 13:10 dechen (inside), 14:45 stair_top (inside), 16:05 dechen (inside), 16:37 stalls (stand, stall:0:-1.4), 16:55 H-SHL-039 (inside) | 1.6 min before dechen at 10:13 |
| porter woman | 0.90 | H-SHL-042 | 08:45 dechen (inside), 10:25 stair_top (inside), 11:48 dechen (inside), 12:12 H-SHL-042 (inside), 13:55 dechen (inside), 15:31 stair_top (inside), 16:27 tsongra (stand, spot:6:10:200), 16:57 dechen (inside), 17:18 H-SHL-042 (inside) | 0.9 min before dechen at 08:45 |
| elder man | 0.65 | H-SHL-002 | 05:45 mani (mani, spot), 08:02 H-SHL-002 (inside), 11:40 talkers (sit, talkers:3:-6.5), 13:02 H-SHL-002 (inside), 16:30 talkers (sit, talkers:2:-5.2), 17:32 H-SHL-002 (inside) | -4.1 min before H-SHL-002 at 13:02 |
| elder woman | 0.60 | H-SHL-052 | 05:53 mani (mani, spot), 08:00 H-SHL-052 (inside), 14:45 mani (mani, spot), 17:10 H-SHL-052 (inside) | 10.2 min before H-SHL-052 at 17:10 |
| boy | 1.25 | H-SHL-001 | 06:52 basin (stand, spot:-1.5:0.6:180), 07:15 H-SHL-001 (inside), 08:15 stalls (stand, stall:1:2.1), 10:10 yak_gate (inside), 11:05 talkers (crouch, talkers:9:4.1), 13:20 H-SHL-001 (inside), 14:32 tsongra (crouch, spot:-5:3:90), 16:02 basin (stand, spot:1.5:0.5:180), 16:30 tsongra_lower (stand, spot:0:1), 17:40 H-SHL-001 (inside) | -0.4 min before basin at 06:52 |
| girl | 1.15 | H-SHL-003 | 06:37 basin (stand, spot:0:0.6:180), 07:11 H-SHL-003 (inside), 08:37 tsongra (stand, spot:-3:10), 11:05 talkers (crouch, talkers:9:5.9), 13:23 H-SHL-003 (inside), 14:51 tsongra (crouch, spot:-3.8:3:270), 16:05 basin (stand, spot:2.5:0.8:180), 16:49 H-SHL-003 (inside) | -8.2 min before tsongra at 08:37 |
| drover | 1.10 | yak_gate |  | - |
| drover b | 1.10 | yak_gate |  | - |
| nomad woman | 1.00 | stair_top | 08:20 tsongra (talk, spot:-8:9:160), 13:22 stair_top (inside) | 20.4 min before tsongra at 08:20 |
| han man | 1.00 | yak_gate | 10:00 dechen (inside), 12:00 stalls (talk, stall:2:0:front), 12:38 tsongra (stand, spot:4:2), 13:40 dechen (sit, room:dechen_chinese:seat:4), 16:50 tsongra (stand, spot:6:3:300), 17:30 yak_gate (inside) | 3.5 min before tsongra at 16:50 |
| cook | 0.90 | dechen | 05:40 dechen (stand, room:dechen_kitchen:spot:-2.2:3.35:0), 21:15 dechen (inside) | 3.2 min before dechen at 05:40 |
| kitchen woman | 1.05 | dechen | 05:55 dechen (stand, room:dechen_kitchen:spot:-4.5:2.1:270), 13:30 dechen (stand, room:dechen_tibetan:spot:2.75:0.75:60), 16:58 dechen (stand, roof:-5.2:19.5:0), 17:30 dechen (stand, room:dechen_kitchen:spot:-4.5:2.1:270), 21:06 dechen (stand, dyard:2.4:11.5:235), 21:52 dechen (inside) | 4.1 min before dechen at 05:55 |
| house grandmother | 0.55 | H-SHL-007 | 05:50 H-SHL-007 (cross, room:house_kitchen_b2_in_v1:seat:2), 09:10 mani (mani, spot), 12:10 H-SHL-007 (cross, room:house_kitchen_b2_in_v1:seat:2), 20:45 H-SHL-007 (inside) | 0.9 min before H-SHL-007 at 05:50 |
| house mother | 1.00 | H-SHL-054 | 05:40 H-SHL-054 (cross, room:house_kitchen_b2_in_v2:seat:1), 09:05 stalls (stand, spot), 11:35 H-SHL-054 (cross, room:house_kitchen_b2_in_v2:seat:1), 21:05 H-SHL-054 (inside) | 4.1 min before H-SHL-054 at 05:40 |
| house man | 0.95 | H-SHL-004 | 06:00 H-SHL-004 (cross, room:house_kitchen_b2_in_v3:seat:1), 08:10 tsongra (stand, spot), 12:30 H-SHL-004 (cross, room:house_kitchen_b2_in_v3:seat:1), 21:15 H-SHL-004 (inside) | 4.8 min before H-SHL-004 at 06:00 |
| poor grandmother | 0.50 | H-SHL-142 | 05:00 H-SHL-142 (stand, room:house_room_e1_in_v2:spot:0.9:0.9:10), 17:40 west_mani (mani, spot), 20:42 H-SHL-142 (cross, room:house_room_e1_in_v2:spot:0.3:2.0:67), 22:00 H-SHL-142 (inside) | 1.9 min before west_mani at 17:40 |
| ama yudron | 0.80 | chang | 09:00 tsongra (stand, spot), 11:00 chang (stand, room:chang_room_b2_in_v2:spot:-2.6:4.2:324), 23:10 chang (inside) | 3.0 min before chang at 23:10 |
| yudron daughter | 1.00 | chang | 10:10 chang (stand, room:chang_room_b2_in_v2:spot:-2.9:1.7:218), 23:00 chang (inside) | 4.5 min before chang at 10:10 |
| jiang deshun | 1.05 | yak_gate | 16:30 chang (cross, room:chang_room_b2_in_v2:seat:5), 18:20 yak_gate (inside) | -0.1 min before yak_gate at 18:20 |
| post soldier | 1.10 | yak_gate | 17:05 chang (sit, room:chang_room_b2_in_v2:seat:12), 19:30 yak_gate (inside) | 1.5 min before yak_gate at 19:30 |
| post soldier b | 1.00 | yak_gate | 17:08 chang (sit, room:chang_room_b2_in_v2:seat:13), 19:30 yak_gate (inside) | 3.6 min before yak_gate at 19:30 |
| muleteer | 1.10 | yak_gate | 17:45 chang (cross, room:chang_room_b2_in_v2:seat:7), 22:00 yak_gate (inside) | 1.3 min before yak_gate at 22:00 |
| muleteer b | 1.00 | yak_gate | 17:50 chang (cross, room:chang_room_b2_in_v2:seat:17), 22:00 yak_gate (inside) | 8.5 min before yak_gate at 22:00 |
| drakpa bard | 0.75 | dechen | 10:00 talkers (sit, talkers:1:2.5), 12:40 dechen (inside), 19:30 chang (cross, room:chang_room_b2_in_v2:seat:9), 21:02 dechen (cross, dyard:0.0:11.5:180), 22:00 dechen (inside) | 1.0 min before dechen at 21:02 |
| novice | 1.20 | stair_top | 14:12 lhakhang (wheel, spot), 14:56 tsongra (crouch, spot:-3.6:1.8:230), 16:40 stair_top (inside) | 4.2 min before stair_top at 16:40 |
| novice b | 1.15 | stair_top | 14:30 dechen (stand, spot), 15:05 tsongra (crouch, spot:-6.4:2.0:80), 16:43 stair_top (inside) | 0.9 min before dechen at 14:30 |
| ngakpa man | 1.00 | H-SHL-128 | 07:50 pema_o (inside), 10:00 H-SHL-128 (inside), 11:30 tsongra (stand, spot:7:6), 13:20 H-SHL-128 (inside), 17:00 conch_terrace (stand, spot:4:-3:113), 18:00 H-SHL-128 (inside) | 12.8 min before conch_terrace at 17:00 |
| ngakpa man b | 0.85 | H-SHL-111 | 07:40 pema_o (inside), 10:05 H-SHL-111 (inside), 15:00 pema_o (stand, spot:3:-2:140), 16:40 H-SHL-111 (inside) | -27.4 min before H-SHL-111 at 10:05 |
| ngakpa woman | 0.95 | H-SHL-133 | 06:20 conch_terrace (stand, spot:-2:-1:113), 07:05 H-SHL-133 (inside), 10:50 tsongra (stand, spot:-2:7), 12:50 H-SHL-133 (inside), 15:30 pema_o (stand, spot:-3:-2), 16:30 H-SHL-133 (inside) | 14.3 min before H-SHL-133 at 07:05 |
| ngakpa woman b | 0.90 | H-SHL-116 | 06:40 conch_terrace (stand, spot:-4:-2:113), 07:35 H-SHL-116 (inside), 11:50 tsongra (stand, spot:-6:8), 14:00 H-SHL-116 (inside) | -33.0 min before H-SHL-116 at 07:35 |
| norbu | 1.00 | H-SHL-142 | 07:30 west_way (inside), 18:00 H-SHL-142 (inside) | -8.0 min before H-SHL-142 at 18:00 |
| dawa | 0.95 | H-SHL-142 | 06:37 west_way (inside), 07:55 H-SHL-142 (inside), 08:55 west_way (inside), 17:25 H-SHL-142 (inside) | -6.0 min before H-SHL-142 at 07:55 |
| norbu girl | 1.10 | H-SHL-142 | 07:46 west_way (inside), 17:16 H-SHL-142 (inside) | -6.7 min before H-SHL-142 at 17:16 |
| norbu boy | 1.20 | H-SHL-142 | 10:00 west_edge (crouch, spot:2:-1:200), 12:28 H-SHL-142 (inside), 15:00 west_mani (stand, spot:1:-1), 16:30 H-SHL-142 (inside) | 1.2 min before H-SHL-142 at 12:28 |
| water woman | 1.00 | H-SHL-108 | 05:40 spring (stand, spot), 06:14 H-SHL-108 (inside), 06:40 spring (stand, spot), 07:11 H-SHL-108 (inside), 15:30 spring (stand, spot), 16:04 H-SHL-108 (inside) | 2.5 min before H-SHL-108 at 06:14 |
| water woman b | 0.95 | H-SHL-056 | 05:40 spring (stand, spot), 06:31 H-SHL-056 (inside), 07:10 spring (stand, spot), 07:54 H-SHL-056 (inside), 15:35 spring (stand, spot), 16:24 H-SHL-056 (inside) | 2.6 min before spring at 05:40 |
| water woman c | 0.80 | H-SHL-081 | 05:57 spring (stand, spot), 06:43 H-SHL-081 (inside), 07:16 spring (stand, spot), 07:53 H-SHL-081 (inside), 15:40 spring (stand, spot), 16:28 H-SHL-081 (inside) | 1.1 min before H-SHL-081 at 06:43 |
| water woman d | 1.05 | H-SHL-072 | 05:41 spring (stand, spot), 06:20 H-SHL-072 (inside), 06:46 spring (stand, spot), 07:18 H-SHL-072 (inside), 15:46 spring (stand, spot), 16:24 H-SHL-072 (inside) | 1.4 min before H-SHL-072 at 06:20 |
| water girl | 1.10 | H-SHL-076 | 05:41 spring (stand, spot), 06:24 H-SHL-076 (inside), 06:54 spring (stand, spot), 07:28 H-SHL-076 (inside), 15:50 spring (stand, spot), 16:33 H-SHL-076 (inside) | 1.4 min before H-SHL-076 at 06:24 |
| water girl b | 1.15 | H-SHL-109 | 05:42 spring (stand, spot), 06:38 H-SHL-109 (inside), 15:32 spring (stand, spot), 16:20 H-SHL-109 (inside) | 3.5 min before spring at 05:42 |
| lookout woman | 0.60 | H-SHL-095 | 16:52 lookout (stand, spot:5.3:5.0:34), 18:34 H-SHL-095 (inside) | 5.4 min before lookout at 16:52 |
| yangchen drolma | 0.95 | headman | 05:30 headman (stand, hroof:0.4:1.7:0), 06:22 headman (stand, room:headman_kitchen:spot:1.1:2.75:0), 06:50 headman (cross, room:headman_kitchen:seat:3), 08:00 tsongra (stand, spot:-8.0:-6.0:45), 12:15 headman (cross, room:headman_kitchen:seat:3), 12:52 headman (inside), 15:00 headman (cross, room:headman_reception:seat:1), 17:08 headman (stand, hroof:0.4:1.7:0), 18:00 headman (cross, room:headman_kitchen:seat:3), 20:10 headman (inside) | -2.6 min before headman at 05:30 |
| pema wife | 1.05 | headman | 05:50 headman (stand, room:headman_kitchen:spot:2.05:3.05:0), 06:50 headman (cross, room:headman_kitchen:spot:3.9:1.05:300), 07:35 headman (stand, room:headman_kitchen:spot:2.05:3.05:0), 12:15 headman (cross, room:headman_kitchen:spot:3.9:1.05:300), 12:52 headman (inside), 15:00 headman (cross, room:headman_roofroom:seat:1), 18:00 headman (cross, room:headman_kitchen:spot:3.9:1.05:300), 20:10 headman (inside) | -1.9 min before headman at 15:00 |
| younger son | 1.10 | headman | 06:50 headman (cross, room:headman_kitchen:seat:1), 07:50 headman (stand, hroof:-2.5:-1.0:90), 12:15 headman (cross, room:headman_kitchen:seat:1), 12:52 headman (inside), 17:10 headman (stand, hroof:1.3:2.2:270), 18:00 headman (cross, room:headman_kitchen:seat:1), 20:10 headman (inside) | 1.1 min before headman at 17:10 |
| headman grandmother | 0.60 | headman | 05:38 headman (stand, room:headman_shrine:spot:2.1:1.35:90), 06:50 headman (cross, room:headman_kitchen:seat:2), 09:00 mani (mani, spot), 12:15 headman (cross, room:headman_kitchen:seat:2), 12:55 headman (cross, room:headman_shrine:seat:2), 15:25 headman (inside), 18:00 headman (cross, room:headman_kitchen:seat:2), 20:10 headman (inside) | -9.7 min before headman at 05:38 |
| headman grandchild | 0.70 | headman | 06:50 headman (cross, room:headman_kitchen:spot:3.6:1.6:300), 08:00 headman (crouch, spot:-6.5:-2.0:250), 12:15 headman (cross, room:headman_kitchen:spot:3.6:1.6:300), 13:10 headman (crouch, spot:-5.6:-1.9:200), 18:00 headman (cross, room:headman_kitchen:spot:3.6:1.6:300), 19:50 headman (inside) | 2.3 min before headman at 06:50 |
| headman steward | 1.00 | headman | 05:05 headman (stand, room:headman_kitchen:spot:4.2:1.15:90), 08:00 tsongra (stand, spot:-7.0:-6.6:225), 12:15 headman (stand, room:headman_kitchen:spot:4.2:1.15:90), 18:00 headman (cross, room:headman_kitchen:spot:-0.8:1.75:90), 21:00 headman (inside) | -0.4 min before headman at 05:05 |
| headman groom | 1.05 | headman | 04:45 headman (stand, room:headman_stable:spot:4.2:1.85:180), 06:50 headman (cross, room:headman_kitchen:spot:-0.8:2.35:90), 07:35 headman (stand, spot:-2.4:0.6:250), 12:15 headman (cross, room:headman_kitchen:spot:-0.8:2.35:90), 12:52 headman (stand, room:headman_stable:spot:1.3:2.15:180), 18:00 headman (cross, room:headman_kitchen:spot:-0.8:2.35:90), 20:30 headman (stand, spot:-3.0:0.4:250), 21:00 headman (inside) | -0.4 min before headman at 20:30 |
| headman kitchen girl | 1.10 | headman | 04:45 headman (crouch, room:headman_kitchen:spot:-0.13:2.65:0), 05:35 headman (stand, room:headman_kitchen:spot:0.6:2.4:0), 10:30 headman (stand, room:headman_shrine:spot:1.4:1.25:42), 10:50 headman (stand, room:headman_kitchen:spot:0.6:2.4:0), 11:30 headman (stand, room:headman_shrine:spot:1.4:1.25:42), 12:15 headman (cross, room:headman_kitchen:spot:-0.2:1.15:60), 12:50 headman (stand, room:headman_kitchen:spot:0.6:2.4:0), 13:30 headman (stand, room:headman_shrine:spot:1.4:1.25:42), 13:48 headman (stand, room:headman_kitchen:spot:0.6:2.4:0), 14:30 headman (stand, room:headman_shrine:spot:1.4:1.25:42), 14:48 headman (stand, room:headman_kitchen:spot:0.6:2.4:0), 18:00 headman (cross, room:headman_kitchen:spot:-0.2:1.15:60), 21:00 headman (inside) | 0.2 min before headman at 04:45 |
| tashi phuntsok | 0.85 | stair_top | 09:58 headman (cross, room:headman_shrine:seat:1), 17:00 stair_top (inside) | 7.6 min before headman at 09:58 |
| hejie trader | 1.00 | yak_gate | 15:05 headman (sit, room:headman_reception:seat:7), 17:20 yak_gate (inside) | 12.6 min before yak_gate at 17:20 |
| dechen lama | 0.70 | dechen | 06:32 dechen (cross, room:dechen_chapel:seat:1), 09:52 dechen (inside), 17:36 dechen (cross, room:dechen_chapel:seat:1), 18:26 dechen (inside) | 1.2 min before dechen at 17:36 |
| dechen steward | 1.00 | dechen | 11:19 stair_top (inside), 12:48 dechen (inside), 21:02 dechen (cross, dyard:-1.5:10.6:112), 21:57 dechen (inside) | 1.5 min before stair_top at 11:19 |
| dechen servant | 1.00 | dechen | 11:20 stair_top (inside), 12:49 dechen (inside) | 1.5 min before stair_top at 11:20 |
| dechen servant b | 1.00 | dechen | 11:21 stair_top (inside), 12:50 dechen (inside), 21:04 dechen (cross, dyard:0.0:8.2:0), 21:55 dechen (inside) | 1.5 min before stair_top at 11:21 |
| tea sewer | 0.85 | dechen | 08:00 dechen (crouch, dyard:13.55:-8.9:300), 12:15 dechen (inside), 13:05 dechen (crouch, dyard:13.55:-8.9:300), 16:40 dechen (inside), 21:03 dechen (cross, dyard:1.3:8.8:313), 21:56 dechen (inside) | 1.7 min before dechen at 21:03 |
| tea sewer b | 0.95 | dechen | 08:05 dechen (crouch, dyard:12.7:-7.6:200), 12:15 dechen (inside), 13:10 dechen (crouch, dyard:12.7:-7.6:200), 16:40 dechen (inside), 21:03 dechen (cross, dyard:-1.3:8.8:47), 21:58 dechen (inside) | 2.3 min before dechen at 21:03 |
| pieman | 0.90 | yak_gate | 08:40 dechen (crouch, dyard:-11.6:-20.2:45), 15:30 yak_gate (inside) | 24.7 min before yak_gate at 15:30 |
| dice player | 1.00 | H-SHL-018 | 09:40 dechen (crouch, dyard:-10.6:-19.5:235), 13:00 H-SHL-018 (inside) | 1.6 min before dechen at 09:40 |
| dice player b | 1.00 | H-SHL-046 | 10:10 dechen (crouch, dyard:-10.9:-21.0:315), 14:30 H-SHL-046 (inside) | 0.2 min before dechen at 10:10 |

## Outdoors by the hour

_The walkers outdoors (standing at a place or walking between them, counted where they are going) against chapter 05, 8.1's Shöl, Hejie and Samkha columns (the simulated 300's, outdoors and visible; Shöl's 17:00 counts the roof sang's people on the roofs, which the walkers are not; Samkha's count the court's, the toll's and the ula yard's people, whom their scenes draw: world/samkha_people.gd, world/ula_yard.gd)._

| Hour | Shöl | Chapter 05 | Hejie | Chapter 05 | Samkha | Chapter 05 |
|---|---|---|---|---|---|---|
| 00:00 | 0 | 6 | 0 | 3 | 0 | 0 |
| 04:30 | 2 | 10 | 0 | 2 | 0 | 0 |
| 06:00 | 38 | 70 | 6 | 16 | 0 | 4 |
| 07:00 | 68 | 98 | 22 | 30 | 9 | 8 |
| 09:00 | 129 | 112 | 32 | 40 | 8 | 12 |
| 11:00 | 150 | 120 | 35 | 46 | 7 | 12 |
| 13:00 | 110 | 104 | 21 | 44 | 6 | 14 |
| 15:00 | 97 | 98 | 29 | 36 | 7 | 12 |
| 17:00 | 70 | 102 | 28 | 44 | 7 | 10 |
| 19:00 | 45 | 52 | 7 | 24 | 0 | 4 |
| 21:00 | 24 | 24 | 1 | 14 | 0 | 2 |

Anchors: HEJ-05, HEJ-06, HEJ-07, HEJ-08, HEJ-09, HEJ-10, HEJ-11, HEJ-12, HEJ-13, HEJ-14, HEJ-15, HEJ-16, HEJ-17, HEJ-18, HEJ-19, HEJ-20, HEJ-21, HEJ-22, HEJ-23, HEJ-24, HEJ-26, HEJ-27, HEJ-29, HEJ-30, HEJ-39, MKT-01, MKT-02, MKT-03, MKT-04, MKT-05, MKT-06, MKT-07, MKT-08, MKT-10, MKT-11, MKT-12, MKT-13, MKT-14, basin, castle_door, castle_gate, castle_lane, chang, conch_terrace, court_wait, dechen, east_gate_in, east_gate_out, headman, hejie_square, lhakhang, lookout, mani, mani_s, pema_o, pitch, pitch_out, ramp_foot, ramp_head, ramp_landing1, river_street, saddler, samkha_poor, samkha_ward, spring, stair_top, stalls, tailor, talkers, tsongra, tsongra_lower, turner, ula_yard, water_gate_in, west_edge, west_mani, west_way, yak_gate; 198 house doors, 63 of them the walkers' homes.
