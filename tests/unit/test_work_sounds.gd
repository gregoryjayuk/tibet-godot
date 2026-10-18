extends GutTest
## The town's work heard (world/work_sounds.gd; M1 sprint 8, step 4): Pasang's chisel only while he sits at his pitch in
## his carving hours, and each work's sound a record of data/sound.json.

const WorkSounds := preload("res://world/work_sounds.gd")


func test_the_carver_at_his_work() -> void:
	var job: Array = WorkSounds.WORK["pasang_carver"]
	assert_true(WorkSounds.at_work(job, 3, 10.0 * 60.0), "sitting at 10:00: carving")
	assert_false(WorkSounds.at_work(job, 0, 10.0 * 60.0), "walking: not")
	assert_false(WorkSounds.at_work(job, 3, 7.0 * 60.0), "before 08:00: not")
	assert_false(WorkSounds.at_work(job, 3, 16.5 * 60.0), "after 15:55: not")


func test_every_work_a_record() -> void:
	var sounds: Dictionary = AudioDirector.data.get("sounds", {})
	for k in WorkSounds.WORK:
		assert_true(sounds.has(String(WorkSounds.WORK[k][0])), "%s's sound is in data/sound.json" % k)
