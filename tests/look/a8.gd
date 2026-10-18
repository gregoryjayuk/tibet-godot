extends "res://tests/look/a7.gd"
## Art step A8 (plan chapter 09, 10.2 and 16; chapter 11, 6.3): the ridge shadow on the draft street from the kit, set
## down at Tsongra (world/horizon.gd), where the real western ridge takes the sun at 16:09 (chapter 02's design: 16:10;
## docs/terrain/sun-report.md). A7's test (which loads the horizon map as the game does) at the moments round it, from the street
## (viewpoint 1) and from above (viewpoint 5). The valley's half is tests/terrain/s3.gd's --ridge mode.
## Run: tools/look/a8.sh


func _init() -> void:
	tag = "a8"
	times = [[15, 50, 0], [16, 4, 0], [16, 7, 0], [16, 9, 0], [16, 11, 0], [16, 30, 0]]

