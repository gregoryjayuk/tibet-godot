extends Node3D
## The Gönkhang heard at its door (M3 sprint 3, step 3; plan chapter 03, 6.4: "a single drum at night"; chapter 10: the
## protector rite at 16:00-17:00, "heard from the courtyard as a low pulse through the door", and at night only at the
## door): the big drum's slow beat (SND-111, a synthesised stand-in: the drum alone, the keepers' chant waits for
## recordings and consent), full through the rite and quieter through the night. Added by world/town.gd under MON-05, in
## its porch before the curtain.

const SOUND := "SND-111"
const RITE := [960.0, 1020.0]  ## 16:00-17:00
const NIGHT := [1260.0, 270.0]  ## 21:00-04:30
const NIGHT_DB := -10.0
const KEY := "gonkhang_drum"

var _db := INF  ## the level it sounds at now (INF: silent)


## The drum's level at `minute` of the day, in dB, or INF when it is silent.
static func level(minute: float) -> float:
	var m := fposmod(minute, 1440.0)
	if m >= RITE[0] and m < RITE[1]:
		return 0.0
	if m >= NIGHT[0] or m < NIGHT[1]:
		return NIGHT_DB
	return INF


func _process(_dt: float) -> void:
	if not is_instance_valid(WorldClock) or not is_instance_valid(AudioDirector):
		return
	var want := level(WorldClock.minute)
	if want == _db:
		return
	var sd: Node = AudioDirector.sound
	if sd == null:
		return
	if _db != INF:
		sd.call("loop_stop", KEY)
	if want != INF:
		sd.call("loop_start", KEY, SOUND, global_position, want)
	_db = want


func _exit_tree() -> void:
	if _db != INF and is_instance_valid(AudioDirector) and AudioDirector.sound != null:
		AudioDirector.sound.call("loop_stop", KEY)
