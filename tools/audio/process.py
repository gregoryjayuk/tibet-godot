#!/usr/bin/env python3
"""The game's sound files from their masters (plan chapter 10, 11.7; M1 sprint 8): each master in audio_src/ levelled
to its loudness target (EBU R128, measured by ffmpeg's loudnorm; one constant gain, so a loop still joins) and written
into audio/ as 16-bit WAV (Godot imports it with QOA compression; this ffmpeg has no Vorbis encoder but its own weak
one, so the beds are WAV too), its loop kept; and audio/CREDITS.csv, every file's source, licence and credit (chapter
10, 11.1: no shipped sound without one).
Targets (chapter 10, 11.7, design): beds -30 to -36 LUFS; ritual near sources -20 (the placeholders a little hotter,
they are heard from far); spot loops about -24; one-shots peaking at -6 dBFS; nothing over -1 dBFS.
Run: tools/py tools/audio/process.py
"""
import csv
import json
import os
import re
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wav import add_loop, read_wav, write_wav  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "audio_src")
OUT = os.path.join(ROOT, "audio")
SYNTH = "synthesised by tools/audio/synth.py"
OWN = "CC0 (the project's own)"
STAND_IN = "stand-in until recorded (chapter 10, 11.3)"
PLACEHOLDER = "PLACEHOLDER: sacred sound, until recorded with consent (chapter 10, 11.5)"

# master (under audio_src/) -> [game file (under audio/), loop, target (LUFS, or "peak" dBFS), source, licence, credit, notes]
FILES = {
    "synth/snd_011_wind_low.wav": ["synth/snd_011_wind_low.wav", True, -34.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_011_wind_mid.wav": ["synth/snd_011_wind_mid.wav", True, -32.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_011_wind_high.wav": ["synth/snd_011_wind_high.wav", True, -30.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_003_torrent.wav": ["synth/snd_003_torrent.wav", True, -20.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_024_juniper.wav": ["synth/snd_024_juniper.wav", True, -24.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_025_hearth.wav": ["synth/snd_025_hearth.wav", True, -27.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_009_spout.wav": ["synth/snd_009_spout.wav", True, -28.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_215_mill.wav": ["synth/snd_215_mill.wav", True, -26.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_211_printing.wav": ["synth/snd_211_printing.wav", True, -26.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_111_protector_drum.wav": ["synth/snd_111_protector_drum.wav", True, -24.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_130_wheel_bell.wav": ["synth/snd_130_wheel_bell.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_216_chop_0.wav": ["synth/snd_216_chop_0.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_216_chop_1.wav": ["synth/snd_216_chop_1.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_216_chop_2.wav": ["synth/snd_216_chop_2.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_015_flag_mass_0.wav": ["synth/snd_015_flag_mass_0.wav", True, -24.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_015_flag_mass_1.wav": ["synth/snd_015_flag_mass_1.wav", True, -24.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_117_rosary_0.wav": ["synth/snd_117_rosary_0.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_117_rosary_1.wav": ["synth/snd_117_rosary_1.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_117_rosary_2.wav": ["synth/snd_117_rosary_2.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_117_rosary_3.wav": ["synth/snd_117_rosary_3.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_129_hand_wheel.wav": ["synth/snd_129_hand_wheel.wav", True, -36.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_229_dranyen.wav": ["synth/snd_229_dranyen.wav", True, -26.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_402_bells.wav": ["synth/snd_402_bells.wav", True, -22.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_239_clock.wav": ["synth/snd_239_clock.wav", True, -30.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_603_breath.wav": ["synth/snd_603_breath.wav", True, -24.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_303_dice_0.wav": ["synth/snd_303_dice_0.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_303_dice_1.wav": ["synth/snd_303_dice_1.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_303_dice_2.wav": ["synth/snd_303_dice_2.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_303_dice_3.wav": ["synth/snd_303_dice_3.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_104_horns_dusk_placeholder.wav": ["synth/snd_104_horns_dusk_placeholder.wav", False, -16.0, SYNTH, OWN, "", PLACEHOLDER],
    "synth/snd_103_horns_dawn_placeholder.wav": ["synth/snd_103_horns_dawn_placeholder.wav", False, -16.0, SYNTH, OWN, "", PLACEHOLDER],
    "synth/snd_101_conch_one_placeholder.wav": ["synth/snd_101_conch_one_placeholder.wav", False, -18.0, SYNTH, OWN, "", PLACEHOLDER],
    "synth/snd_101_conch_two_placeholder.wav": ["synth/snd_101_conch_two_placeholder.wav", False, -18.0, SYNTH, OWN, "", PLACEHOLDER],
    "synth/snd_127_wheel_bell.wav": ["synth/snd_127_wheel_bell.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_604_tea_pour_0.wav": ["synth/snd_604_tea_pour_0.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_604_tea_pour_1.wav": ["synth/snd_604_tea_pour_1.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_604_tea_pour_2.wav": ["synth/snd_604_tea_pour_2.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_128_wheel_squeak_0.wav": ["synth/snd_128_wheel_squeak_0.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_128_wheel_squeak_1.wav": ["synth/snd_128_wheel_squeak_1.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_128_wheel_squeak_2.wav": ["synth/snd_128_wheel_squeak_2.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_128_wheel_squeak_3.wav": ["synth/snd_128_wheel_squeak_3.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_408_mastiff_0.wav": ["synth/snd_408_mastiff_0.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_408_mastiff_1.wav": ["synth/snd_408_mastiff_1.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_408_mastiff_2.wav": ["synth/snd_408_mastiff_2.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_408_mastiff_3.wav": ["synth/snd_408_mastiff_3.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_408_mastiff_4.wav": ["synth/snd_408_mastiff_4.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_408_mastiff_5.wav": ["synth/snd_408_mastiff_5.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_414_chough_0.wav": ["synth/snd_414_chough_0.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_414_chough_1.wav": ["synth/snd_414_chough_1.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_414_chough_2.wav": ["synth/snd_414_chough_2.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_414_chough_3.wav": ["synth/snd_414_chough_3.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_414_chough_4.wav": ["synth/snd_414_chough_4.wav", False, "peak", SYNTH, OWN, "", STAND_IN],
    "synth/snd_013_flags_0.wav": ["synth/snd_013_flags_0.wav", True, -26.0, SYNTH, OWN, "", STAND_IN],
    "synth/snd_013_flags_1.wav": ["synth/snd_013_flags_1.wav", True, -26.0, SYNTH, OWN, "", STAND_IN],
}
CEILING = 10 ** (-1.0 / 20.0)  # -1 dBFS

# Kenney's CC0 packs (tools/audio/fetch_kenney.sh; Greg's yes, 27 Sep 2026): [game file stem, the pack's files, peak
# dBFS]. Mono, 48 kHz, each levelled to its peak; the footsteps quiet (Greg: "quiet footsteps").
KENNEY = [
    ["snd_601_step_stone", ["impact/Audio/footstep_concrete_%03d.ogg" % k for k in range(5)], -16.0],
    ["snd_601_step_earth", ["rpg/Audio/footstep%02d.ogg" % k for k in range(10)], -17.0],
    ["snd_601_step_wood", ["impact/Audio/footstep_wood_%03d.ogg" % k for k in range(5)], -15.0],
    ["snd_601_step_rug", ["impact/Audio/footstep_carpet_%03d.ogg" % k for k in range(5)], -20.0],
    ["snd_602_cloth", ["rpg/Audio/cloth%d.ogg" % k for k in range(1, 5)], -16.0],
    ["snd_219_creak", ["rpg/Audio/creak%d.ogg" % k for k in range(1, 4)], -14.0],
    ["snd_218_door_open", ["rpg/Audio/doorOpen_%d.ogg" % k for k in range(1, 3)], -10.0],
    ["snd_218_door_close", ["rpg/Audio/doorClose_%d.ogg" % k for k in range(1, 5)], -10.0],
    ["snd_220_curtain", ["impact/Audio/impactSoft_heavy_%03d.ogg" % k for k in range(5)], -14.0],  # a hall's yak-hair curtain falling back (M3 sprint 6)
    ["snd_609_page", ["rpg/Audio/bookFlip%d.ogg" % k for k in range(1, 4)], -12.0],
    ["snd_609_book_open", ["rpg/Audio/bookOpen.ogg"], -12.0],
    ["snd_609_book_close", ["rpg/Audio/bookClose.ogg"], -12.0],
    ["snd_610_punch", ["impact/Audio/impactPunch_medium_%03d.ogg" % k for k in range(5)], -8.0],
    ["snd_610_punch_heavy", ["impact/Audio/impactPunch_heavy_%03d.ogg" % k for k in range(5)], -6.0],
    ["snd_610_block", ["impact/Audio/impactSoft_medium_%03d.ogg" % k for k in range(5)], -10.0],
    ["snd_219_knock", ["impact/Audio/impactPlank_medium_%03d.ogg" % k for k in range(5)], -12.0],
    ["snd_207_pot", ["rpg/Audio/metalPot%d.ogg" % k for k in range(1, 4)], -14.0],
    ["snd_208_chisel", ["impact/Audio/impactMining_%03d.ogg" % k for k in range(5)], -15.0],
    ["snd_604_coins", ["rpg/Audio/handleCoins.ogg", "rpg/Audio/handleCoins2.ogg"], -14.0],
]
KENNEY_CREDIT = ["Kenney (kenney.nl): %s", "CC0 1.0", "Kenney (kenney.nl)", "downloaded with Greg's yes, 27 Sep 2026"]


def kenney(rows):
    """The Kenney files: each decoded by ffmpeg to 48 kHz mono and levelled to its peak."""
    import tempfile
    base = os.path.join(SRC, "lib", "kenney")
    if not os.path.isdir(base):
        print("process: no audio_src/lib/kenney (run tools/audio/fetch_kenney.sh)")
        return
    for stem, files, peak_db in KENNEY:
        for k, f in enumerate(files):
            src = os.path.join(base, f)
            if not os.path.exists(src):
                print("process: missing %s" % f)
                continue
            with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
                subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src, "-ac", "1", "-ar", "48000", "-c:a", "pcm_s16le", tmp.name], check=True)
                x, rate = read_wav(tmp.name)
            x = x * (10 ** (peak_db / 20.0) / (float(np.max(np.abs(x))) + 1e-12))
            game = "kenney/%s_%d.wav" % (stem, k)
            dst = os.path.join(OUT, game)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            write_wav(dst, x, rate, loop=False)
            pack = "RPG Audio" if f.startswith("rpg") else "Impact Sounds"
            rows.append([game, KENNEY_CREDIT[0] % (pack + ", " + os.path.basename(f)), KENNEY_CREDIT[1], KENNEY_CREDIT[2], KENNEY_CREDIT[3]])
    print("process: %d Kenney files -> audio/kenney/" % sum(len(f) for _, f, _ in KENNEY))


def loudness(path):
    """Integrated loudness (LUFS) by ffmpeg's loudnorm, first pass."""
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "loudnorm=print_format=json", "-f", "null", "-"],
                       capture_output=True, text=True)
    m = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", r.stderr, re.S)
    return float(json.loads(m.group(0))["input_i"])


def main():
    rows = []
    for master, (game, loop, target, source, licence, credit, notes) in FILES.items():
        src = os.path.join(SRC, master)
        if not os.path.exists(src):
            print("process: missing %s (run tools/audio/synth.py)" % master)
            continue
        x, rate = read_wav(src)
        peak = float(np.max(np.abs(x)))
        if target == "peak":
            gain = 10 ** (-6.0 / 20.0) / peak
            got = "peak -6 dBFS"
        else:
            gain = 10 ** ((target - loudness(src)) / 20.0)
            got = "%.0f LUFS" % target
        if peak * gain > CEILING:  # never over -1 dBFS: the target yields
            gain = CEILING / peak
            got += " (held under -1 dBFS)"
        dst = os.path.join(OUT, game)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        write_wav(dst, x * gain, rate, loop=loop)
        rows.append([game, source, licence, credit, notes])
        print("process: %s  %s%s" % (game, got, ", loops" if loop else ""))
    kenney(rows)
    with open(os.path.join(OUT, "CREDITS.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["file", "source", "licence", "credit", "notes"])
        w.writerows(sorted(rows))
    print("process: %d files -> audio/, their credits in audio/CREDITS.csv" % len(rows))


if __name__ == "__main__":
    main()
