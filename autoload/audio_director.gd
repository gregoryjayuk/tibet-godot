extends Node
## The game's sound (plan chapter 10, 13.1; chapter 11, 16's one AudioDirector; M1 sprint 8, step 1). Its children do
## the jobs: Sound (autoload/audio/sound.gd: voices from pools by priority, the delay of distance and the ridge's echo,
## the ritual schedule, looping sources kept virtual out of range) and Ambience (autoload/audio/ambience.gd: the district
## beds by district and hour, the wind by height, the market's murmur by how many stand near, held low indoors). Every
## sound is a record of data/sound.json (tools/audio/sound_data.py), its files under res://audio/ with their credits in
## audio/CREDITS.csv (tools/audio/process.py). The buses are res://default_bus_layout.tres (tools/audio/make_buses.gd).

const DATA := "res://data/sound.json"
const AUDIO := "res://audio/"

var data := {}
var sound: Node
var ambience: Node
## The sound's own dice, never the global stream: the scenes' seeded builders draw from that (main.gd's grass and monks
## after its seed(1903), which the draft's reference shots compare), and a bed started or a step played in between moved
## every blade (27 Sep 2026). Godot's AudioStreamRandomizer draws from the global stream too, so it is not used.
var rng := RandomNumberGenerator.new()
var _files := {}  ## id -> [AudioStream or null], its files loaded, in the record's order
var _offsets := {}  ## source -> {bus: dB}: the mix's snapshots (a viewpoint settling, a moment's reveal), summed on each bus
var _base_db := {}  ## bus -> its own level, read the first time a source moves it
var _last := {}  ## id -> the file played last
var _missing := {}


## Sets `source`'s offset on `bus` (dB; 0 lifts it): a bus stands at its own level plus every source's offset, so two
## snapshots at once (sat at a viewpoint, coming out of the Gate Chorten) add instead of fighting (chapter 10's snapshots).
func set_offset(source: String, bus: String, db: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	if not _base_db.has(bus):
		_base_db[bus] = AudioServer.get_bus_volume_db(i)
	if not _offsets.has(source):
		_offsets[source] = {}
	(_offsets[source] as Dictionary)[bus] = db
	var sum := 0.0
	for s in _offsets:
		sum += float((_offsets[s] as Dictionary).get(bus, 0.0))
	AudioServer.set_bus_volume_db(i, float(_base_db[bus]) + sum)


## The offset `source` holds on `bus` (the tests').
func offset(source: String, bus: String) -> float:
	return float((_offsets.get(source, {}) as Dictionary).get(bus, 0.0))


func _ready() -> void:
	rng.seed = 1903
	if FileAccess.file_exists(DATA):
		data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	# loaded, not preloaded: compiling this autoload must not pull in scripts that name the other autoloads (a tool run
	# with --script compiles its own script's dependencies before any autoload exists, and the loop blinded it to all)
	sound = (load("res://autoload/audio/sound.gd") as GDScript).new()
	sound.name = "Sound"
	add_child(sound)
	ambience = (load("res://autoload/audio/ambience.gd") as GDScript).new()
	ambience.name = "Ambience"
	add_child(ambience)


## A record's files, loaded once and kept in its order (a variant is an index); one not built is null, with a warning
## once (tools/audio/synth.py, process.py).
func _loaded(id: String) -> Array:
	if _files.has(id):
		return _files[id]
	var rec: Dictionary = (data.get("sounds", {}) as Dictionary).get(id, {})
	var got: Array = []
	for f in rec.get("files", []):
		var path := AUDIO + String(f)
		if ResourceLoader.exists(path):
			got.append(load(path))
		else:
			got.append(null)
			if not _missing.has(path):
				_missing[path] = true
				push_warning("AudioDirector: %s is not built (tools/audio/synth.py and process.py)" % path)
	_files[id] = got
	return got


## Which of a record's files plays next: one at random, never the one played last when it has more than two (13.8).
func pick(id: String) -> int:
	var n := _loaded(id).size()
	if n <= 1:
		return 0
	var k := rng.randi_range(0, n - 1)
	if n > 2 and k == int(_last.get(id, -1)):
		k = (k + rng.randi_range(1, n - 1)) % n
	_last[id] = k
	return k


## A record's stream: its file `variant`, or with -1 the one `pick` draws. Null when it is not built.
func stream(id: String, variant := -1) -> AudioStream:
	var got := _loaded(id)
	var k := variant if variant >= 0 else pick(id)
	return got[k] as AudioStream if k < got.size() else null


## One playing's spread, [pitch scale, dB], from the record's `vary` (semitones and dB either way) about its `pitch`:
## footsteps and blows a little different each time, never voices.
func vary(id: String) -> Vector2:
	var rec: Dictionary = (data.get("sounds", {}) as Dictionary).get(id, {})
	var base := float(rec.get("pitch", 1.0))  # a record's own pitch (the great wheel's groan: a ladder's creaks, lower)
	var v: Array = rec.get("vary", [])
	if v.size() < 2:
		return Vector2(base, 0.0)
	return Vector2(base * pow(2.0, rng.randf_range(-float(v[0]), float(v[0])) / 12.0), rng.randf_range(-float(v[1]), float(v[1])))


## A sound heard flat, not placed: the interface's (the codex's pages), on its record's bus.
var _ui: AudioStreamPlayer


func play_ui(id: String) -> void:
	if _ui == null:
		_ui = AudioStreamPlayer.new()
		_ui.max_polyphony = 3
		add_child(_ui)
	var s := stream(id)
	if s == null:
		return
	var vy := vary(id)
	_ui.stream = s
	_ui.pitch_scale = vy.x
	_ui.volume_db = vy.y
	_ui.bus = StringName(((data.get("sounds", {}) as Dictionary).get(id, {}) as Dictionary).get("bus", "UI"))
	_ui.play()


## Every sound in the game goes through here (13.1): the record `id` at `pos`, caused at `cause` (the Sound's clock;
## -1 now), its `variant` (-1 any). Returns the voice, or null when the sound is delayed by its distance or has none.
func play(id: String, pos: Vector3, cause := -1.0, variant := -1) -> Node:
	return sound.play(id, pos, cause, variant)
