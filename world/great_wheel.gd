extends Node3D
## The Mani Lhakhang's great wheel (plan chapter 03, 8.4; chapter 07, 6.5; sprint 4, step 3). Walked round clockwise
## against its bars (1.2-2.4 m from its axis, at a walk or faster), it turns with the walker, at the walker's own pace
## round it, the bar in hand going with the hand, and runs on when let go, slowing over about four seconds; walked round
## the other way it does not turn (turning a wheel backwards "is held sacrilegious", chapter 07). Its peg, high on the
## drum, strikes the bell's tongue once each turn, and the bell rings (SND-127, through the AudioDirector: a tone of a few
## decaying partials rendered by tools/audio/synth.py until chapter 10's recordings); the bell does not swing. Its axle
## groans as it goes round (SND-127's groan, oftener the faster). The first turn brings a gloss (ui/hud.gd).
## The townspeople turn it the same way (TownSim's walkers). `turns` and `rings` are counted for the tests; there is no
## score.

const R_IN := 1.2
const R_OUT := 2.4
const RUN_DOWN := 0.75  ## its spin decays by e each 1/0.75 s: about four seconds to a stop

var bell: Node3D  ## set before adding: the node at the house's BELL socket, which the peg strikes
var turns := 0.0  ## clockwise turns made, for the tests
var rings := 0  ## the bell's strokes, for the tests
var omega := 0.0  ## rad/s, clockwise seen from above
var _peg := 0.0  ## radians the peg has come round since it last struck
var _player: Node3D
var _groan := 0.0  ## seconds to the axle's next groan
var _dice := RandomNumberGenerator.new()  ## its own, never the global stream


func _physics_process(dt: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	var push := 0.0
	if _player is CharacterBody3D:
		var rel := (_player as Node3D).global_position - global_position
		var r := Vector2(rel.x, rel.z).length()
		if r > R_IN and r < R_OUT and absf(rel.y) < 1.5:
			var v: Vector3 = (_player as CharacterBody3D).velocity
			var tangent := Vector2(-rel.z, rel.x) / r  # clockwise seen from above, in Godot's x and z
			var vt := Vector2(v.x, v.z).dot(tangent)
			if vt > 0.2:
				push = vt / r  # the walker's pace round the axis (divided by a fixed 1.9 m, it ran 16% ahead of the hand)
	if TownSim.walkers_on:  # the townspeople going round it (TownSim's walkers on their round, sprint 4, step 4)
		for i in TownSim.count:
			if TownSim.state[i] != 0:
				continue
			var rel2: Vector3 = TownSim.pos[i] - global_position
			var r2 := Vector2(rel2.x, rel2.z).length()
			if r2 > R_IN and r2 < R_OUT and absf(rel2.y) < 1.5:
				var v2: Vector3 = TownSim.vel[i]
				var vt2 := Vector2(v2.x, v2.z).dot(Vector2(-rel2.z, rel2.x) / r2)
				if vt2 > 0.2:
					push = maxf(push, vt2 / r2)
	omega = maxf(push, omega * exp(-RUN_DOWN * dt))
	if omega < 0.01:
		omega = 0.0
		return
	rotation.y -= omega * dt  # clockwise from above is negative about +Y
	_groan -= dt
	if _groan <= 0.0 and omega > 0.3:  # the axle groans as it goes round, oftener the faster (sprint 8, step 4)
		_groan = _dice.randf_range(0.7, 1.5) * clampf(1.2 / omega, 0.6, 2.5)
		AudioDirector.play("SND-127.groan", global_position + Vector3(0.0, 1.0, 0.0))
	turns += omega * dt / TAU
	_peg += omega * dt
	if _peg >= TAU:
		_peg -= TAU
		rings += 1
		AudioDirector.play("SND-127", bell.global_position if bell != null else global_position)  # its stroke (data/sound.json)
	if turns > 0.25:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.gloss("The great wheel holds the mani mantra printed many thousands of times. People push it round clockwise as they walk; its bell rings once each turn.", "great_wheel")
