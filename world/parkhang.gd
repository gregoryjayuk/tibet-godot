extends Node3D
## The Parkhang's printers at work (M3 sprint 1, step 4; plan chapter 03, 6.10): the block laid on the inked sheet, the
## felt roller's rub, the sheet lifted, the pairs at their boards, heard through its windows from 08:00 to 17:00 (SND-211,
## a synthesised stand-in). Added by world/town.gd under RNG-10, in its printing room along the north range's second
## storey (M3 sprint 5, step 8; chapter 04, 3.6: six pairs; until then at the court's middle).

const SOUND := "SND-211"
const FROM := 480.0  ## 08:00
const TO := 1020.0  ## 17:00
const KEY := "parkhang_printers"

var _on := false


## Whether the printers are at work at `minute` of the day.
static func at_work(minute: float) -> bool:
	var m := fposmod(minute, 1440.0)
	return m >= FROM and m < TO


func _process(_dt: float) -> void:
	if not is_instance_valid(WorldClock) or not is_instance_valid(AudioDirector):
		return
	var want := at_work(WorldClock.minute)
	if want == _on:
		return
	var sd: Node = AudioDirector.sound
	if sd == null:
		return
	if want:
		sd.call("loop_start", KEY, SOUND, global_position + Vector3(0.0, 2.0, 0.0), 0.0)
	else:
		sd.call("loop_stop", KEY)
	_on = want


func _exit_tree() -> void:
	if _on and is_instance_valid(AudioDirector) and AudioDirector.sound != null:
		AudioDirector.sound.call("loop_stop", KEY)
