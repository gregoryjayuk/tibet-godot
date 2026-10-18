# Dungkardo · དུང་དཀར་མདོ — the design in brief

Dungkardo is an invented Tibetan town at a real place: the Yalong ferry on the old Qing road from Dartsedo to Lhasa, which the American traveller W. W. Rockhill called "practically the frontier post of China" when he crossed it in 1892. The game is set in the autumn of 1903, the last calm years on the border. It was researched from the eyewitness accounts of travellers who crossed this river, and every Tibetan and Chinese term was checked.

## The town in six lines

- **Where and when:** Dungkardo, "White-Conch Confluence" (Chinese 銅鼓渡, "Bronze-Drum Ferry"), autumn 1903.
- **The shape:** a Tibetan town of whitewashed stone and red timber climbs a sunny mountainside in terraces of flat roofs; a castle on a rock over an iron-chain bridge; a small walled Chinese post-town on the fan where the torrent meets the Yalong; a Gelug monastery on a spur 250 m above; a white hermitage on the cliff over that; and high above, a pass where Minya Konka stands over the clouds.
- **The intricacy:** almost no level streets. Lanes are stairs, some of them tunnels under houses; the flat roofs are a second street joined by notched-log ladders and plank bridges; 1,080 steps climb to the monastery; a gorge stair climbs out on galleries pinned to a cliff.
- **The people:** about 2,500 settled, a few hundred simulated each day, dozens of named people with hour-by-hour days: the landlady-broker of the trading house, the castle's lord, a Qing sub-lieutenant and his men, a Gesar bard, a young reincarnate lama, porters, nomads, Hui traders.
- **The time:** the game opens on Wednesday 28 October 1903 (Tibetan 9th month, 8th day; the Chinese Double Ninth) and runs the sixteen days to the festival of Lhabab Düchen, with its lit stair.
- **The look:** stylized and painterly, with Karma Gadri, the Kham school of thangka painting, as the house style for sky, cloud, water and colour.

## The awe moments

Twenty-four staged moments shape a first play-through. Among them: the Gate Chorten reveal, the chain bridge, evening on the roofs, the whole town at golden hour, prayer flags across the gorge, a caravan of a hundred yak, the dawn horns on the assembly hall's roof, the Chinese quarter's lanterns in night rain, the cloud sea from the hermitage, the assembly hall at the full moon, the Maitreya's face from the top gallery, first snow in the debate courtyard, the giant thangka at dawn, and the lit stair of Lhabab Düchen.

## The player

A traveller who came up from Dartsedo with the tea caravan and lodges at the trading house, Dechen-tsang; a man or a woman, chosen at the start, who speaks some Tibetan and some Mandarin. The camera is third person with a first-person toggle. The first story, *The guarantee*, begins with a sealed letter carried for the house. Violence is rare and has consequences: fists first, then the period's weapons, the sling above all.

## How it is built

- Geometry is generated in Blender from code (the companion repository tibet-blender): a kit of Tibetan building parts assembled into about 900 buildings, interiors carved and furnished per room, people as skinned bodies baked to vertex-animation textures.
- The terrain is the real valley's elevation, reshaped where the town needs terraces, and streamed in regions with Terrain3D.
- The look lives in a handful of Godot shaders driven by global uniforms (sun, moon, wind, wetness, snow, the time of day), so every building, person and plant answers to the same light and weather.
- The world's facts are data: the town plan, the population and their days, the calendar, the palette, dialogue, barks and codex entries are JSON files under `data/`, most of them written by the Python tools in `tools/`.
