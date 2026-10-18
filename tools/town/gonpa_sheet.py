#!/usr/bin/env python3
"""Dungkar Gönpa whole, M3 sprint 3 on one page (chapter 12's M3; chapter 02, D08 and MON-01 to MON-41; chapter 03, 6.1-6.9;
chapter 08, V-05a/b, V-06, V-31): V-01's upward view of the spur, the Tsokchen on its platform over its courtyard, V-05 on
its rear block's roof at the gilded roof's first sun and at dusk, the Chöra and the colleges, the red chapels and the
Gönkhang, the Labrang and the working buildings, the monks' houses lived in and shut, the west face's galleries, the
Gönkor's wheel galleries and the great wheel house, and the two viewpoints sat at (V-31, V-06).
Its stills (in a window, some fifteen minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=1200 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=mon_v01,tsokchen_above,tsokchen_court,v05a_sun,v05a_town,v05b_dusk,chora_in,colleges_above,mon04_front,mon05_porch,labrang_front,jakhang_flume,monks_pair,face_top,gonkor_south,gonkor_gallery,mon23_in
  RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route viewpoints   (V-31's and V-06's, tests/player/out/s15_viewpoint_v31.png, _v06.png)
Run: tools/py tools/town/gonpa_sheet.py   Writes tests/terrain/out/gonpa_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [(TERRAIN, "s3_mon_v01", "V-01 turned right and 27 degrees up: the halls behind the spur's brow, its top rows on the skyline (ISS-205)"),
         (TERRAIN, "s3_tsokchen_above", "The Tsokchen on its platform over its courtyard, the galleried ranges, the great darchen"),
         (TERRAIN, "s3_tsokchen_court", "The Tsokchen from its courtyard: the portico, its curtains rolled up, the lantern"),
         (TERRAIN, "s3_v05a_sun", "V-05, 07:24: on the rear block's roof, the gilded roof over the inner chapel in its first sun"),
         (TERRAIN, "s3_v05a_town", "V-05, 07:24: the Yalong under its mist, the ridges lit; the spur's slope hides most of Shöl (ISS-205)"),
         (TERRAIN, "s3_v05b_dusk", "V-05 at dusk turned to 039: the Labrang's roof above; the spur hides Dungri Karpo (ISS-153)"),
         (PLAYER, "s15_viewpoint_v31", "V-31, seated in the Chöra: the debate under the gold poplars"),
         (TERRAIN, "s3_colleges_above", "The Chöra between the Tsenyi Dratsang and its court, the Gyüpa above"),
         (TERRAIN, "s3_mon04_front", "The Jampa Lhakhang up its eleven steps: its gilded roof, the windows on the Maitreya's face"),
         (TERRAIN, "s3_mon05_porch", "The Gönkhang's porch: its protectors painted on black ground, the black banners"),
         (TERRAIN, "s3_labrang_front", "The Labrang up its eleven steps, turned so its bay looks up the gorge"),
         (PLAYER, "s15_viewpoint_v06", "V-06, seated on the Labrang's roof: the gilded roofs and the valley at dusk (ISS-202)"),
         (TERRAIN, "s3_jakhang_flume", "07:00: the Jakhang's smoke lantern at the morning tea, its flume on trestles"),
         (TERRAIN, "s3_monks_pair", "The monks' houses: smoke and firewood where one is lived in, a barred door where shut"),
         (TERRAIN, "s3_face_top", "The west face from above: the houses' timber galleries over the gorge"),
         (TERRAIN, "s3_gonkor_south", "The Gönkor's eight wheel galleries on the south wall, 128 wheels"),
         (TERRAIN, "s3_gonkor_gallery", "Walking the Gönkor clockwise, the wheels at the right hand"),
         (TERRAIN, "s3_mon23_in", "The great wheel house MON-23: its 3.5 m wheel, its bars, the bell its peg strikes")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Dungkar Gönpa whole (M3 sprint 3): the Tsokchen and V-05, the Chöra and colleges, the chapels, the Labrang, the face, the Gönkor.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "gonpa_sheet.jpg")
    img.save(path, quality=86)
    print("gonpa_sheet: %s" % path)


if __name__ == "__main__":
    main()
