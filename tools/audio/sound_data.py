#!/usr/bin/env python3
"""The sound data (plan chapter 10, 13.10; M1 sprint 8, step 1): data/sound.json, read by the AudioDirector
(autoload/audio_director.gd): the emitter classes (13.3), the slice's sound records (12's IDs), the district beds and
their layer curves over the day (13.7), the reverb zones (9.1, 9.3; 13.4) and the scheduled ritual sounds (4.1).
Every file named here must be in audio/ and in audio/CREDITS.csv (tools/audio/process.py; the tests check both).
Run: python3 tools/audio/sound_data.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 13.3: model (inverse, log), unit_size, max_distance (m), filter cutoff (Hz; 0 off) and its dB, polyphony, pool, delay.
# The valley calls and long calls fall off as inverse distance, not the chapter's "logarithmic": Godot's logarithmic
# model is -20 ln(d / unit_size), steeper, not gentler (-36 dB at 560 m for the horns, lost under Tsongra's beds;
# inverse gives -16 dB there, -30 dB at 3 km; 27 Sep 2026)
CLASSES = {
    "valley_call": {"model": "inverse", "unit_size": 90.0, "max_distance": 3000.0, "cutoff": 3000.0, "cutoff_db": -18.0, "polyphony": 2, "pool": "ritual", "delay": True},
    "rites_far": {"model": "inverse", "unit_size": 30.0, "max_distance": 1500.0, "cutoff": 2500.0, "cutoff_db": -24.0, "polyphony": 4, "pool": "ritual", "delay": True},
    "bells": {"model": "inverse", "unit_size": 20.0, "max_distance": 600.0, "cutoff": 4000.0, "cutoff_db": -20.0, "polyphony": 3, "pool": "animals", "delay": False},
    "river": {"model": "inverse", "unit_size": 25.0, "max_distance": 400.0, "cutoff": 6000.0, "cutoff_db": -12.0, "polyphony": 1, "pool": "river", "delay": False},
    "work": {"model": "inverse", "unit_size": 8.0, "max_distance": 120.0, "cutoff": 4000.0, "cutoff_db": -24.0, "polyphony": 2, "pool": "near", "delay": False},
    "spans": {"model": "inverse", "unit_size": 25.0, "max_distance": 220.0, "cutoff": 4000.0, "cutoff_db": -18.0, "polyphony": 2, "pool": "loops", "delay": False},
    "animals": {"model": "inverse", "unit_size": 6.0, "max_distance": 150.0, "cutoff": 5000.0, "cutoff_db": -24.0, "polyphony": 2, "pool": "animals", "delay": False},
    "voices": {"model": "inverse", "unit_size": 3.0, "max_distance": 40.0, "cutoff": 6000.0, "cutoff_db": -24.0, "polyphony": 1, "pool": "near", "delay": False},
    "long_calls": {"model": "inverse", "unit_size": 40.0, "max_distance": 400.0, "cutoff": 3500.0, "cutoff_db": -18.0, "polyphony": 1, "pool": "near", "delay": True},
    "near_foley": {"model": "inverse", "unit_size": 2.0, "max_distance": 25.0, "cutoff": 8000.0, "cutoff_db": -24.0, "polyphony": 3, "pool": "near", "delay": False},
    "spot_loop": {"model": "inverse", "unit_size": 4.0, "max_distance": 60.0, "cutoff": 6000.0, "cutoff_db": -12.0, "polyphony": 1, "pool": "loops", "delay": False},
    "birds_far": {"model": "inverse", "unit_size": 10.0, "max_distance": 400.0, "cutoff": 4000.0, "cutoff_db": -18.0, "polyphony": 2, "pool": "animals", "delay": True},
    "flutter": {"model": "inverse", "unit_size": 2.0, "max_distance": 25.0, "cutoff": 7000.0, "cutoff_db": -12.0, "polyphony": 1, "pool": "loops", "delay": False},
    "hearth": {"model": "inverse", "unit_size": 1.5, "max_distance": 16.0, "cutoff": 5000.0, "cutoff_db": -18.0, "polyphony": 2, "pool": "loops", "delay": False},
    "player": {"model": "inverse", "unit_size": 1.0, "max_distance": 10.0, "cutoff": 0.0, "cutoff_db": 0.0, "polyphony": 3, "pool": "dialogue", "delay": False},
}
# 13.8: voices per pool and their priority (1 highest); a full pool steals from its own lowest-priority, quietest voice
POOLS = {"dialogue": [4, 1], "ritual": [4, 2], "near": [12, 3], "animals": [6, 4], "loops": [6, 5], "river": [3, 5]}

S = "synth/"
SOUNDS = {
    "SND-003": {"name": "Dungchu in the gorge (stand-in: a synthetic torrent)", "files": [S + "snd_003_torrent.wav"], "bus": "Water", "class": "river", "loop": True},
    "SND-011": {"name": "Valley wind bed, low, with gusts (stand-in), at three strengths", "files": [S + "snd_011_wind_low.wav", S + "snd_011_wind_mid.wav", S + "snd_011_wind_high.wav"], "bus": "Wind", "loop": True, "lufs": [-34.0, -32.0, -30.0]},
    "SND-013": {"name": "Prayer flags in the wind: a string or a pole's bundle flapping (stand-in, synthesised)", "files": [S + "snd_013_flags_0.wav", S + "snd_013_flags_1.wav"], "bus": "World", "class": "flutter", "loop": True},
    "SND-024": {"name": "Green juniper on a burner (stand-in)", "files": [S + "snd_024_juniper.wav"], "bus": "World", "class": "spot_loop", "loop": True},
    "SND-025": {"name": "A kitchen's clay stove: its draw, dry wood crackling, an ember settling (stand-in, synthesised)", "files": [S + "snd_025_hearth.wav"], "bus": "World", "class": "hearth", "loop": True},
    "SND-229": {"name": "The dranyen at the chang house from 19:00: strummed, the drone on D, a 6/8 figure (stand-in, synthesised, until it is played and recorded)", "files": [S + "snd_229_dranyen.wav"], "bus": "World", "class": "hearth", "loop": True},
    "SND-603": {"name": "The walker's breath, winded after a sprint: quick deep breaths, a loop (stand-in, synthesised; player/player.gd, IMP-043, louder the harder it breathes)", "files": [S + "snd_603_breath.wav"], "bus": "Foley", "class": "player", "loop": True},
    "SND-239": {"name": "A French clock ticking on Dolkar's shelf, wound at dusk, for an hour (stand-in, synthesised; chapter 04, 4.3)", "files": [S + "snd_239_clock.wav"], "bus": "World", "class": "hearth", "loop": True, "gain_db": -4.0},
    "SND-303": {"name": "The pieman's dice: three bone dice shaken in a wooden cup and thrown on the board in Dechen-tsang's Yard 1 (stand-in, synthesised; world/work_sounds.gd, from the players at their hours)", "files": [S + "snd_303_dice_%d.wav" % k for k in range(4)], "bus": "World", "class": "near_foley", "loop": False},
    "SND-402": {"name": "The caravan's bells: the lead yak's iron bell at each stride, the file's small bells out of step (stand-in, synthesised, until they are recorded; ISS-083; played from the lead by world/caravan.gd while it walks)", "files": [S + "snd_402_bells.wav"], "bus": "Animals", "class": "hearth", "loop": True},
    "SND-129": {"name": "A hand prayer wheel turning: its whirr and its weight's tick, 1.4 turns a second (stand-in, synthesised; played from the walker by characters/hand_wheel.gd)", "files": [S + "snd_129_hand_wheel.wav"], "bus": "Foley", "class": "near_foley", "loop": True},
    "SND-101": {"name": "Daily conch, one and two blasts (PLACEHOLDER)", "files": [S + "snd_101_conch_one_placeholder.wav", S + "snd_101_conch_two_placeholder.wav"], "bus": "Ritual", "class": "valley_call", "echo": True, "gain_db": 4.0},
    "SND-103": {"name": "Dawn horns, two long horns (PLACEHOLDER)", "files": [S + "snd_103_horns_dawn_placeholder.wav"], "bus": "Ritual", "class": "valley_call", "echo": True, "emission_deg": 70.0, "facing_deg": 240.0, "gain_db": 6.0},
    "SND-104": {"name": "Dusk horns (PLACEHOLDER; the shawms to come)", "files": [S + "snd_104_horns_dusk_placeholder.wav"], "bus": "Ritual", "class": "valley_call", "echo": True, "emission_deg": 70.0, "facing_deg": 240.0, "gain_db": 6.0},
    "SND-127": {"name": "The Mani Lhakhang's great wheel's bell, once a turn", "files": [S + "snd_127_wheel_bell.wav"], "bus": "Ritual", "class": "bells"},
}
# Kenney's CC0 sounds (tools/audio/fetch_kenney.sh, levelled by process.py into audio/kenney/): the player's steps by the
# surface underfoot, cloth, the ladders' creak and knock, doors, the codex's pages (SND-609), the fighting (SND-610, which
# chapter 10's catalogue gained on 27 Sep 2026), the kitchen. `vary`: a randomizer's
# pitch (semitones) and volume (dB) spread, never on voices (chapter 10, 13.8); `pitch`: a base pitch scale.
K = "kenney/"
def _k(stem, n):
    return [K + "%s_%d.wav" % (stem, k) for k in range(n)]
SOUNDS.update({
    "SND-601.stone": {"name": "The player's steps on stone: flagstones, stone steps, the lanes", "files": _k("snd_601_step_stone", 5), "bus": "Foley", "class": "player", "vary": [0.6, 2.0]},
    "SND-601.earth": {"name": "The player's steps on beaten earth: the roofs, the valley outside the town", "files": _k("snd_601_step_earth", 10), "bus": "Foley", "class": "player", "vary": [0.6, 2.0]},
    "SND-601.wood": {"name": "The player's steps on wood: ladders, planks, galleries, wooden floors", "files": _k("snd_601_step_wood", 5), "bus": "Foley", "class": "player", "vary": [0.6, 2.0]},
    "SND-601.rug": {"name": "The player's steps on a rug", "files": _k("snd_601_step_rug", 5), "bus": "Foley", "class": "player", "vary": [0.5, 2.0]},
    "SND-602": {"name": "The player's heavy coat: sitting, standing, climbing", "files": _k("snd_602_cloth", 4), "bus": "Foley", "class": "player", "vary": [0.5, 2.0]},
    "SND-219.creak": {"name": "A notched-log ladder's creak under the climber", "files": _k("snd_219_creak", 3), "bus": "Foley", "class": "near_foley", "vary": [1.0, 2.0]},
    "SND-219.knock": {"name": "A notched-log ladder knocked down on a parapet or the ground: drawn up at dusk, set down at dawn", "files": _k("snd_219_knock", 5), "bus": "Foley", "class": "work", "vary": [1.0, 2.0]},
    "SND-218.open": {"name": "A door opened", "files": _k("snd_218_door_open", 2), "bus": "Foley", "class": "near_foley", "vary": [0.5, 1.0]},
    "SND-218.close": {"name": "A door closed", "files": _k("snd_218_door_close", 4), "bus": "Foley", "class": "near_foley", "vary": [0.5, 1.0]},
    "SND-220": {"name": "A hall's yak-hair curtain falling back behind whoever came through (a stand-in: Kenney's soft heavy impact)", "files": _k("snd_220_curtain", 5), "bus": "Foley", "class": "near_foley", "vary": [0.5, 1.0]},
    "SND-609.page": {"name": "The codex: a page turned as an entry is written", "files": _k("snd_609_page", 3), "bus": "UI", "class": "player", "vary": [0.4, 1.0]},
    "SND-609.open": {"name": "The codex opened", "files": _k("snd_609_book_open", 1), "bus": "UI", "class": "player"},
    "SND-609.close": {"name": "The codex closed", "files": _k("snd_609_book_close", 1), "bus": "UI", "class": "player"},
    "SND-610.punch": {"name": "A blow landing", "files": _k("snd_610_punch", 5), "bus": "Foley", "class": "near_foley", "vary": [1.0, 2.0]},
    "SND-610.punch_heavy": {"name": "A heavy blow landing, a knock-down", "files": _k("snd_610_punch_heavy", 5), "bus": "Foley", "class": "near_foley", "vary": [1.0, 2.0]},
    "SND-610.block": {"name": "A blow taken on the guard", "files": _k("snd_610_block", 5), "bus": "Foley", "class": "near_foley", "vary": [1.0, 2.0]},
    "SND-208": {"name": "The mani carver's chisel: an iron point struck into slate (Pasang at his pitch)", "files": _k("snd_208_chisel", 5), "bus": "World", "class": "work", "vary": [1.5, 3.0], "gain_db": -3.0},
    "SND-127.groan": {"name": "The great wheel's axle groaning as it turns (Kenney's creaks, pitched down)", "files": _k("snd_219_creak", 3), "bus": "World", "class": "near_foley", "vary": [1.0, 2.0], "pitch": 0.55, "gain_db": -4.0},
    "SND-207.pot": {"name": "A pot set down in a kitchen", "files": _k("snd_207_pot", 3), "bus": "Foley", "class": "work", "vary": [1.0, 3.0]},
    "SND-604.coins": {"name": "Coins counted", "files": _k("snd_604_coins", 2), "bus": "Foley", "class": "near_foley", "vary": [0.5, 2.0]},
    "SND-215": {"name": "A water mill at work on the Serchu's leat: the chute's jet on the paddles, the runner's grind, the clapper on the shoe (stand-in, synthesised; world/mills.gd, at each mill)", "files": [S + "snd_215_mill.wav"], "bus": "Water", "class": "spot_loop", "loop": True, "gain_db": -3.0},
    "SND-130": {"name": "A water prayer wheel's small bell, struck once a turn by a peg on its drum (stand-in, synthesised; world/mills.gd, at each wheel house's BELL)", "files": [S + "snd_130_wheel_bell.wav"], "bus": "Ritual", "class": "work", "gain_db": -9.0},
    "SND-216": {"name": "A woodcutter's axe biting into a larch's trunk in the Shade Wood (stand-in, synthesised; world/serchu_people.gd, at each woodcutter at work)", "files": [S + "snd_216_chop_0.wav", S + "snd_216_chop_1.wav", S + "snd_216_chop_2.wav"], "bus": "World", "class": "work", "gain_db": -4.0},
    "SND-117": {"name": "A pilgrim's rosary on the 1,080 steps, a bead slipped at each step (stand-in, synthesised: no voice until the counting is recorded; world/steps_people.gd, from the nearest climber)", "files": [S + "snd_117_rosary_%d.wav" % k for k in range(4)], "bus": "Foley", "class": "near_foley", "vary": [0.5, 1.0], "gain_db": -6.0},
    "SND-015": {"name": "The gorge's flag spans: six strings of prayer flags across it snapping as one in the wind (stand-in, synthesised; world/flags.gd, at each span's middle)", "files": [S + "snd_015_flag_mass_%d.wav" % k for k in range(2)], "bus": "World", "class": "spans", "loop": True, "gain_db": -4.0},
    "SND-111": {"name": "The Gönkhang's protector rite heard through its door: the big drum's slow beat (stand-in, synthesised: the drum alone, the keepers' chant and the rolmo wait for recordings and consent; world/gonkhang.gd, 16:00-17:00, and quieter at night)", "files": [S + "snd_111_protector_drum.wav"], "bus": "Ritual", "class": "spot_loop", "loop": True, "gain_db": -6.0},
    "SND-211": {"name": "The Parkhang's printers at work, heard through its windows: the block laid on the inked sheet, the felt roller's rub, the sheet lifted (stand-in, synthesised; world/parkhang.gd, 08:00-17:00)", "files": [S + "snd_211_printing.wav"], "bus": "Foley", "class": "spot_loop", "loop": True, "gain_db": -8.0},
    "SND-009": {"name": "The Lukhang spring's spout falling into its stone basin (stand-in, synthesised; world/spring.gd, at each spout's mouth)", "files": [S + "snd_009_spout.wav"], "bus": "Water", "class": "hearth", "loop": True, "gain_db": -2.0},
    "SND-128": {"name": "A wall prayer wheel set turning by a hand: its pin squeaking in its socket, the drum's rumble (stand-in, synthesised, until Pema Ö's wheels are recorded; its kora corridor's 36, world/kora_wheels.gd)", "files": [S + "snd_128_wheel_squeak_%d.wav" % k for k in range(4)], "bus": "Foley", "class": "near_foley", "vary": [0.9, 1.1], "gain_db": -2.0},
    "SND-408": {"name": "A mastiff's bark: deep, rough (stand-in, synthesised, until the mastiffs are recorded; Samkha Khar's two on their roof barking at the chain bridge, world/samkha_people.gd)", "files": [S + "snd_408_mastiff_%d.wav" % k for k in range(6)], "bus": "Animals", "class": "animals", "vary": [0.92, 1.06], "gain_db": 2.0},
    "SND-414": {"name": "Choughs: a ringing \"chee-ow\" (stand-in, synthesised)", "files": [S + "snd_414_chough_%d.wav" % k for k in range(5)], "bus": "Animals", "class": "birds_far", "vary": [1.0, 1.5], "gain_db": -6.0},
    "SND-604.tea": {"name": "Tea poured into the player's bowl (stand-in, synthesised)", "files": [S + "snd_604_tea_pour_%d.wav" % k for k in range(3)], "bus": "Foley", "class": "player", "vary": [0.5, 1.0], "gain_db": -4.0},
})

OFF = None  # a layer off at that hour
# No murmur of voices (Greg, 27 Sep 2026, 18:55: "the murmouring doesn't sound good, and even if it did would we want
# it?"): the synthetic walla and lanes' murmur (SND-501, SND-502) are gone; a crowd bed comes back only recorded from
# real people, if Greg wants it.
# 13.7: each bed's layers, a curve of its loudness over the day's hours (LUFS at the listener; keys "HH:MM", linear
# between them; None off): a layer's player gain is the curve less its files' own loudness (`lufs`, tools/audio/process.py)
BEDS = {
    "AMB-valley": {"district": "*", "layers": [
        {"sound": "SND-011", "curve": {"00:00": -38, "06:00": -38, "11:00": -35, "15:00": -32, "18:00": -35, "23:59": -38}, "wind": True},
    ]},
}

# 9.1, 9.3: the zones the slice has, their bus, how much each sound inside sends to it, and its uniformity (13.4)
ZONES = {
    "RZ-07": {"name": "Small room: Dechen-tsang's guest room", "bus": "Rv_Room", "amount": 0.15, "uniformity": 0.8, "rt60": 0.5},
    "RZ-08": {"name": "Room, carpeted: Dechen-tsang's Tibetan room", "bus": "Rv_Room", "amount": 0.10, "uniformity": 0.8, "rt60": 0.4},
    "RZ-09": {"name": "Tiny, dead: the poor house H-SHL-142", "bus": "Rv_Dead", "amount": 0.10, "uniformity": 0.85, "rt60": 0.3},
    "RZ-12": {"name": "Timber room, lively: Dechen-tsang's Chinese room", "bus": "Rv_Room", "amount": 0.20, "uniformity": 0.8, "rt60": 0.7},
    "RZ-15": {"name": "Per floor: a house's kitchen (Dechen-tsang's), 0.6 s", "bus": "Rv_Room", "amount": 0.18, "uniformity": 0.8, "rt60": 0.6},
    "RZ-20": {"name": "Stone lanes: the Sky Stair between its walls", "bus": "Rv_Lane", "amount": 0.25, "uniformity": 0.2, "rt60": 0.5},
    "RZ-21": {"name": "Covered passage: the tunnel under three houses (SHL-16)", "bus": "Rv_Stone", "amount": 0.40, "uniformity": 0.6, "rt60": 1.0},
    "RZ-22": {"name": "Gateway chorten: SHL-17's passage", "bus": "Rv_Stone", "amount": 0.35, "uniformity": 0.6, "rt60": 0.9},
    "RZ-23": {"name": "Tsongra, the open square", "bus": "Rv_Lane", "amount": 0.12, "uniformity": 0.3, "rt60": 0.4},
    "RZ-24": {"name": "Stable and stores, straw and dung underfoot: the headman's ground floor (SHL-19)", "bus": "Rv_Dead", "amount": 0.12, "uniformity": 0.85, "rt60": 0.35},
}
ROOM_ZONES = {"dechen_tibetan": "RZ-08", "dechen_chinese": "RZ-12", "dechen_guest": "RZ-07", "dechen_kitchen": "RZ-15",
              "dechen_chapel": "RZ-12", "dechen_dolkar": "RZ-08",  # Yard 3 (M2 sprint 8): the chapel's boards and bare walls lively, her carpets three deep
              "house_kitchen_b2_in_v1": "RZ-15", "house_kitchen_b2_in_v2": "RZ-15", "house_kitchen_b2_in_v3": "RZ-15",  # the town houses' kitchens (sprint 8, step 7)
              "house_room_e1_in_v1": "RZ-09", "house_room_e1_in_v2": "RZ-09", "house_room_e1_in_v3": "RZ-09",  # the poor house's one room (ISS-105)
              "chang_room_b2_in_v1": "RZ-15", "chang_room_b2_in_v2": "RZ-15", "chang_room_b2_in_v3": "RZ-15",  # the chang house's drinking room (M2 sprint 2)
              # the headman's house, per floor (chapter 04, 4.1; M2 sprint 7): the stable dead with straw, the kitchen's 0.6 s, the
              # carpeted rooms, the halls and the small rooms
              "headman_stable": "RZ-24", "headman_hall1": "RZ-07", "headman_kitchen": "RZ-15", "headman_reception": "RZ-08",
              "headman_grain": "RZ-07", "headman_hall2": "RZ-07", "headman_shrine": "RZ-08", "headman_guest": "RZ-08",
              "headman_bed1": "RZ-08", "headman_bed2": "RZ-08", "headman_roofroom": "RZ-07"}

# 4.1: the monastery's day, from the Tsokchen roof (MON-40); the town grid's x, y and height
PLACES = {"MON-40": [540.0, 150.0, 2947.0]}
SCHEDULE = [
    {"time": "05:00", "sound": "SND-101", "variant": 0, "at": "MON-40"},
    {"time": "05:25", "sound": "SND-101", "variant": 1, "at": "MON-40"},
    {"time": "05:30", "sound": "SND-103", "at": "MON-40"},
    {"time": "17:15", "sound": "SND-104", "at": "MON-40"},
]
# 13.6: the echo's reflector, the western ridge crest (chapter 02, 2.7): about 3.9 km from Tsongra at 250 degrees
ECHO = {"at": [-3660.0, -1330.0, 3900.0], "db": -24.0, "cutoff": 800.0}


def main():
    out = {"about": "The game's sound data (plan chapter 10, 13.10), written by tools/audio/sound_data.py: do not edit by hand. Files are under res://audio/ with their credits in audio/CREDITS.csv.",
           "classes": CLASSES, "pools": POOLS, "sounds": SOUNDS, "beds": BEDS, "zones": ZONES, "room_zones": ROOM_ZONES,
           "places": PLACES, "schedule": SCHEDULE, "echo": ECHO, "sound_speed_at_c": [331.3, 0.606], "air_c": 8.0}
    json.dump(out, open(os.path.join(ROOT, "data", "sound.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("sound_data: %d sounds, %d beds, %d zones, %d scheduled -> data/sound.json" % (len(SOUNDS), len(BEDS), len(ZONES), len(SCHEDULE)))


if __name__ == "__main__":
    main()
