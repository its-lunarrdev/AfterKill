extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var record_label: Label = $Overlay/Center/VBox/RecordLabel
@onready var time_label: Label = $Overlay/Center/VBox/TimeLabel
@onready var restart_btn: Button = $Overlay/Center/VBox/RestartButton
@onready var menu_btn: Button = $Overlay/Center/VBox/MenuButton

const MAIN_MENU_SCENE := "res://Scenes/MainMenu.tscn"

func _ready() -> void:
	visible = false
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func show_end_screen(current_time: String, record_time: String) -> void:
	if record_label:
		record_label.text = "Overall record: %s" % record_time
	if time_label:
		time_label.text = "Current time: %s" % current_time
	visible = true
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
