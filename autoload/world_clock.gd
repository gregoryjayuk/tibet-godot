extends Node
## WorldClock (plan chapter 11, 3.1, 7.3 and 15.1). It owns the animation clock behind the `g_time` shader global
## (every animated shader reads g_time instead of TIME, so screenshot mode can freeze it at a known phase) and the
## game time: minutes of local mean time from 00:00 on 21 October 1903, which the Calendar turns into dates and the
## sun and moon (spike S13). Named cues (the conch at 05:00, the horns…) and the day's light come with art step A7.

const DEFAULT_MINUTE := 10920.0  ## 14:00 on the default day, Wednesday 28 October 1903 (chapter 12's first slice)

var anim_time := 0.0  ## seconds of animation time
var minute := DEFAULT_MINUTE  ## game minutes from 00:00 on 21 October 1903, local mean time at the site
const RATE_PLAY := 0.1  ## game minutes per real second: 6:1, one game hour in ten real minutes (chapter 11, 15.1)
const RATE_WATCH := 1.0  ## 60:1, "watch": how a player waits for dusk without a menu (15.1)
var rate := RATE_PLAY
var frozen := false


func freeze(at_seconds: float, at_minute: float = DEFAULT_MINUTE) -> void:
	frozen = true
	anim_time = at_seconds
	minute = at_minute
	_push()


func _process(dt: float) -> void:
	if not frozen:
		anim_time += dt
		minute += dt * rate
	_push()


func _push() -> void:
	RenderingServer.global_shader_parameter_set("g_time", anim_time)
