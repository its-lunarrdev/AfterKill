extends Label

var time_elapsed: float = 0.0
var running: bool = true

const SAVE_PATH := "user://all_times.save"

func _ready():
	update_display()

func _process(delta):
	if running:
		time_elapsed += delta
		update_display()

func update_display():
	text = get_formatted_time()

func get_time_elapsed() -> float:
	return time_elapsed

func get_formatted_time() -> String:
	var minutes := int(time_elapsed / 60)
	var seconds := int(time_elapsed) % 60
	var milliseconds := int((time_elapsed - int(time_elapsed)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func stop_timer() -> void:
	running = false

func get_record_time() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return "—"
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return "—"
	var lines = file.get_as_text().split("\n", false)
	file.close()
	if lines.is_empty():
		return "—"
	var best_seconds := INF
	for line in lines:
		line = line.strip_edges()
		if line.is_empty():
			continue
		var parts = line.split(":", false)
		if parts.size() >= 2:
			var mins = int(parts[0])
			var sec_ms = parts[1].split(".", false)
			var secs = int(sec_ms[0]) if sec_ms.size() > 0 else 0
			var ms = int(sec_ms[1]) if sec_ms.size() > 1 else 0
			var total = mins * 60.0 + secs + ms / 100.0
			if total < best_seconds:
				best_seconds = total
	if best_seconds == INF:
		return "—"
	var m := int(best_seconds / 60)
	var s := int(best_seconds) % 60
	var ms := int((best_seconds - int(best_seconds)) * 100)
	return "%02d:%02d.%02d" % [m, s, ms]

func _unhandled_input(event):
	if event.is_action_pressed("reset_times"):
		reset_time()


func save_time():
	var times := []
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			times = file.get_as_text().split("\n", false)
			file.close()
	var minutes := int(time_elapsed / 60)
	var seconds := int(time_elapsed) % 60
	var milliseconds := int((time_elapsed - int(time_elapsed)) * 100)
	var formatted_time = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
	times.append(formatted_time)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(times))
		file.close()


func reset_time():
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			var err = dir.remove(SAVE_PATH.get_file())
			if err != OK:
				push_error("Failed to remove save file")
	time_elapsed = 0.0
	update_display()
	print("Timer reset and save file cleared!")


func print_final_time():
	var minutes := int(time_elapsed / 60)
	var seconds := int(time_elapsed) % 60
	var milliseconds := int((time_elapsed - int(time_elapsed)) * 100)
	print("Final Time: %02d:%02d.%02d" % [minutes, seconds, milliseconds])


func print_all_times():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No saved times found.")
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var times = file.get_as_text().split("\n", false)
		print("All Saved Times:")
		for t in times:
			print("  " + t)
		file.close()
