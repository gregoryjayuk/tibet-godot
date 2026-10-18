extends CharacterBody3D
## The player (plan chapter 11, 13.1): a capsule on Jolt at 30 Hz with physics interpolation. The camera is top-level
## and placed every rendered frame from the interpolated body plus the mouse look, so turning never waits for a physics
## tick. The camera carries the screen-space ink-line quad. The draft climbs stairs with its step-up hack (ISS-005);
## M1's player climbs the kit's flights on their ramps (chapter 11, 13.2; sprint 3, step 3, ISS-035): the ramp under the
## capsule carries its steps, so the pace is counted in steps (1.3 a second up at a walk, 2 down), the walk plays one
## step to a tread, and the feet are set on the treads (characters/feet.gd). Notched logs (chapter 11, 13.3; step 3,
## part 2): walking into one's foot, or up to its top from the roof, mounts it; W and S climb it at 0.5 m/s; at its top
## the climb-up clip steps over the parapet onto the roof, at its foot a step off. Split out of main.gd at M0 RT-03.
## M1's player is seen in third person (Greg, 25 Sep 2026, 17:35: as in Red Dead Redemption 2, with a first-person
## toggle): a body that turns towards where it goes and plays its gait at the speed that keeps its feet planted
## (assets/generated/people/player_clips.json), and a camera over the right shoulder on an arm that shortens against
## walls and ceilings, so it keeps its head in the town's 2.4 m passages. Until chapter 05's bodies (12, steps 3-4) the
## body is the villager stand-in (../tibet-blender/people2/stand_ins.py). The draft keeps the first-person player.
##
## Controls (IMP-044; Greg's brief of 14 Oct 2026, docs/brief-movement-controls.md; the input actions are
## autoload/controls.gd's): the keys and the mouse as World of Warcraft has them, with no clicking in: W and S forward and
## back along the walker's way, A and D turn it; the left button held and dragged swings the camera round the walker,
## the right held turns the walker to the camera's way (A and D then step aside), both walk on, the wheel brings the
## camera closer or further; the cursor hides while a button is held and comes back where it was. A PS4 controller
## GTA's way: the left stick moves the way it is pushed from the camera (a light tilt walks), the right stick turns the
## camera. Until 14 Oct 2026 a click took the mouse and W A S D went where the camera looked.
## The pace (IMP-043): a jog (4.5 m/s) unless Option toggles the walk (1.5 m/s; Shift toggled it from 10 Oct to 14 Oct
## 2026), a sprint (7 m/s) while Shift or the controller's cross is held, for about 15 s before the breath runs out
## (panting, a faint vignette at the screen's edge, no bar), back after a few seconds' jog. F fly (E/Q up/down, Shift
## held faster), O ink outlines on/off, 1-9 jump to viewpoints (as many as the scene gives). First person (the draft,
## and V in third person) looks with the mouse, taken at once; Esc frees it, and a button held then looks. Third person:
## B the man or the woman, C (circle) sit down or stand up. Fighting (chapter 11, 13.8; Greg's choice, chapter 14, 3): R
## puts the fists up and takes the mouse for the fight (left button punches, right guards; R or Esc lowers them), on the
## controller R1 punches and L1 guards; Space (square) jumps, and with the guard up dodges; G takes out the sling (hold
## the left button to whirl it, let go to loose the stone where the camera aims; on the controller R2 held and let go).
## Sitting (chapter 11, 13.1 and 15.1): C sits on a ledge 0.3-0.65 m high just behind (a step, a wall's footing, a
## bench), or kneels where there is none; seated, time runs 60:1, which is how a player waits for dusk (15.1's
## "watch", until now held on T); C again or a step stands up.

const SHADER_OUTLINE := preload("res://shaders/outline.gdshader")
const PERSON := preload("res://characters/person.gdshader")
const Ink := preload("res://world/ink.gd")
const Fighting := preload("res://characters/fighting.gd")
const Feet := preload("res://characters/feet.gd")
const EYE := 1.6
const BODIES := {"man": "res://assets/generated/people/player_man.glb", "woman": "res://assets/generated/people/player_woman.glb"}
## The player's clothes (IMP-025; Greg's 1771): each of the two dressed three ways, changed at the chest in Dechen-tsang's
## guest room (world/wardrobe.gd): [name, body file, in words] (../tibet-blender people2/body.py BODIES)
const OUTFITS := {"man": [["road", "res://assets/generated/people/player_man.glb", "Sheepskin, leather out, for the road"],
		["town", "res://assets/generated/people/player_man_town.glb", "Dull red serge to the knee, for the town"],
		["best", "res://assets/generated/people/player_man_best.glb", "Fine dark wool, a turban and a ga'u, for a visit"]],
	"woman": [["road", "res://assets/generated/people/player_woman.glb", "A blue truk trimmed black, for the road"],
		["town", "res://assets/generated/people/player_woman_town.glb", "Undyed wool under the dark over-gown, for the town"],
		["best", "res://assets/generated/people/player_woman_best.glb", "A striped truk, a silk over-gown and amber, for a visit"]]}
const CLIPS := "res://assets/generated/people/player_clips.json"
## Chapter 11, 13.1: walk 1.3 m/s, run 4.5 m/s on level ground; the walk is 1.5 m/s since Greg found the player "a
## little slow" (26 Sep 2026, 14:12; M1's gate asks for the pace). The run is the default since Greg, 10 Oct 2026, 11:00
## ("the walking is too slow ... the run should be default"), called the jog since 14 Oct 2026 (IMP-043: "the normal
## movement is kind of like a jog, and then you can sprint to go a bit faster"): Option toggles the walk (`walking`),
## Shift or the controller's cross held sprints, the body build's Sprint clip (7.5 m/s the man's, 6.5 the woman's).
## Backing away on S is a walk, the body still facing its way (Walk_Backwards).
const WALK := 1.5
const RUN := 4.5
const SPRINT := 7.0
const BACK := 1.2
## The breath (IMP-043; chapter 06, 10.7's breath, "sound and a faint vignette, no bar"): seconds of sprint at the town's
## height before it runs out; then winded, no sprint, until half of it is back. It comes back BREATH_JOG a second at the
## jog, BREATH_EASY walking or still: a few seconds' jog and the sprint is there again.
const BREATH := 15.0
const BREATH_JOG := 2.5
const BREATH_EASY := 4.0
const VIGNETTE := 0.35  ## the vignette's darkness at the screen's corners, winded: faint (0.55 took half the light there)
const PANT_DB := -6.0  ## the panting (SND-603), winded
## The controls' feel: the keys turn the walker PI a second (World of Warcraft's 180 degrees), the camera eases back
## behind the walker as it goes (FOLLOW a second) unless a button holds it, the mouse turns 0.0025 radians a pixel, the
## wheel steps the arm by ZOOM_STEP between ZOOM_MIN and ZOOM_MAX of its length; a light tilt of the left stick, under
## WALK_TILT, walks.
const TURN := PI
const FOLLOW := 2.5
const MOUSE_TURN := 0.0025
const ZOOM_STEP := 0.88
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.2
const WALK_TILT := 0.6
## Space jumps (0.55 m); with the guard up it dodges instead (the fight took it for the dodge until 26 Sep 2026).
const JUMP := 3.3
const AIR_STEER := 3.0  ## m/s² the keys nudge a jump's way and pace in the air (its take-off's run is kept: Greg, 27 Sep 2026)
## The third-person camera: its pivot over the head, the arm back and over the right shoulder, and the probe's radius.
const PIVOT := 1.55
const ARM := Vector3(0.45, 0.15, 2.6)
const PROBE := 0.22
## On stairs (chapter 11, 13.1; chapter 05: 0.6-0.9 s a step up for adults, 0.5 s down): treads a second, up and down,
## by the gait. Greg's verdict on the climbing pace (26 Sep 2026, 14:12: "a little slow, especially when going up
## stairs"): the walk 2 up, 2.6 down (they were 1.3 and 2.0). The jog took them half again faster until 14 Oct 2026 (3
## and 3.9, `STAIR_HURRY` 1.5): the town is mostly stairs, and there the run was barely faster than the walk (IMP-043).
## Now the jog takes 4 up and 5 down, one to a step, and the sprint 6 up and 7 down two to a stride, the feet on every
## other tread (characters/feet.gd sets each on the tread under it); at the jog the 1,080 steps take about 4.5 minutes.
const STAIR := {"walk": [2.0, 2.6], "back": [2.0, 2.6], "jog": [4.0, 5.0], "sprint": [6.0, 7.0]}
const STAIR_TWO := {"sprint": true}  ## the gaits that take two treads a stride
## Notched logs (chapter 11, 13.3): 0.75 m/s up or down since 14 Oct 2026 (IMP-043; it was 0.5); the Climb_Ladder clip
## climbs 0.34 m/s at its own pace, and ClimbUp_1m_RM, 0.67 s, steps over the parapet.
const CLIMB := 0.75
const CLIMB_RATE := CLIMB / 0.34
const CLIMB_UP := 0.667
## Never able to fall (chapter 12, M1's acceptance 5; sprint 4, step 1): the walk stops where the ground half a metre
## ahead lies more than this under the feet (a roof's edge over its parapet, a terrace wall, a lane's side, a bank
## steeper than the floor's 50 degrees, which the body slides down), sliding along the edge where it can. Stairs drop
## 0.4 m in half a metre.
const LEDGE := 0.6
## The highest step the walk takes: over a rich roof's parapet (R2, 0.5 m) onto the Rooftop Way's planks (it was 0.4 m).
const STEP_UP := 0.55
## Chapter 04, 10: a threshold is stepped over, never on: the sill's collision is a box a metre high (tibet-blender
## core.sill_box), and walking at it within 50 degrees of straight across carries the player over in 0.3 s.
const STEP_OVER := 0.3
## Ducking under a low lintel (chapter 04, 10: "at 1.70 m or less the player ducks automatically"; ISS-105, the poor
## house's door of 1.6 m): the capsule this high while ducked, a lintel lower than DUCK_AT over the way ahead ducked
## under, at this pace, the camera's pivot this low.
const DUCK_H := 1.3
const DUCK_AT := 1.72
const DUCK_SPEED := 0.9
const DUCK_PIVOT := 1.15

enum Rest { NONE, SITTING_DOWN, SEATED, STANDING_UP }

var views: Array = []  ## [feet, look-at] pairs in Blender coordinates
var cam: Camera3D
var outline_mat: ShaderMaterial
var ink_air := false  ## set before adding: M1's ink pass (world/ink.gd, art step A5) instead of the draft's outline
var third_person := false  ## set before adding: M1's player, a body seen from behind (V toggles the view)
var flying := false
var yaw := 0.0
var pitch := 0.0
var frozen := false  ## screenshot mode: the body neither moves nor falls
var walking := false  ## Option toggles it: the walk instead of the default jog (Greg, 10 Oct 2026, 11:00; Shift until 14 Oct)
var scripted := false  ## automated tests steer through scripted_move: macOS drops held keys when the window loses focus
var scripted_move := Vector3.ZERO  ## x = strafe, z = forward/back (-1 forward), y > 0.5 = the jog, y > 1.5 = the sprint

var body: Node3D  ## the visible body (third person), top-level, placed every frame at the interpolated capsule
var anim: AnimationPlayer
var woman := false
var view_first := false  ## in third person: V looks through the eyes instead
var facing := 0.0  ## the body's yaw, turning towards the way it goes
var arm_len := Vector2(ARM.y, ARM.z).length()  ## the arm back from the shoulder, shortened by walls
var _bodies := {}  ## "man"/"woman" -> [root, AnimationPlayer]
var _gaits := {}  ## "man"/"woman" -> {walk: [clip, m/s], run: [clip, m/s], sprint: [clip, m/s], back: [clip, m/s], idle: clip}
var _clip := ""
var _probe := SphereShape3D.new()
var rest := Rest.NONE
var rest_kind := ""  ## "chair" on a ledge, "kneel" on the ground, "cross" cross-legged in a Tibetan room (ISS-088)
var _cross_at := Vector3.ZERO  ## sitting cross-legged: where the body's root goes (the clip's hips are 0.4 m behind it)
var seat_height := 0.0  ## the ledge's height above the feet
var _rest_t := 0.0
var _pivot_h := PIVOT  ## the camera's pivot, lower when seated
var fight: Node  ## characters/fighting.gd: fists, then the sling (third person)
var stair := {}  ## the flight underfoot (third person): its ramp's steps in world space {toe, dir, rise, run, n}, or empty
var _stair_shape: Object = null
var _floor_n := Vector3.UP  ## the surface under the capsule's axis, from the same ray
var _body_dy := 0.0  ## the body's lag under the capsule after a step up, eased away so a ledge is stepped, not jumped
var ladder: Node3D = null  ## the notched log being climbed (world/town.gd's group "ladders"), or null
var ladder_h := 0.0  ## the climber's feet over the log's foot
var _lad := {}  ## the log's foot, top, parapet, way (level, towards the wall) and the height its climb ends at
var _lad_phase := ""  ## "mount", "climb", "dismount" (over the parapet onto the roof), "off" (at its foot)
var _lad_left: Node3D = null  ## the ladder last stepped off, and when (physics frames): not mounted again for 1.5 s
var _lad_left_frame := -1000000
var _lad_t := 0.0
var _lad_from := Vector3.ZERO
var _lad_mid := Vector3.ZERO
var _lad_to := Vector3.ZERO
var _lad_move := 0.0  ## -1, 0 or 1: down, still or up this tick
var _want_jump := false  ## Space pressed since the last physics tick
var _airborne := false  ## off the ground in a jump
var _jump_floor := 0.0  ## the height the jump left from: the air is kept over it (never able to fall)
var _land := 0.0  ## seconds of the landing clip left
var over := {}  ## a step over a threshold in progress: {from, to, top, t}; empty when none
var indoor := 0.0  ## 1 in a room (world/interiors.gd), eased over 0.4 s: the body's shader drops the sky's light
var cramped := false  ## the camera's arm had no room (a doorway, a small room): the view is at the eyes until it has
var _interiors: Node = null
var ducking := false  ## under a low lintel: the capsule lowered, the crouched walk (DUCK_H)
var talking := false  ## in a conversation (world/conversation.gd): standing, its keys the replies
var gait := "jog"  ## the pace this tick: "walk", "jog", "sprint", or "back" (backing away on S)
var heading := 0.0  ## the walker's way on the keys (World of Warcraft's): W goes along it, A and D turn it
var breath := BREATH  ## seconds of sprint left (IMP-043)
var winded := false  ## the breath ran out: no sprint until half of it is back
var puff := 0.0  ## how hard the walker breathes, 0 to 1: the panting's loudness and the vignette's darkness
var zoom := 1.0  ## the camera's arm, by the wheel (ZOOM_MIN to ZOOM_MAX of its length)
var orbiting := false  ## the left button held (the mouse free): dragging swings the camera round the walker
var steering := false  ## the right button held (the mouse free): the walker turns to the camera's way, A and D step aside
var fists := false  ## R: the fists up, the mouse taken for the fight (left punches, right guards)
var _freed := false  ## Esc freed the mouse from looking (first person, flying): a button held looks until it is let go
var _looked := false  ## the mouse looked last frame (`_looks`), so a new look takes it again
var _drag_from := Vector2.ZERO  ## where the cursor was when a button was pressed: it comes back there
var _wow := false  ## the keys drove the walker along `heading` this tick (World of Warcraft's way)
var _r2 := false  ## the controller's R2 past its dead zone (the sling's whirl)
var _sprint_k := 0.0
var _pant: AudioStreamPlayer  ## SND-603, the walker's breath when winded
var bare_feet := false  ## the boots off in a hall (world/boots.gd; M3 sprint 6, step 2): stockinged feet, soft steps
var _stoop := 0.0  ## seconds left stooped at a threshold (the boots off or on again): the walker still, crouched
var _vignette: TextureRect
var talk_at := Vector3.INF  ## the head of whoever the player talks with (world/conversation.gd), for the camera's two-shot
var sway_offset := Vector3.ZERO  ## the chain bridge's sway where the player stands on it (world/chain_bridge.gd): the camera
## takes it, the collider does not (chapter 11, 13)
var _talk_k := 0.0
var _cap: CapsuleShape3D
var _cs: CollisionShape3D
var _body_meshes: Array = []
## Third person: under this much free arm the view goes to the eyes, and back over CRAMPED + 0.5 m (sprint 7: in a
## doorway or a small room the camera sat in the player's shoulder).
const CRAMPED := 0.9
## The camera's framing (IMP-022; Greg's 1773, 1776, 1777 and 1779): running, the arm eases lower and shorter and the
## view a little wider, speed felt close behind; climbing a flight, it drops and tips up the stair, the walls rising
## either side (the slot stair of 1776); in a framing hint (data/camera_hints.json: a box in the town grid), it swings to
## the hint's side-on view along a gallery, most of the way, while the keys still move the walker as the mouse turned it
## (1779). H turns the framing off and on: Greg's to judge ("I don't know if that camera angle would make for good
## gameplay").
const RUN_ARM := Vector3(0.38, 0.0, 2.05)
const RUN_PIVOT := 1.4
const FOV := 68.0
const RUN_FOV := 74.0
## At the sprint (IMP-043) the arm a little further back and the view wider than the jog's, to sell the speed.
const SPRINT_ARM := Vector3(0.36, 0.05, 2.6)
const SPRINT_FOV := 82.0
const CLIMB_PIVOT := 1.2
const CLIMB_LOOK := 0.17  ## radians the view tips up a flight being climbed
const HINT_SWING := 0.85  ## how much of the way to a hint's view the camera turns
const HINTS := "res://data/camera_hints.json"
var framing := true
var outfit := {"man": 0, "woman": 0}  ## what each of the two wears (OUTFITS)
var dressing := false  ## at the chest (world/wardrobe.gd; dress()): the walker turning on the spot, the camera still
var view_k := 0.0  ## sat at a viewpoint (world/viewpoints.gd): how far the camera has drifted out to its frame, 0 to 1
var view_frame := Transform3D()
var view_fov := 50.0
var _view_shown := false  ## the body shown for the frame where the view had hidden it
var _dress_cam := Vector3.BACK  ## from the walker to the camera while dressing, level
var _dress_reach := 2.4
var _run_k := 0.0
var _climb_k := 0.0
var _hint_k := 0.0
var _hint := {}  ## the framing hint the camera last eased into
var _hints: Array = []


var save_key := "player"  ## its block in a save (autoload/save.gd)


func _ready() -> void:
	add_to_group("player")  # for the world's things that answer the walker (world/great_wheel.gd, world/mani_wall.gd)
	add_to_group("saved")
	var steps: Node = (load("res://player/steps.gd") as GDScript).new()  # the steps and the coat (sprint 8, step 4)
	steps.name = "Steps"
	add_child(steps)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	add_child(cs)
	_cap = cap
	_cs = cs
	cam = Camera3D.new()
	cam.position.y = EYE
	cam.fov = FOV
	cam.near = 0.05
	cam.far = 20000.0
	cam.top_level = true
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(cam)
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(50.0)
	if FileAccess.file_exists(HINTS):
		_hints = JSON.parse_string(FileAccess.get_file_as_string(HINTS))["hints"]
	_outline()
	heading = facing
	_vignette_setup()
	if third_person:
		_probe.radius = PROBE
		_make_bodies()


func _outline() -> void:
	if ink_air:
		outline_mat = Ink.attach(cam)
		return
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2, 2)
	q.mesh = qm
	q.extra_cull_margin = 16384.0
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline_mat = ShaderMaterial.new()
	outline_mat.shader = SHADER_OUTLINE
	outline_mat.set_shader_parameter("enabled", 1.0)  # set explicitly: an unset parameter reads back as null (ISS-010)
	q.material_override = outline_mat
	cam.add_child(q)


## The breath seen as it runs out (IMP-043): a faint darkening at the screen's edge, clear in the middle, over the world
## and under the pages; `puff` sets it (`_breath_shown`).
func _vignette_setup() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.5, 1.0])
	g.colors = PackedColorArray([Color(0.03, 0.02, 0.01, 0.0), Color(0.03, 0.02, 0.01, 1.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.1, 0.5)
	t.width = 256
	t.height = 256
	_vignette = TextureRect.new()
	_vignette.texture = t
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	layer.add_child(_vignette)


## The breath heard and seen by `puff`: the panting (SND-603, a loop, its stand-in synthesised: tools/audio/synth.py
## `breath`) louder and the vignette darker the harder the walker breathes; silent and clear when not.
func _breath_shown() -> void:
	if _vignette != null:
		_vignette.modulate.a = puff * VIGNETTE
	if puff <= 0.02:
		if _pant != null and _pant.playing:
			_pant.stop()
		return
	if _pant == null:
		var ad := get_node_or_null("/root/AudioDirector")
		var st: AudioStream = ad.call("stream", "SND-603") if ad != null else null
		if st == null:
			return
		_pant = AudioStreamPlayer.new()
		_pant.stream = st
		_pant.bus = "Foley"
		add_child(_pant)
	_pant.volume_db = linear_to_db(puff) + PANT_DB
	if not _pant.playing:
		_pant.play()


## Both bodies, built once; B shows the other. Each plays its own walk and run: the woman's clips where the rig has them.
func _make_bodies() -> void:
	for k in BODIES:
		_load_body(k, String(OUTFITS[k][outfit[k]][1]))
	_show_body()
	if not _bodies.is_empty():
		fight = Fighting.new()
		fight.fighter = self
		add_child(fight)
		for k in _bodies:
			_fight_loops(_bodies[k][1])


func _fight_loops(ap2: AnimationPlayer) -> void:
	for n in ["Fighting_Idle"]:
		if ap2.has_animation(n):
			ap2.get_animation(n).loop_mode = Animation.LOOP_LINEAR


## At the chest (world/wardrobe.gd) or done there: the camera set where the room has most room round the walker (a
## small room's walls would come between them as it went round), the walker turned to face it; dressing turns them.
func dress(on: bool) -> void:
	dressing = on
	if not on:
		return
	var origin := global_position
	var pv := origin + Vector3(0.0, 1.15, 0.0)
	var was := cam.global_position - origin
	was = Vector3(was.x, 0.0, was.z).normalized() if Vector2(was.x, was.z).length() > 0.1 else Vector3.BACK
	var best := -INF
	for i in 24:
		var a := TAU * i / 24.0
		var d := Vector3(sin(a), 0.0, cos(a))
		var free := 3.2 * _cast(pv, d * 3.2)
		var score := free + 0.3 * d.dot(was)  # among the free, the side the camera was on
		if score > best:
			best = score
			_dress_cam = d
			_dress_reach = clampf(free - 0.15, 0.9, 3.0)
	facing = atan2(-_dress_cam.x, -_dress_cam.z)


## Changes what the one now shown wears (OUTFITS; world/wardrobe.gd): its body for the outfit's, the same person
## dressed otherwise. True if changed.
func wear(i: int) -> bool:
	var k := "woman" if woman else "man"
	i = clampi(i, 0, (OUTFITS[k] as Array).size() - 1)
	if i == int(outfit[k]) and _bodies.has(k):
		return false
	var old: Array = _bodies.get(k, [])
	var was := int(outfit[k])
	outfit[k] = i
	if not _load_body(k, String(OUTFITS[k][i][1])):
		outfit[k] = was
		return false
	if not old.is_empty():
		(old[0] as Node).queue_free()
	_fight_loops(_bodies[k][1])
	_show_body()
	return true


## Loads a body for "man" or "woman" from `path`, its clips set to loop, its feet placed on the treads: _bodies[k].
func _load_body(k: String, path: String) -> bool:
	var clips = JSON.parse_string(FileAccess.get_file_as_string(CLIPS)) if FileAccess.file_exists(CLIPS) else null
	var mat := ShaderMaterial.new()
	mat.shader = PERSON
	if not ResourceLoader.exists(path) or clips == null:
		push_warning("player: %s or %s missing; run ../tibet-blender/people2/body.py" % [path, CLIPS])
		return false
	var root: Node3D = (load(path) as PackedScene).instantiate()
	root.top_level = true
	root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	PersonLook.apply(root, mat)  # the cloth by vertex colour, the face, hands and eyes painted
	var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
	var c: Dictionary = clips["bodies"]["player_" + k]
	var walk := "Walk_Female" if k == "woman" and c.has("Walk_Female") else "Walk"
	# both run with Run_Female, compact and smooth: the man's Jog leapt, its pelvis rising 24 cm a stride (Greg, 26 Sep
	# 2026, 14:12: "the way he runs is too bounding ... the womans running is much better")
	var run := "Run_Female" if c.has("Run_Female") else "Jog"
	var sprint := "Sprint" if c.has("Sprint") else run
	var back := "Walk_Backwards" if c.has("Walk_Backwards") else walk
	for name in [walk, run, sprint, back, "Idle_A", "Sitting_Idle", "Crouch_Idle", "Sitting_Cross", "Climb_Ladder", "Ladder_Idle"]:
		# (the ladder's two: played once, the climb had stopped after its 2 s and the body slid on up the log frozen;
		# Greg, 10 Oct 2026, ISS-178)
		var a := ap.get_animation(name)
		if a != null:
			a.loop_mode = Animation.LOOP_LINEAR
	_gaits[k] = {"idle": "Idle_A", "walk": [walk, float(c[walk]["speed"])], "run": [run, float(c[run]["speed"])],
			"sprint": [sprint, float(c[sprint]["speed"])], "back": [back, maxf(float(c[back]["speed"]), 0.3)],
			"duck": ["Crouch_Walk", float(c["Crouch_Walk"]["speed"]) if c.has("Crouch_Walk") else 0.55]}
	var cw := ap.get_animation("Crouch_Walk")
	if cw != null:
		cw.loop_mode = Animation.LOOP_LINEAR
	add_child(root)
	root.visible = false
	_bodies[k] = [root, ap]
	var sks := root.find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		var feet := Feet.new()
		feet.tread = tread_at
		feet.setup(sks[0] as Skeleton3D)
	return true


## The boots taken off at a hall's threshold, or put on again (world/boots.gd; chapter 04, 9 "Shoes"): stooped and still
## for `seconds`, the boots drawn as stockings while off (characters/person.gdshader `bare`), both bodies.
func boots_off(off: bool, seconds := 1.0) -> void:
	bare_feet = off
	_stoop = seconds
	for k in _bodies:
		for m in (_bodies[k][0] as Node).find_children("*", "GeometryInstance3D", true, false):
			(m as GeometryInstance3D).set_instance_shader_parameter("bare", 1.0 if off else 0.0)


## A blow or a stone landing on the player (characters/fighting.gd decides: turned by the guard, a stagger, a fall).
func take_hit(from: Vector3, head: bool, power := 1.0) -> bool:
	if fight == null:
		return false
	if rest != Rest.NONE:
		rest = Rest.NONE
		_rest_t = 0.0
	return fight.take_hit(from, head, power)


func _show_body() -> void:
	var k := "woman" if woman else "man"
	for b in _bodies:
		(_bodies[b][0] as Node3D).visible = b == k and not view_first
	if _bodies.has(k):
		body = _bodies[k][0]
		anim = _bodies[k][1]
		_clip = ""


func set_outline(on: bool) -> void:
	outline_mat.set_shader_parameter("enabled", 1.0 if on else 0.0)


func teleport(k: int) -> void:
	var v: Array = views[clampi(k, 0, views.size() - 1)]
	var pos: Vector3 = _b2g(v[0])
	var look: Vector3 = _b2g(v[1])
	global_position = pos
	velocity = Vector3.ZERO
	var d := (look - (pos + Vector3(0, EYE, 0))).normalized()
	yaw = atan2(-d.x, -d.z)
	pitch = asin(clampf(d.y, -1.0, 1.0))
	facing = yaw
	heading = yaw
	flying = k == 4
	reset_physics_interpolation()
	if not third_person:
		rotation.y = yaw
	_place_camera()


## The player's block in a save (chapter 11, 18.2): where, which way, how, who, in what; on a ladder its foot, seated
## where the seat is (a load stands there).
func save_state() -> Dictionary:
	var p := global_position
	if ladder != null and _lad.has("foot"):
		p = _lad["foot"]
	return {"at": [p.x, p.y, p.z], "facing": facing, "yaw": yaw, "pitch": pitch, "woman": woman,
			"outfit": [int(outfit["man"]), int(outfit["woman"])], "view_first": view_first,
			"posture": "ladder" if ladder != null else ("seated" if rest != Rest.NONE else "stand")}


## Back where a save had the player, standing (off any ladder or seat), in the body and the clothes it had.
func load_state(d: Dictionary) -> void:
	if ladder != null:
		_leave_ladder()
	rest = Rest.NONE
	_rest_t = 0.0
	over = {}
	_airborne = false
	ducking = false
	if _cap != null:
		_cap.height = 1.7
		_cs.position.y = 0.85
	var a: Array = d.get("at", [global_position.x, global_position.y, global_position.z])
	global_position = Vector3(float(a[0]), float(a[1]) + 0.05, float(a[2]))
	velocity = Vector3.ZERO
	facing = float(d.get("facing", facing))
	heading = facing
	yaw = float(d.get("yaw", yaw))
	pitch = float(d.get("pitch", pitch))
	if third_person:
		woman = bool(d.get("woman", woman))
		var o: Array = d.get("outfit", [outfit["man"], outfit["woman"]])
		for k in 2:
			var who := "man" if k == 0 else "woman"
			if int(o[k]) != int(outfit[who]):
				var was := woman
				woman = who == "woman"
				wear(int(o[k]))
				woman = was
		view_first = bool(d.get("view_first", view_first))
		_show_body()
	reset_physics_interpolation()
	if not third_person:
		rotation.y = yaw
	_place_camera()


static func _b2g(v: Vector3) -> Vector3:
	return Vector3(v.x, v.z, -v.y)


func _place_camera() -> void:
	_place_camera_base()
	if sway_offset != Vector3.ZERO:
		cam.global_position += sway_offset
	if view_k > 0.001:  # sat at a viewpoint (world/viewpoints.gd): drifted out to its composed frame, the walker in it
		cam.global_transform = cam.global_transform.interpolate_with(view_frame, view_k)
		cam.fov = lerpf(cam.fov, view_fov, view_k)
		if body != null and not body.visible:
			body.visible = true
			_view_shown = true
	elif _view_shown:
		_view_shown = false
		_show_body()


func _place_camera_base() -> void:
	var origin := get_global_transform_interpolated().origin
	RenderingServer.global_shader_parameter_set("g_player", origin)  # what the walker pushes through (world/laundry.gd)
	var dt := get_process_delta_time()
	var low := 1.05 if rest_kind == "chair" else (clampf(seat_height + 0.74, 0.7, 1.2) if rest_kind == "cross" else 0.95)
	_pivot_h = move_toward(_pivot_h, low if rest in [Rest.SITTING_DOWN, Rest.SEATED] else (DUCK_PIVOT if ducking else PIVOT), 1.2 * dt)
	if dressing and third_person and body != null:  # at the chest: the walker turning slowly on the spot, as 1771's figure on its mandala
		var turn := clampf(Input.get_axis("move_left", "move_right") + Controls.stick().x, -1.0, 1.0)  # A and D, or the left stick
		facing = wrapf(facing + dt * (0.3 if turn == 0.0 else 1.8 * turn), -PI, PI)
		# the whole walker in the frame, head to feet, and right of the middle, clear of the page down the left
		var fov := clampf(rad_to_deg(2.0 * atan(1.05 / _dress_reach)), 44.0, 72.0)
		var eye := origin + Vector3(0.0, 1.15, 0.0) + _dress_cam * _dress_reach
		var at := origin + Vector3(0.0, 0.92, 0.0)
		var vs := get_viewport().get_visible_rect().size
		var right := (at - eye).cross(Vector3.UP).normalized()
		at -= right * _dress_reach * 0.27 * tan(deg_to_rad(fov) * 0.5) * vs.x / maxf(vs.y, 1.0)
		cam.fov = fov
		cam.global_transform = Transform3D(Basis.looking_at(at - eye), eye)
		body.visible = true
		return
	if not third_person or view_first or cramped:
		var eye := EYE * _pivot_h / PIVOT
		cam.global_transform = Transform3D(Basis.from_euler(Vector3(pitch, yaw, 0.0)), origin + Vector3(0, eye, 0))
		cam.fov = FOV
		if cramped:  # back over the shoulder once the arm has room again (the way the framing would hold it)
			var fc := _framing(origin, dt)
			var bb := Basis.from_euler(Vector3(fc[2], fc[3], 0.0))
			var pv := origin + Vector3(0, _pivot_h - float(fc[1]), 0)
			var sd := bb.x * (fc[0] as Vector3).x
			var sh := pv + sd * _cast(pv, sd)
			var bk := bb * Vector3(0.0, (fc[0] as Vector3).y, (fc[0] as Vector3).z)
			if bk.length() * _cast(sh, bk) > CRAMPED + 0.5:
				cramped = false
				arm_len = CRAMPED + 0.5
			if body != null:
				body.visible = not cramped
		return
	# Over the shoulder: out to the right shoulder first, then back along the arm, each leg a sphere cast that stops at
	# walls, ceilings and the ground. Keeping the shoulder when the arm is short keeps the head off the frame's centre
	# in a narrow passage. The arm grows back slowly, so the camera does not pump in and out along a gallery's posts.
	var fr := _framing(origin, dt)  # [arm, pivot drop, pitch, yaw, fov]
	var arm: Vector3 = fr[0]
	cam.fov = fr[4]
	var b := Basis.from_euler(Vector3(fr[2], fr[3], 0.0))
	var pivot := origin + Vector3(0, _pivot_h - float(fr[1]), 0)
	var side := b.x * arm.x
	var shoulder := pivot + side * _cast(pivot, side)
	var back := b * Vector3(0.0, arm.y, arm.z)
	var free_len := back.length() * _cast(shoulder, back)
	if free_len < CRAMPED and rest == Rest.NONE and ladder == null:
		cramped = true
		arm_len = free_len
		if body != null:
			body.visible = false
		return
	arm_len = free_len if free_len < arm_len else move_toward(arm_len, free_len, 3.0 * dt)
	cam.global_transform = Transform3D(b, shoulder + back.normalized() * arm_len)
	# In a conversation, a two-shot over the right shoulder aimed at the speaker, far enough to the side that the player's
	# body does not hide them (ISS-135), eased in and out; the walls stop it as they stop the arm
	_talk_k = move_toward(_talk_k, 1.0 if talking and talk_at != Vector3.INF else 0.0, dt / 0.6)
	if _talk_k > 0.001 and talk_at != Vector3.INF:
		var to := Vector3(talk_at.x - origin.x, 0.0, talk_at.z - origin.z)
		if to.length() > 0.3:
			var dir := to.normalized()
			var head := origin + Vector3(0.0, _pivot_h, 0.0)
			var off := dir * -1.9 + dir.cross(Vector3.UP) * 1.1 + Vector3(0.0, 0.15, 0.0)
			var eye := head + off * _cast(head, off)
			var two := Transform3D(Basis.looking_at(talk_at - eye), eye)
			cam.global_transform = cam.global_transform.interpolate_with(two, smoothstep(0.0, 1.0, _talk_k))
	if body != null:
		body.visible = arm_len > 0.3 or (shoulder - pivot).length() > 0.3  # hide it when the camera is in its head


## The framing (IMP-022) eased by the minute's movement: [the arm, how far the pivot drops, the camera's pitch and yaw,
## its field of view]. The walker's own yaw and pitch stay the mouse's.
func _framing(origin: Vector3, dt: float) -> Array:
	var h := Vector2(velocity.x, velocity.z)
	var running := framing and is_on_floor() and stair.is_empty() and rest == Rest.NONE and h.length() > (WALK + RUN) * 0.5
	_run_k = move_toward(_run_k, 1.0 if running else 0.0, dt / (0.6 if running else 0.9))
	var sprinting := framing and gait == "sprint" and rest == Rest.NONE and ladder == null and h.length() > 1.0
	_sprint_k = move_toward(_sprint_k, 1.0 if sprinting else 0.0, dt / (0.8 if sprinting else 1.2))
	var climbing := false
	if framing and not stair.is_empty() and h.length() > 0.3:
		var sd: Vector3 = stair["dir"]
		climbing = h.normalized().dot(Vector2(sd.x, sd.z).normalized()) > 0.5
	_climb_k = move_toward(_climb_k, 1.0 if climbing else 0.0, dt / 1.0)
	var here := {}
	if framing:
		var tx := origin.x
		var ty := -origin.z
		var tz := origin.y + 2662.0  # world/town.gd's datum
		for hn in _hints:
			var c: Array = hn["center"]
			var sz: Array = hn["size"]
			if absf(tx - float(c[0])) <= float(sz[0]) / 2.0 and absf(ty - float(c[1])) <= float(sz[1]) / 2.0 and absf(tz - float(c[2])) <= float(sz[2]) / 2.0:
				here = hn
				break
	if not here.is_empty():
		_hint = here
	_hint_k = move_toward(_hint_k, 1.0 if not here.is_empty() else 0.0, dt / 1.0)
	var kr := smoothstep(0.0, 1.0, _run_k)
	var kc := smoothstep(0.0, 1.0, _climb_k)
	var kh := smoothstep(0.0, 1.0, _hint_k)
	var ks := smoothstep(0.0, 1.0, _sprint_k)
	var arm := ARM.lerp(RUN_ARM, kr).lerp(SPRINT_ARM, ks)
	arm.y *= zoom
	arm.z *= zoom
	var cam_yaw := yaw
	if kh > 0.0 and not _hint.is_empty():
		cam_yaw = lerp_angle(yaw, -deg_to_rad(float(_hint["view"])), kh * HINT_SWING)
		arm.z = lerpf(arm.z, float(_hint.get("arm", ARM.z)), kh)
	var drop := (PIVOT - RUN_PIVOT) * kr + (PIVOT - CLIMB_PIVOT) * kc
	return [arm, drop, clampf(pitch + CLIMB_LOOK * kc, -1.4, 1.2), cam_yaw, lerpf(lerpf(FOV, RUN_FOV, kr), SPRINT_FOV, ks)]


## The fraction of `motion` a probe sphere can travel from `from` before it touches anything but the player.
func _cast(from: Vector3, motion: Vector3) -> float:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _probe
	q.transform = Transform3D(Basis(), from)
	q.motion = motion
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.cast_motion(q)
	return hit[0] if hit.size() > 0 else 1.0


func _place_body(dt: float) -> void:
	if body == null:
		return
	_update_indoor(dt)
	var h := Vector2(velocity.x, velocity.z)
	var speed := h.length() if is_on_floor() or flying else 0.0
	var mark: Node = fight.nearest(3.0) if fight != null and fight.guard_up() else null
	if mark != null:  # fists up: square up to the nearest fighter, stepping round him rather than turning away
		var to: Vector3 = mark.fighter.global_position - global_position
		facing = wrapf(lerp_angle(facing, atan2(-to.x, -to.z), 1.0 - exp(-12.0 * dt)), -PI, PI)
	elif gait == "back" and _wow:  # backing away on S: still facing its way
		facing = wrapf(lerp_angle(facing, heading, 1.0 - exp(-12.0 * dt)), -PI, PI)
	elif speed > 0.2:
		facing = wrapf(lerp_angle(facing, atan2(-h.x, -h.y), 1.0 - exp(-10.0 * dt)), -PI, PI)
	elif _wow and rest == Rest.NONE and ladder == null:  # still: turned on the spot by A and D, or by the right button
		facing = wrapf(lerp_angle(facing, heading, 1.0 - exp(-12.0 * dt)), -PI, PI)
	var origin := get_global_transform_interpolated().origin
	var g: Dictionary = _gaits["woman" if woman else "man"]
	if rest != Rest.NONE:
		_place_resting(dt, origin, g)
		return
	if ladder != null:
		_place_climbing(origin)
		return
	# The rig faces +Z in Godot (-y in Blender), the way a camera looks backwards: turn it half round to face `facing`.
	_body_dy = move_toward(_body_dy * exp(-14.0 * dt), 0.0, 0.2 * dt)
	body.global_transform = Transform3D(Basis(Vector3.UP, facing + PI), origin + Vector3(0.0, _body_dy, 0.0))
	if fight != null:
		if fight.sling and not scripted:
			fight.aim_point = _aim_point()
		if fight.owns_clip():
			fight.drive(dt)
			return
		fight.drive(dt)  # its cool-downs
	var clip: String = "Fighting_Idle" if fight != null and fight.guard_up() and speed <= 0.2 else g["idle"]
	if _stoop > 0.0 and anim.has_animation("Crouch_Idle"):  # bent to the boots at a threshold
		clip = "Crouch_Idle"
	var rate := 1.0
	_land = maxf(_land - dt, 0.0)
	if _airborne and anim.has_animation("Jump_air"):
		clip = "Jump_air"
	elif _land > 0.0 and anim.has_animation("Jump_Land"):
		clip = "Jump_Land"
		rate = 1.4
	elif not stair.is_empty() and speed > 0.08:
		# On a flight: the gait's clip, one step to a tread at the walk and the jog, two at the sprint (each clip has two
		# steps); backing down or up a flight, the walk.
		var along := absf(Vector2(velocity.x, velocity.z).dot(Vector2(stair["dir"].x, stair["dir"].z)))
		var two := STAIR_TWO.has(gait)
		clip = g["sprint" if gait == "sprint" else ("run" if gait == "jog" else "walk")][0]
		var per_step := float(stair["run"]) * (2.0 if two else 1.0)
		rate = along / per_step * anim.get_animation(clip).length / 2.0 if anim.has_animation(clip) else 1.0
	elif ducking and anim.has_animation("Crouch_Walk"):  # under a low lintel
		clip = "Crouch_Walk" if speed > 0.1 else "Crouch_Idle"
		rate = speed / maxf(float(g["duck"][1]), 0.1) if speed > 0.1 else 1.0
	elif speed > 0.2 and gait == "back" and _wow:
		clip = g["back"][0]
		rate = speed / maxf(float(g["back"][1]), 0.1)
	elif speed > 0.2:
		var gk := "sprint" if speed > (RUN + SPRINT) * 0.5 else ("run" if speed > (WALK + RUN) * 0.5 else "walk")
		clip = g[gk][0]
		rate = speed / maxf(float(g[gk][1]), 0.1)
	if clip != _clip:
		anim.play(clip, 0.25)
		_clip = clip
	anim.speed_scale = rate


## On a notched log: facing it, the climb clip at the pace of the climb (backwards going down), the idle on it when
## still, the climb-up clip over the parapet (its root motion taken out: the capsule carries the body).
func _place_climbing(origin: Vector3) -> void:
	body.global_transform = Transform3D(Basis(Vector3.UP, facing + PI), origin)
	var clip := "Ladder_Idle"
	var rate := 1.0
	if _lad_phase == "dismount":
		clip = "ClimbUp_1m_RM"
	elif _lad_phase == "climb" and _lad_move != 0.0:
		clip = "Climb_Ladder"
		rate = CLIMB_RATE * _lad_move
	elif _lad_phase == "mount" or _lad_phase == "off":
		clip = "Climb_Ladder"
	if clip != _clip:
		anim.play(clip, 0.2)
		_clip = clip
	anim.speed_scale = rate


## Sitting down, seated, standing up: the clips in turn; on a ledge the body rises or sinks to its height (the clip's
## seat is about 0.45 m), easing in as it sits.
func _place_resting(dt: float, origin: Vector3, g: Dictionary) -> void:
	var chair := rest_kind == "chair"
	var cross := rest_kind == "cross"
	var clip: String
	match rest:
		Rest.SITTING_DOWN:
			clip = "Sitting_Enter" if chair else ("Sitting_Cross" if cross else "Crouch_Idle")
		Rest.SEATED:
			clip = "Sitting_Idle" if chair else ("Sitting_Cross" if cross else "Crouch_Idle")
		_:
			clip = "Sitting_Exit" if chair else g["idle"]
	if clip != _clip:
		anim.play(clip, 0.2)
		_clip = clip
	anim.speed_scale = 1.0
	_rest_t += dt
	var length := anim.get_animation(clip).length if anim.has_animation(clip) else 0.5
	if cross:  # down onto the bench or the floor and up again, the clip's pose eased in (it has no sitting-down)
		length = 0.6
	if rest == Rest.SITTING_DOWN and _rest_t >= (length if chair or cross else 0.4):
		rest = Rest.SEATED
		_rest_t = 0.0
	elif rest == Rest.STANDING_UP and _rest_t >= (length if chair or cross else 0.3):
		rest = Rest.NONE
		_rest_t = 0.0
	var lift := clampf(seat_height - 0.45, -0.1, 0.15) if chair else 0.0
	var k := 1.0
	if rest == Rest.SITTING_DOWN:
		k = clampf(_rest_t / maxf(length, 0.1), 0.0, 1.0)
	elif rest == Rest.STANDING_UP:
		k = 1.0 - clampf(_rest_t / maxf(length, 0.1), 0.0, 1.0)
	elif rest == Rest.NONE:  # stood up this frame
		k = 0.0
	if cross:
		body.global_transform = Transform3D(Basis(Vector3.UP, facing + PI), origin.lerp(_cross_at, k))
		return
	body.global_transform = Transform3D(Basis(Vector3.UP, facing + PI), origin + Vector3(0, lift * k, 0))


## Where the camera's centre points, up to 80 m off: the sling's aim.
func _aim_point() -> Vector3:
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 80.0
	var q := PhysicsRayQueryParameters3D.create(from, to, collision_mask, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return (hit["position"] as Vector3) if not hit.is_empty() else to


## Sit on a ledge 0.3-0.65 m high a step behind, or kneel; on a flight too, as the talkers sit on their steps (the
## capsule rides a flight's ramp, so it is not on the floor there).
func sit() -> void:
	if not third_person or flying or rest != Rest.NONE or not (is_on_floor() or not stair.is_empty()) or body == null or ladder != null:
		return
	var fwd := Vector3(-sin(facing), 0.0, -cos(facing))
	var at := global_position - fwd * 0.32
	var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 0.9, 0), at + Vector3(0, -0.1, 0), collision_mask, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	seat_height = (hit["position"] as Vector3).y - global_position.y if not hit.is_empty() else 0.0
	for g in get_tree().get_nodes_in_group("seat_rules"):  # a seat no guest sits on (the headman's: world/headman_house.gd),
		# at either of the probes the sit takes its seat from (a bench a little further back: 0.55 m)
		if not bool(g.call("may_sit", at, global_position - fwd * 0.55)):
			return
	rest_kind = "chair" if seat_height > 0.3 and seat_height < 0.65 else "kneel"
	# In a Tibetan room, cross-legged on its bench or its floor (ISS-088: "they sit as on a chair"); a Chinese room's chairs
	# and the town's steps and ledges are sat on as chairs
	var room: Node = _interiors.call("room_at", global_position + Vector3(0.0, 1.0, 0.0)) if _interiors != null else null
	if room != null and not String(room.get("room_id")).contains("chinese") and seat_height < 0.65 and anim != null \
			and anim.has_animation("Sitting_Cross"):
		rest_kind = "cross"
		if seat_height < 0.2:  # a bench a little further back than the first probe's 0.32 m
			var at2 := global_position - fwd * 0.55
			var q2 := PhysicsRayQueryParameters3D.create(at2 + Vector3(0, 0.9, 0), at2 + Vector3(0, -0.1, 0), collision_mask, [get_rid()])
			var hit2 := get_world_3d().direct_space_state.intersect_ray(q2)
			var h2 := (hit2["position"] as Vector3).y - global_position.y if not hit2.is_empty() else 0.0
			if h2 > 0.25 and h2 < 0.65:
				seat_height = h2
		if seat_height > 0.2:  # on the bench: the root at its front edge, so the hips are 0.4 m in
			var h := global_position + Vector3(0.0, seat_height - 0.04, 0.0)
			var e := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(h, h - fwd * 0.6, collision_mask, [get_rid()]))
			_cross_at = global_position - fwd * ((h - (e["position"] as Vector3)).length() if not e.is_empty() else 0.3)
		else:  # on the floor: the hips just behind where the feet stood
			seat_height = 0.0
			_cross_at = global_position + fwd * 0.32
		_cross_at.y = global_position.y + seat_height
	rest = Rest.SITTING_DOWN
	_rest_t = 0.0
	velocity = Vector3.ZERO


func stand() -> void:
	if rest == Rest.SEATED or rest == Rest.SITTING_DOWN:
		rest = Rest.STANDING_UP
		_rest_t = 0.0


## A notched log's foot and top (its LADDER sockets), the parapet's top it rests on, its way (level, towards the wall) and
## the height over its foot at which the climb ends and the step over the parapet begins.
func _lad_of(l: Node3D) -> Dictionary:
	var foot: Vector3 = (l.find_child("SOCK_LADDER_1", true, false) as Node3D).global_position
	var top: Vector3 = (l.find_child("SOCK_LADDER_2", true, false) as Node3D).global_position
	var parapet: Vector3 = l.get_meta("parapet")
	return {"foot": foot, "top": top, "parapet": parapet, "way": l.get_meta("way"), "end": maxf(parapet.y - foot.y - 0.35, 0.3)}


## The climber's feet on the log at `h` over its foot: along its axis, a little back from it.
func _lad_pos(h: float) -> Vector3:
	var foot: Vector3 = _lad["foot"]
	var top: Vector3 = _lad["top"]
	return foot + (top - foot) * (h / maxf(top.y - foot.y, 0.1)) - (_lad["way"] as Vector3) * 0.28


## Walking into a log's foot, or up to its top from the roof, mounts it.
func _try_ladder(dir: Vector3) -> void:
	for l in get_tree().get_nodes_in_group("ladders"):
		# just stepped off it at its foot: walking on past the foot does not put the walker back on it (at its top, walking
		# back to it is meant: off a door's landing a moment after climbing onto it; IMP-019)
		var recent: bool = l == _lad_left and Engine.get_physics_frames() - _lad_left_frame < int(1.5 * Engine.physics_ticks_per_second)
		var d := _lad_of(l)
		var way: Vector3 = d["way"]
		var to_foot: Vector3 = (d["foot"] as Vector3) - global_position
		var edge: Vector3 = (d["parapet"] as Vector3) + way * 1.0  # on the roof, over the log's top
		var to_edge: Vector3 = edge - global_position
		var from_top := Vector2(to_edge.x, to_edge.z).length() < 0.9 and to_edge.y > -0.2 and to_edge.y < 0.9 and dir.dot(-way) > 0.5
		if from_top or (not recent and Vector2(to_foot.x, to_foot.z).length() < 0.9 and absf(to_foot.y) < 0.7 and dir.dot(way) > 0.5):
			ladder = l
			_lad = d
			ladder_h = float(d["end"]) if from_top else 0.0
			_lad_phase = "mount"
			_lad_t = 0.0
			_lad_from = global_position
			_lad_to = _lad_pos(ladder_h)
			velocity = Vector3.ZERO
			stair = {}
			return


## One physics tick on a log: the mount, the climb (W up, S down), the step over the parapet, the step off at its foot.
func _ladder_physics(dt: float, iz: float) -> void:
	var way: Vector3 = _lad["way"]
	facing = atan2(-way.x, -way.z)
	_lad_t += dt
	_lad_move = 0.0
	match _lad_phase:
		"mount":
			global_position = _lad_from.lerp(_lad_to, smoothstep(0.0, 0.3, _lad_t))
			if _lad_t >= 0.3:
				_lad_phase = "climb"
		"climb":
			var h0 := ladder_h
			ladder_h = clampf(ladder_h - iz * CLIMB * dt, 0.0, float(_lad["end"]))
			_lad_move = signf(ladder_h - h0)
			global_position = _lad_pos(ladder_h)
			if ladder_h >= float(_lad["end"]) - 0.001 and iz < -0.5:
				# Over the parapet onto the roof a metre inside it: up to the parapet's top, then over and down.
				var over: Vector3 = (_lad["parapet"] as Vector3) + way * 1.0
				var q := PhysicsRayQueryParameters3D.create(over + Vector3(0, 1.5, 0), over + Vector3(0, -3.0, 0), collision_mask, [get_rid()])
				var hit := get_world_3d().direct_space_state.intersect_ray(q)
				_lad_from = global_position
				_lad_mid = (_lad["parapet"] as Vector3) + way * 0.25 + Vector3(0, 0.08, 0)
				_lad_to = (hit["position"] as Vector3) if not hit.is_empty() else over
				_lad_phase = "dismount"
				_lad_t = 0.0
				anim.root_motion_track = NodePath("Armature/Skeleton3D:root")
			elif ladder_h <= 0.001 and iz > 0.5:
				_lad_from = global_position
				_lad_to = (_lad["foot"] as Vector3) - way * 0.75 + Vector3(0, 0.05, 0)
				_lad_phase = "off"
				_lad_t = 0.0
		"dismount":
			var k := _lad_t / CLIMB_UP
			global_position = _lad_from.lerp(_lad_mid, smoothstep(0.0, 0.55, k)) if k < 0.55 else _lad_mid.lerp(_lad_to, smoothstep(0.55, 1.0, k))
			if k >= 1.0:
				_leave_ladder()
		"off":
			global_position = _lad_from.lerp(_lad_to, smoothstep(0.0, 0.3, _lad_t))
			if _lad_t >= 0.3:
				_leave_ladder()
	velocity = Vector3.ZERO


## The walk turned along a drop's edge, or stopped at it: the first of the way ahead and a turn of 35 degrees either
## side with ground under it within LEDGE, at the speed that heads that way (turns of 70 degrees had led a walker along
## a rim it then slipped from).
## In a room or not (world/interiors.gd), eased: the body's shader takes the sky's light away indoors.
func _update_indoor(dt: float) -> void:
	if _interiors == null:
		_interiors = get_tree().get_first_node_in_group("interiors")
		if _interiors == null:
			return
	var target := 1.0 if _interiors.call("room_at", global_position + Vector3(0.0, 1.0, 0.0)) != null else 0.0
	if target == indoor:
		return
	indoor = move_toward(indoor, target, dt / 0.4)
	if _body_meshes.is_empty():
		for k in _bodies:
			_body_meshes.append_array((_bodies[k][0] as Node).find_children("*", "MeshInstance3D", true, false))
	for mi in _body_meshes:
		(mi as MeshInstance3D).set_instance_shader_parameter("indoor", indoor)


## A threshold before the player, walked at nearly straight across (world/town.gd's markers in the group "sills"):
## start carrying the player over it, from where they stand to as far beyond it, down onto the floor there.
func _try_sill(dir: Vector3) -> bool:
	for node in get_tree().get_nodes_in_group("sills"):
		var mk := node as Node3D
		var n := -mk.global_basis.z
		n.y = 0.0
		n = n.normalized()
		var t := Vector3(-n.z, 0.0, n.x)
		var d := global_position - mk.global_position
		var s := d.dot(n)
		var u := d.dot(t)
		var hd := float(mk.get_meta("d", 0.2)) / 2.0
		if absf(u) > float(mk.get_meta("w", 1.0)) / 2.0 - 0.2 or absf(s) < hd or absf(s) > hd + 0.9 or absf(d.y) > 0.6:
			continue
		var across := -signf(s) * n
		if dir.dot(across) < 0.64:  # within 50 degrees of straight across
			continue
		var far := mk.global_position + across * (hd + 0.42) + t * u
		var q := PhysicsRayQueryParameters3D.create(far + Vector3(0.0, 1.5, 0.0), far - Vector3(0.0, 1.5, 0.0), collision_mask, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			continue
		far.y = (hit["position"] as Vector3).y
		over = {"from": global_position, "to": far, "top": mk.global_position.y + float(mk.get_meta("h", 0.3)) + 0.06, "t": 0.0}
		if not ducking and not _room_at(get_world_3d().direct_space_state, far):  # a low doorway beyond its sill (the headman's
			ducking = true  # stable, 1.5 m over a 30 cm sill: M2 sprint 7): ducked from the first step, and through it
			_cap.height = DUCK_H
			_cs.position.y = _cap.height / 2.0
		return true
	return false


## The step over (chapter 04, 10): along a short arc whose middle clears the sill, then down on the far side.
func _step_over(dt: float) -> void:
	var a: Vector3 = over["from"]
	var b: Vector3 = over["to"]
	var k := minf(float(over["t"]) + dt / STEP_OVER, 1.0)
	over["t"] = k
	var p := a.lerp(b, k)
	if not ducking:  # ducked under a low lintel the body keeps low and only the feet go over (the capsule would meet it)
		p.y += maxf(float(over["top"]) - (a.y + b.y) / 2.0, 0.0) * sin(PI * k)
	velocity = Vector3(b.x - a.x, 0.0, b.z - a.z) / STEP_OVER  # the body walks on through it
	global_position = p
	if k >= 1.0:
		over = {}
		velocity = Vector3(velocity.x, 0.0, velocity.z)


func _ledge_guard() -> void:
	var v := Vector3(velocity.x, 0.0, velocity.z)
	var speed := v.length()
	if speed < 0.01:
		return
	var space := get_world_3d().direct_space_state
	for a in [0.0, 0.6, -0.6]:
		var d := v.rotated(Vector3.UP, a) / speed
		var ahead := global_position + d * 0.5
		var q := PhysicsRayQueryParameters3D.create(ahead + Vector3(0, 0.6, 0), ahead + Vector3(0, -LEDGE, 0), collision_mask, [get_rid()])
		if not space.intersect_ray(q).is_empty():
			if a != 0.0:
				velocity.x = d.x * speed * cos(a)
				velocity.z = d.z * speed * cos(a)
			return
	velocity.x = 0.0
	velocity.z = 0.0


## In a jump, never carried off a drop: where the ground ahead lies more than LEDGE under the height the jump left from,
## the jump goes straight up and comes down where it began.
func _air_guard() -> void:
	var v := Vector3(velocity.x, 0.0, velocity.z)
	if v.length() < 0.01:
		return
	var ahead := global_position + v * 0.15
	var q := PhysicsRayQueryParameters3D.create(ahead + Vector3(0.0, 0.3, 0.0), Vector3(ahead.x, _jump_floor - LEDGE, ahead.z), collision_mask, [get_rid()])
	if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		velocity.x = 0.0
		velocity.z = 0.0


func _leave_ladder() -> void:
	_lad_left = ladder
	_lad_left_frame = Engine.get_physics_frames()
	ladder = null
	_lad_phase = ""
	velocity = Vector3.ZERO
	if anim != null:
		anim.root_motion_track = NodePath()


## The tread's height under a point (world space) on the flight underfoot, or NAN off a flight (characters/feet.gd):
## tread k runs from the k-th nosing to the next, and the nosings stand a run apart from the ramp's toe.
func tread_at(p: Vector3) -> float:
	if stair.is_empty():
		return NAN
	var d := (p - (stair["toe"] as Vector3)).dot(stair["dir"])
	return (stair["toe"] as Vector3).y + clampf(floorf(d / float(stair["run"])), 0.0, float(stair["n"])) * float(stair["rise"])


## Ducking (DUCK_H): under a lintel at the head's height just ahead with the way open at the chest and the knee beneath
## it (a doorway; a window's wall stands under it), the capsule lowered so it passes; up again only where a standing
## capsule has room.
func _duck(dir: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	var p := global_position
	var low := false
	if dir.length() > 0.1:
		low = _ray(space, p + Vector3(0.0, DUCK_AT - 0.03, 0.0), dir * 0.75) and not _ray(space, p + Vector3(0.0, 1.0, 0.0), dir * 0.75) \
				and not _ray(space, p + Vector3(0.0, 0.45, 0.0), dir * 0.75)
	var want := low or (ducking and not _room_to_stand(space))
	if want == ducking:
		return
	ducking = want
	_cap.height = DUCK_H if want else 1.7
	_cs.position.y = _cap.height / 2.0


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, by: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, from + by)
	q.exclude = [get_rid()]
	return not space.intersect_ray(q).is_empty()


func _room_to_stand(space: PhysicsDirectSpaceState3D) -> bool:
	return _room_at(space, global_position)


## Whether a standing capsule has room with its feet at `at`.
func _room_at(space: PhysicsDirectSpaceState3D, at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.28
	c.height = 1.65
	q.shape = c
	q.transform = Transform3D(Basis(), at + Vector3(0.0, 0.9, 0.0))
	q.exclude = [get_rid()]
	return space.intersect_shape(q, 1).is_empty()


## The flight underfoot: a short ray down the capsule's axis; a ramp's shape carries its steps (addons/dungkardo_import).
func _find_stair() -> void:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.4, 0), global_position + Vector3(0, -0.35, 0), collision_mask, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var shape: Object = null
	_floor_n = (hit["normal"] as Vector3) if not hit.is_empty() else Vector3.UP
	if not hit.is_empty() and hit["collider"] is CollisionObject3D:
		var co: CollisionObject3D = hit["collider"]
		shape = co.shape_owner_get_owner(co.shape_find_owner(int(hit["shape"])))
	if shape == _stair_shape:
		return
	_stair_shape = shape
	stair = _stair_of(shape)


## A flight's steps in world space {toe, dir, rise, run, n} from its ramp's shape (addons/dungkardo_import's meta), or
## empty if the shape is no flight's.
static func _stair_of(shape: Object) -> Dictionary:
	if not (shape is Node3D and (shape as Node3D).has_meta("stair")):
		return {}
	var m: Dictionary = (shape as Node3D).get_meta("stair")
	var t := (shape as Node3D).global_transform
	var dir: Vector3 = t.basis * (m["dir"] as Vector3)
	dir.y = 0.0
	return {"toe": t * (m["toe"] as Vector3), "dir": dir.normalized(), "rise": float(m["rise"]), "run": float(m["run"]), "n": int(m["n"])}


## The flight the walker is about to step onto, or empty: a ray down 0.7 m ahead. At the jog and the sprint its pace is
## taken a step early, so a run across a landing does not sail off the next flight's first treads (S15 at the jog, down
## from the Sky Stair's top: the feet 0.7 m over the flight's line; IMP-043).
func _flight_ahead(dir: Vector3) -> Dictionary:
	var at := global_position + dir * 0.7
	var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 0.6, 0), at + Vector3(0, -1.0, 0), collision_mask, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or not (hit["collider"] is CollisionObject3D):
		return {}
	var co: CollisionObject3D = hit["collider"]
	return _stair_of(co.shape_owner_get_owner(co.shape_find_owner(int(hit["shape"]))))


func _process(dt: float) -> void:
	_controls_frame(dt)
	_place_camera()
	if third_person:
		_place_body(dt)
	_breath_shown()


## Once a rendered frame: the right stick turns the camera (Controls.look: its dead zone, its curve, a little
## acceleration), a mouse button let go while the window was away is let go here, and the mouse is taken or freed as the
## mode wants (`_update_mouse`).
func _controls_frame(dt: float) -> void:
	if scripted or frozen:
		return
	var lk: Vector2 = Controls.look(dt)
	if lk != Vector2.ZERO and not dressing:
		yaw = wrapf(yaw - lk.x, -PI, PI)
		pitch = clampf(pitch - lk.y, -1.4, 1.4 if not third_person or view_first else 1.0)
		if not third_person:
			rotation.y = yaw
	if (orbiting and not Input.is_action_pressed("orbit")) or (steering and not Input.is_action_pressed("steer")):
		_drag(orbiting and Input.is_action_pressed("orbit"), steering and Input.is_action_pressed("steer"))
	_update_mouse()


## Whether the mouse looks with no button held: first person, flying, the fists up or the sling out.
func _looks() -> bool:
	return not third_person or view_first or flying or _fight_mouse()


## Whether the mouse's buttons are the fight's: the fists up (R) or the sling out on the keys (G), on the feet.
func _fight_mouse() -> bool:
	return third_person and fight != null and (fists or (fight.sling and not Controls.pad)) and rest == Rest.NONE \
			and not flying and not view_first and ladder == null


## The mouse taken (hidden, each motion turning the view) while the mode looks with it or a button is held, free
## otherwise. Never in the automated runs (`scripted`), the frozen stills or headless.
func _update_mouse() -> void:
	if scripted or frozen or DisplayServer.get_name() == "headless":
		return
	var looks := _looks()
	if looks and not _looked:
		_freed = false  # a new look takes the mouse again
	_looked = looks
	var want := Input.MOUSE_MODE_CAPTURED if (looks and not _freed) or orbiting or steering else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want:
		Input.mouse_mode = want


## The mouse's two buttons held or not (`o` the left, `s` the right; the mouse free): while either is, the cursor hides
## and the mouse turns the camera, the right turning the walker with it; let go, the cursor comes back where it was.
func _drag(o: bool, s: bool) -> void:
	var was := orbiting or steering
	if s and not steering:
		heading = yaw  # the walker turns to the camera's way at once
	orbiting = o
	steering = s
	var now := orbiting or steering
	if now and not was:
		_drag_from = get_viewport().get_mouse_position()
	_update_mouse()
	if was and not now and not scripted and not _looks() and DisplayServer.get_name() != "headless":
		get_viewport().warp_mouse(_drag_from)


func _mouse_button(e: InputEventMouseButton) -> void:
	if scripted or frozen:
		return
	if e.is_action("zoom_in") or e.is_action("zoom_out"):
		if e.pressed and third_person and not view_first:
			zoom = clampf(zoom * (ZOOM_STEP if e.is_action("zoom_in") else 1.0 / ZOOM_STEP), ZOOM_MIN, ZOOM_MAX)
		return
	if _fight_mouse():  # the fists up: the left button punches, the right guards; the sling out: the left whirls and looses
		if e.is_action("orbit"):
			if e.pressed:
				if fight.sling:
					fight.start_whirl()
				else:
					fight.strike()
			elif fight.sling:
				fight.release()
		elif e.is_action("steer"):
			fight.guard = e.pressed
		return
	if e.is_action("orbit") or e.is_action("steer"):
		_drag(e.pressed if e.is_action("orbit") else orbiting, e.pressed if e.is_action("steer") else steering)


func _mouse_moved(e: InputEventMouseMotion) -> void:
	if scripted or frozen:
		return
	if not (orbiting or steering or (_looks() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)):
		return
	yaw = wrapf(yaw - e.relative.x * MOUSE_TURN, -PI, PI)
	pitch = clampf(pitch - e.relative.y * MOUSE_TURN, -1.4, 1.4 if not third_person or view_first else 1.0)
	if steering:
		heading = yaw
	if not third_person:
		rotation.y = yaw


## Esc: the fists lowered and the sling put away; looking with the mouse (first person, flying), the mouse freed.
func _lower() -> void:
	if fists or (fight != null and fight.sling and not Controls.pad):
		fists = false
		if fight != null:
			fight.guard = false
			if not fight.owns_clip():
				fight.sling = false
	elif _looks():
		_freed = true
	_update_mouse()


## A punch (R1 on the controller; the left button with the fists up): the sling, if out, put away first.
func _strike() -> void:
	if fight == null or not third_person or rest != Rest.NONE or flying or view_first or ladder != null:
		return
	if fight.sling and not fight.owns_clip():
		fight.sling = false
	fight.strike()


## The controller's R2 (`whirl`): pressed past its dead zone, the sling out and whirling; let go, the stone loosed.
func _trigger(on: bool) -> void:
	if on == _r2:
		return
	_r2 = on
	if fight == null or not third_person or rest != Rest.NONE or flying or view_first or ladder != null:
		return
	if on:
		if not fight.sling and not fight.owns_clip():
			fight.sling = true
			fists = false
		fight.start_whirl()
	else:
		fight.release()


## B (or square at the chest): the other of the two, the man or the woman.
func other_body() -> void:
	if third_person and rest == Rest.NONE:
		woman = not woman
		_show_body()
		if dressing:
			get_tree().call_group("wardrobe", "shown")


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_mouse_moved(e as InputEventMouseMotion)
		return
	if e is InputEventMouseButton:
		_mouse_button(e as InputEventMouseButton)
		return
	if e is InputEventJoypadMotion:
		if e.is_action("whirl"):
			_trigger(e.is_action_pressed("whirl"))
		return
	if e.is_action("guard") and fight != null and third_person and not e.is_echo():  # L1 held: the guard up
		fight.guard = e.is_pressed() and rest == Rest.NONE and not flying and ladder == null
	if not e.is_pressed() or e.is_echo():
		return
	if e.is_action_pressed("back") and e is InputEventKey:
		_lower()
	if e.is_action_pressed("fly"):
		flying = not flying
	if e.is_action_pressed("walk"):
		walking = not walking
	if e.is_action_pressed("ink"):
		set_outline(float(outline_mat.get_shader_parameter("enabled")) < 0.5)
	if not talking and not dressing:
		for k in mini(views.size(), 10):
			if e.is_action_pressed("viewpoint_%d" % (k + 1)):
				teleport(k)
	if (e.is_action_pressed("hour_back") or e.is_action_pressed("hour_on")) and not WorldClock.frozen:
		WorldClock.minute += -60.0 if e.is_action_pressed("hour_back") else 60.0  # an hour back or on
	if e.is_action_pressed("view") and third_person:
		view_first = not view_first
		pitch = minf(pitch, 1.0)
		_show_body()
	if e.is_action_pressed("body"):
		other_body()
	if e.is_action_pressed("sit") and not dressing and not Controls.any_page():
		if rest == Rest.NONE:
			sit()
		else:
			stand()
	if e.is_action_pressed("sling") and fight != null and not fight.owns_clip():
		fight.sling = not fight.sling
		fists = false
		fight.guard = false
	if e.is_action_pressed("fists") and fight != null and rest == Rest.NONE and third_person:  # (at tea, seated, R is enough)
		fists = not fists
		fight.guard = false
		if fists and fight.sling and not fight.owns_clip():
			fight.sling = false
	if e.is_action_pressed("framing"):  # the camera's framing (IMP-022), for Greg to judge
		framing = not framing
	if e.is_action_pressed("strike"):
		_strike()
	if e.is_action_pressed("jump") and not talking and not dressing:
		if fight != null and fight.guard_up() and third_person and rest == Rest.NONE and not flying:
			var side := Input.get_axis("move_left", "move_right") + Controls.stick().x
			fight.dodge("left" if side < -0.3 else ("right" if side > 0.3 else "back"))
		else:
			_want_jump = true
	_update_mouse()


## The breath (IMP-043): spent a second a second at the sprint, back BREATH_JOG a second at the jog and BREATH_EASY
## walking or still; run out, the walker is winded until half of it is back. `puff` eases towards how hard it breathes.
func _breathe(dt: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	if gait == "sprint" and moving:
		breath = maxf(breath - dt, 0.0)
		winded = winded or breath <= 0.0
	else:
		breath = minf(breath + dt * (BREATH_JOG if gait == "jog" and moving else BREATH_EASY), BREATH)
	if winded and breath >= BREATH * 0.5:
		winded = false
	var want := 1.0 if winded else (clampf(1.0 - breath / (BREATH * 0.35), 0.0, 1.0) if gait == "sprint" and moving else 0.0)
	puff = move_toward(puff, want, dt / (0.8 if want > puff else 2.5))


func _physics_process(dt: float) -> void:
	if frozen:
		return
	if not scripted:
		# Watch time pass at 60:1 while seated (chapter 11, 15.1), or while T is held.
		WorldClock.rate = WorldClock.RATE_WATCH if Input.is_action_pressed("watch") or rest == Rest.SEATED else WorldClock.RATE_PLAY
	# What moves the walker: sideways (ix) and back (+iz) or forward (-iz), from the camera's way (the controller, the
	# mouse looking, the scripted runs) or from the walker's own on the keys (`_wow`, World of Warcraft's: A and D turn it
	# unless the right button is held)
	var ix := 0.0
	var iz := 0.0
	var turn := 0.0
	var g := "jog"
	_wow = false
	if scripted:
		ix = scripted_move.x
		iz = scripted_move.z
		g = "sprint" if scripted_move.y > 1.5 else ("jog" if scripted_move.y > 0.5 else "walk")
	else:
		var st: Vector2 = Controls.stick()
		if st != Vector2.ZERO:  # the controller, GTA's way: the way it is pushed, from the camera; a light tilt walks
			ix = st.x
			iz = st.y
			g = "walk" if st.length() < WALK_TILT else "jog"
		else:
			ix = Input.get_axis("move_left", "move_right")
			iz = Input.get_axis("move_forward", "move_back")
			if orbiting and steering:  # both buttons: on along the way
				iz = -1.0
			g = "walk" if walking else "jog"
			_wow = third_person and not flying and not _looks()
			if _wow and not steering:
				turn = ix
				ix = 0.0
		if Input.is_action_pressed("sprint") and (ix != 0.0 or iz != 0.0) and not (_wow and iz > 0.0):
			g = "sprint"
		elif _wow and iz > 0.0 and ix == 0.0:
			g = "back"  # backing away on S, still facing the way
	if g == "sprint" and winded:
		g = "jog"
	var fast := Input.is_action_pressed("sprint") or (scripted and scripted_move.y > 0.5)  # (flying)
	if rest != Rest.NONE:
		if rest == Rest.SEATED and (ix != 0.0 or iz != 0.0 or turn != 0.0):
			stand()  # a step stands up
		ix = 0.0
		iz = 0.0
		turn = 0.0
	if dressing or talking or _stoop > 0.0:  # the chest's keys are its own (world/wardrobe.gd), a conversation's
		ix = 0.0  # (world/conversation.gd); stooped at a threshold, the boots off or on (world/boots.gd)
		iz = 0.0
		turn = 0.0
		g = "walk"
	_stoop = maxf(_stoop - dt, 0.0)
	gait = g
	_breathe(dt)
	# The walker's way on the keys: turned by A and D, the camera turned with it unless the left button holds it, and
	# eased back behind it as it goes; otherwise the camera's (the mouse looking) or the body's own.
	if _wow:
		if turn != 0.0 and ladder == null and over.is_empty():
			heading = wrapf(heading - turn * TURN * dt, -PI, PI)
			if not orbiting:
				yaw = wrapf(yaw - turn * TURN * dt, -PI, PI)
		if (ix != 0.0 or iz != 0.0 or turn != 0.0) and not orbiting and not steering:
			yaw = lerp_angle(yaw, heading, 1.0 - exp(-FOLLOW * dt))
	elif not scripted and _looks():
		heading = yaw
	else:
		heading = facing
	if rest != Rest.NONE or ladder != null or dressing or talking or (fight != null and (fight.owns_clip() or fight.guard_up())):
		heading = facing  # turned by its seat, its log, the chest, a talk or a fight: the way is the body's again
	if ladder != null:
		_ladder_physics(dt, iz)
		return
	if not over.is_empty():
		_step_over(dt)
		return
	if flying:
		var b := cam.global_transform.basis
		var v := b.x * ix + b.z * iz
		v.y += Input.get_action_strength("fly_up") - Input.get_action_strength("fly_down")
		if v.length() > 0.0:
			global_position += v.normalized() * (30.0 if fast else 9.0) * dt
		if third_person:  # the body faces the way it flies
			velocity = v.normalized() * (30.0 if fast else 9.0) if v.length() > 0.0 else Vector3.ZERO
		return
	# On the keys the walker goes along its own way; otherwise third person walks where the camera looks, first person
	# where the body faces, which the mouse turns.
	var pb := Basis(Vector3.UP, heading) if _wow else (Basis(Vector3.UP, yaw) if third_person else global_transform.basis)
	var dir := pb.x * ix + pb.z * iz
	dir.y = 0.0
	dir = dir.normalized()
	if third_person and rest == Rest.NONE and dir.length() > 0.1 and is_on_floor():
		_try_ladder(dir)
		if ladder != null:
			return
	# a sill on a flight's landing too (a town house's door at the top of its outside stair; sprint 8, step 7): the
	# sill's own tests (within 0.9 m, at the feet's height, walked at nearly straight across) keep it to doorways
	if rest == Rest.NONE and dir.length() > 0.1 and is_on_floor() and _try_sill(dir):
		return
	var speed: float = RUN
	match gait:
		"walk":
			speed = WALK if third_person else 2.5  # (first person's walk was 2.5 m/s, its run 6, until the run was the default)
		"back":
			speed = BACK
		"sprint":
			speed = SPRINT
	if fight != null:
		speed *= fight.move_scale()
	if rest == Rest.NONE and is_on_floor():
		_duck(dir)
	if ducking:
		speed = minf(speed, DUCK_SPEED)
	if _airborne and not is_on_floor():
		# In a jump the run carries on: the take-off's way and pace, which the keys only nudge; let go, it keeps going
		# (until 27 Sep 2026 the keys set it afresh every frame, and a jump with the keys let go stopped dead in the air)
		var steer := Vector2(velocity.x, velocity.z)
		if dir.length() > 0.1:
			steer = steer.move_toward(Vector2(dir.x, dir.z) * speed, AIR_STEER * dt)
		velocity.x = steer.x
		velocity.z = steer.y
	else:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	if fight != null:
		var lv: Vector3 = fight.lunge_velocity()
		if lv != Vector3.ZERO:
			velocity.x = lv.x
			velocity.z = lv.z
	# On a flight the pace is counted in treads: the speed along it is treads a second, by the gait (STAIR), times the
	# run; at the jog and the sprint the next flight's a step before it.
	var flight := stair
	if flight.is_empty() and gait in ["jog", "sprint"] and dir.length() > 0.1 and is_on_floor() and not _airborne:
		flight = _flight_ahead(dir)
	if not flight.is_empty():
		var along := Vector2(velocity.x, velocity.z).dot(Vector2(flight["dir"].x, flight["dir"].z))
		var per: Array = STAIR.get(gait, STAIR["jog"])
		var cap: float = float(per[0] if along > 0.0 else per[1]) * float(flight["run"])
		if absf(along) > cap:
			velocity.x *= cap / absf(along)
			velocity.z *= cap / absf(along)
	if not stair.is_empty():
		# Along the ramp, pressed a little into it: the slide projected a level walk into the slope and lost a quarter
		# of it, and a walk exactly along it left the ramp for a frame and fell back.
		velocity.y = -(_floor_n.x * velocity.x + _floor_n.z * velocity.z) / maxf(_floor_n.y, 0.2)
		velocity -= _floor_n * 0.1  # square into the ramp, so the slide takes it all back and none of the pace
	elif is_on_floor():
		if _want_jump and rest == Rest.NONE and (fight == null or not fight.owns_clip()):
			velocity.y = JUMP
			_airborne = true
			_jump_floor = global_position.y
	else:
		velocity.y -= 9.8 * dt
		if _airborne:
			_air_guard()
	_want_jump = false
	if is_on_floor() and stair.is_empty() and velocity.y <= 0.0:
		_ledge_guard()
	var before := global_position
	move_and_slide()
	if _airborne and is_on_floor() and velocity.y <= 0.0:
		_airborne = false
		_land = 0.3
	if dir.length() > 0.1 and is_on_wall() and stair.is_empty():
		# The draft's step-up hack (ISS-005): lift STEP_UP and try again when a step stops the body. Never on a flight:
		# pressed against its cheek walls it lifted the player onto them (S15 on the stair's outer lines).
		var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()
		if moved < speed * dt * 0.5:
			# up to the step's own top, the highest of three rays down onto it just past the capsule's front (STEP_UP
			# where none answers): a fixed STEP_UP had lifted the walker 0.55 m off a 17 cm lip at the Sky Stair's top
			# and sailed it over the first treads at the jog (S15, 14 Oct 2026; IMP-043)
			var lift := -1.0
			for reach in [0.3, 0.36, 0.44]:
				var ahead := global_position + dir * float(reach)
				var q := PhysicsRayQueryParameters3D.create(ahead + Vector3(0, STEP_UP + 0.05, 0), ahead + Vector3(0, 0.02, 0), collision_mask, [get_rid()])
				var top := get_world_3d().direct_space_state.intersect_ray(q)
				if not top.is_empty():
					lift = maxf(lift, (top["position"] as Vector3).y - global_position.y + 0.03)
			lift = clampf(lift, 0.05, STEP_UP) if lift > 0.0 else STEP_UP
			var t := global_transform
			t.origin += Vector3(0, lift, 0)
			# over the step, and along a wall's end beside it where one stands at the capsule's side (the Sky Stair's
			# cheek wall at its top, by the outer line: the fixed STEP_UP had stepped onto it); where that does not go
			# (ground rising on past the step, as on the Rooftop Way's earth by point 41), the draft's fixed STEP_UP ahead
			var way := dir
			var kc := KinematicCollision3D.new()
			if test_move(t, way * 0.35, kc) and kc.get_normal().y < 0.5:
				var n := kc.get_normal()
				n.y = 0.0
				if n.length() > 0.1 and absf(n.normalized().dot(dir)) < 0.75:
					n = n.normalized()
					way = (dir - n * dir.dot(n)).normalized()
			for tr in [[lift, way], [STEP_UP, dir]]:
				var up: float = tr[0]
				var go: Vector3 = tr[1]
				var t2 := global_transform
				t2.origin += Vector3(0, up, 0)
				if not test_move(global_transform, Vector3(0, up, 0)) and not test_move(t2, go * 0.35):
					global_position += Vector3(0, up, 0) + go * speed * dt
					_body_dy -= up  # the body lags and steps up after the capsule
					break
	if third_person:
		_find_stair()
	if global_position.y < -50.0 and not views.is_empty():
		teleport(0)
