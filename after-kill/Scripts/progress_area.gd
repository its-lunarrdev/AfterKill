extends Area3D

@export var target: Node3D
@export var move_speed := 30.0
@export var move_height := 50.0

@onready var sfx_door_open: AudioStreamPlayer3D = $"../../SFX_DoorOpen"

var initial_y: float
var enemy_count := 0
var is_moving := false
var has_played_sfx := false

func _ready():
	initial_y = target.global_position.y
	monitoring = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		enemy_count += 1
		print("Enemy entered, count:", enemy_count)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		enemy_count = max(enemy_count - 1, 0)
		print("Enemy exited, count:", enemy_count)

		if enemy_count == 0:
			is_moving = true

func _physics_process(delta: float) -> void:
	if is_moving:
		move_target_up(delta)

func move_target_up(delta: float) -> void:
	if not has_played_sfx:
		sfx_door_open.play()
		has_played_sfx = true

	var pos := target.global_position
	var target_y := initial_y + move_height

	pos.y = move_toward(pos.y, target_y, move_speed * delta)
	target.global_position = pos

	# Stop once we reach the target
	if is_equal_approx(pos.y, target_y):
		is_moving = false
