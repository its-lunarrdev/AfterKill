extends Area3D

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if triggered:
		return
	if not body.is_in_group("Player"):
		return
	triggered = true

	var world := get_tree().current_scene
	var stopwatch: Node = world.get_node_or_null("UI/Stopwatch")
	var end_screen: Node = world.get_node_or_null("EndScreen")
	if not stopwatch or not end_screen:
		return

	var sw := stopwatch
	sw.stop_timer()
	sw.save_time()

	var current_str: String = sw.get_formatted_time()
	var record_str: String = sw.get_record_time()
	end_screen.show_end_screen(current_str, record_str)
