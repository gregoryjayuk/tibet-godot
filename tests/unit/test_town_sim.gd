extends GutTest
## TownSim's walkers on their days (M1 sprint 6, step 1; chapter 05, 7.2; IMP-017): a day is places to be at by clock
## times, each departure worked back from its arrival by the route's time at the clock's 6:1, and where anyone is at the
## clock's minute is looked up. A made-up street file: a walker at home (x = 0) until 10:00, to stand at an errand 10 m
## east from 10:10 to 10:40, up a flight of ten steps (2 m) to be indoors there from 11:40, home again by 13:40.

const Town := preload("res://world/town.gd")
const PATH := "user://test_streets.json"

var keep := {}


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true
	var level := [0.0, 0.0, 2662.0, 5.0, 0.0, 2662.0, 10.0, 0.0, 2662.0]
	var data := {"pace": 1.1, "up": 0.75, "down": 0.5, "rate": 0.1,
		"anchors": {"h": [0.0, 0.0, 2662.0], "a": [10.0, 0.0, 2662.0], "b": [12.0, 0.0, 2664.0]},
		"walkers": [
			{"kind": "villager_man", "pace": 1.0, "up": 0.8, "down": 0.5, "home": "h",
				"day": [["h", 0, 600, "inside", 0], ["a", 610, 640, "stand", 0], ["b", 700, 800, "inside", 0], ["h", 820, 1440, "inside", 0]]},
			{"kind": "monk", "pace": 1.0, "up": 0.8, "down": 0.5, "home": "h",  # an arrival it cannot make: it slips
				"day": [["h", 0, 600, "inside", 0], ["a", 600.2, 640, "stand", 0], ["h", 700, 1440, "inside", 0]]}],
		"routes": {
			"h>a": {"p": level, "k": [0, 0], "n": [0, 0]},
			"a>h": {"p": [10.0, 0.0, 2662.0, 5.0, 0.0, 2662.0, 0.0, 0.0, 2662.0], "k": [0, 0], "n": [0, 0]},
			"a>b": {"p": [10.0, 0.0, 2662.0, 12.0, 0.0, 2664.0], "k": [1], "n": [10]},
			"b>h": {"p": [12.0, 0.0, 2664.0, 10.0, 0.0, 2662.0, 0.0, 0.0, 2662.0], "k": [1, 0], "n": [10, 0]},
		}}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	TownSim.setup_walkers(PATH, ["monk", "villager_man"])


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]


## The clock at minute m of the default day, and everyone looked up.
func _at(m: float) -> void:
	WorldClock.minute = 7.0 * 1440.0 + m
	TownSim.step(0.0, Vector3.ZERO)


func _near(i: int, x: float, y: float, z: float) -> float:
	return TownSim.pos[i].distance_to(Town.to_godot(x, y, z))


func test_the_day() -> void:
	assert_eq(int(TownSim.kind[0]), 1, "drawn as its kind")
	_at(599.0)
	assert_eq(int(TownSim.state[0]), 2, "at home, indoors, until it sets off")
	_at(609.5)  # 10 m at 1 m/s is 10 s, a game minute at 6:1: it left at 10:09 to be there at 10:10
	assert_eq(int(TownSim.state[0]), 0, "walking")
	assert_almost_eq(_near(0, 5.0, 0.0, 2662.0), 0.0, 0.01, "halfway at its pace")
	assert_almost_eq(TownSim.cur_speed[0], 1.0, 0.01, "at 1 m/s on the screen")
	_at(620.0)
	assert_eq(int(TownSim.state[0]), 1, "standing at the errand")
	assert_almost_eq(_near(0, 10.0, 0.0, 2662.0), 0.0, 0.01, "at the errand")
	_at(650.0)
	assert_eq(int(TownSim.state[0]), 1, "past its leave: it waits to set off for an arrival at 11:40")
	_at(699.6)  # ten steps up at 0.8 s is 8 s, 0.8 game minutes: it left at 11:39.2
	assert_eq(int(TownSim.state[0]), 0, "on the flight")
	assert_almost_eq(_near(0, 11.0, 0.0, 2663.0), 0.0, 0.01, "half way up")
	_at(750.0)
	assert_eq(int(TownSim.state[0]), 2, "indoors at the second place")
	_at(818.75)  # down: five steps' 2.5 s of 5, then 10 m in 10 s; it left at 13:38.5 to be home at 13:40
	assert_almost_eq(_near(0, 11.0, 0.0, 2663.0), 0.0, 0.01, "half way down")
	_at(900.0)
	assert_eq(int(TownSim.state[0]), 2, "home for the night")
	assert_almost_eq(_near(0, 0.0, 0.0, 2662.0), 0.0, 0.01, "at home")
	_at(1439.9)
	assert_eq(int(TownSim.state[0]), 2, "still, at midnight, and the day begins again")


func test_a_late_start_slips() -> void:
	assert_eq(TownSim.slipped, 1, "one arrival later than its schedule")
	_at(600.5)
	assert_eq(int(TownSim.state[1]), 0, "it left on leaving home, at 10:00, and is on its way")
	_at(601.05)
	assert_eq(int(TownSim.state[1]), 1, "arrived a minute after it left, not at 10:00.2")


func test_the_busiest_minute() -> void:
	var m: float = TownSim.busiest_time(Town.to_godot(10.0, 0.0, 2662.0), 0.5, 600.0, 700.0, 1.0)
	assert_between(m, 610.0, 699.0, "a minute the walkers stand at the errand")
	assert_eq(TownSim.out_at(900.0), 0, "at 15:00 both are indoors")
