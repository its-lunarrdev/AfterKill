extends Control

@onready var level_1_btn: Button = $MainVBox/LevelList/Level1Button
@onready var level_2_btn: Button = $MainVBox/LevelList/Level2Button
@onready var quit_btn: Button = $MainVBox/BottomBar/HBox/QuitButton

const WORLD_SCENE := "res://Scenes/World.tscn"

func _ready() -> void:
	level_1_btn.pressed.connect(_on_level_1_pressed)
	level_2_btn.pressed.connect(_on_level_2_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_level_2_pressed() -> void:
	# Coming soon - could load another level scene later
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
