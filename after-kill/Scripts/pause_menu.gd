extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var card: PanelContainer = $Overlay/Center/Card
@onready var resume_btn: Button = $Overlay/Center/Card/Margin/VBox/ResumeButton
@onready var restart_btn: Button = $Overlay/Center/Card/Margin/VBox/RestartButton
@onready var menu_btn: Button = $Overlay/Center/Card/Margin/VBox/MenuButton
@onready var quit_btn: Button = $Overlay/Center/Card/Margin/VBox/QuitButton
@onready var sfx_button: AudioStreamPlayer = $SFX_Button

var _animating := false

const MAIN_MENU_SCENE := "res://Scenes/MainMenu.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _is_end_screen_visible():
		return
	if _animating:
		return
	_toggle_pause()

func _toggle_pause() -> void:
	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()

func _pause_game() -> void:
	get_tree().paused = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_in()

func _resume_game() -> void:
	sfx_button.play()
	await get_tree().create_timer(0.15).timeout
	_animate_out()

func _on_resume_pressed() -> void:
	sfx_button.play()
	_resume_game()

func _on_restart_pressed() -> void:
	sfx_button.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_menu_pressed() -> void:
	sfx_button.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_quit_pressed() -> void:
	sfx_button.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _is_end_screen_visible() -> bool:
	var end_screen := get_node_or_null("../EndScreen")
	if end_screen and end_screen is CanvasLayer:
		return end_screen.visible
	return false

func _animate_in() -> void:
	_animating = true
	overlay.modulate.a = 0.0
	card.modulate.a = 0.0
	card.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		_animating = false
	)

func _animate_out() -> void:
	_animating = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(card, "scale", Vector2(0.98, 0.98), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(card, "modulate:a", 0.0, 0.12)
	tween.parallel().tween_property(overlay, "modulate:a", 0.0, 0.12)
	tween.finished.connect(func():
		visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_animating = false
	)
