extends Node
## The town's work heard (plan chapter 10, the 2xx sounds; M1 sprint 8, step 4): a worker's tool sounds from the worker
## while the worker is at the work: Pasang's chisel in the mani stones (SND-208) while he sits at his pitch in his
## carving hours (08:00-15:55, data/named_days.json), in runs of taps with a pause between (to look, blow off the dust,
## set the chisel again); the dice thrown by the pieman in Dechen-tsang's Yard 1 (SND-303). Its own dice; quiet while TownSim's walkers are off. Added by world/town.gd.

## a walker's key: [sound, the states it works in (TownSim: 3 sitting, 5 crouching), its hours [from, to] in minutes,
## the gap between taps [min, max] s, taps in a run [min, max], the pause after a run [min, max] s, the tool's height]
const WORK := {
	"pasang_carver": ["SND-208", [3, 5], [480.0, 955.0], [0.28, 0.55], [4, 14], [2.0, 7.0], 0.45],
	# the dice in Dechen-tsang's Yard 1 by the pieman (M2 sprint 8, step 3; SND-303): a throw now and then, a pause while
	# the stake is paid and the cup goes round
	"dice_player": ["SND-303", [5], [580.0, 755.0], [1.6, 2.4], [1, 2], [5.0, 12.0], 0.25],
	"dice_player_b": ["SND-303", [5], [610.0, 850.0], [1.6, 2.4], [1, 2], [6.0, 14.0], 0.25],
}

var workers: Array = []  ## [walker index, its key]
var taps := 0  ## for the tests
var _next := {}  ## walker -> seconds to its next tap
var _left := {}  ## walker -> taps left in its run
var _dice := RandomNumberGenerator.new()  ## its own, never the global stream


## Whether a job's worker is at it: in one of its states, within its hours.
static func at_work(job: Array, state: int, minute: float) -> bool:
	return (job[1] as Array).has(state) and minute >= float(job[2][0]) and minute <= float(job[2][1])


func _process(dt: float) -> void:
	if not TownSim.walkers_on:
		return
	if workers.is_empty():
		for i in TownSim.count:
			if WORK.has(TownSim.who[i]):  # by its own name: the dice players wear others' bodies
				workers.append([i, TownSim.who[i]])
		if workers.is_empty():
			set_process(false)
			return
	var m := fposmod(WorldClock.minute, 1440.0)
	for w in workers:
		var i: int = w[0]
		var job: Array = WORK[w[1]]
		if not at_work(job, int(TownSim.state[i]), m):
			_left[i] = 0
			continue
		_next[i] = float(_next.get(i, 0.0)) - dt
		if float(_next[i]) > 0.0:
			continue
		if int(_left.get(i, 0)) <= 0:
			_left[i] = _dice.randi_range(int(job[4][0]), int(job[4][1]))
		_left[i] = int(_left[i]) - 1
		taps += 1
		AudioDirector.play(String(job[0]), TownSim.pos[i] + Vector3(0.0, float(job[6]), 0.0))
		_next[i] = _dice.randf_range(float(job[3][0]), float(job[3][1])) if int(_left[i]) > 0 else _dice.randf_range(float(job[5][0]), float(job[5][1]))
