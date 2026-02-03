extends Area3D

@export var target: Node3D
@export var move_speed := 30.0
@export var move_height := 50.0

var initial_y: float
var enemy_count := 0
var should_move := false

func _ready():
	initial_y = target.global_position.y
	monitoring = true

	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node):
	if body.is_in_group("Enemy"): 
		enemy_count += 1
		print("Enemy entered, count:", enemy_count)

func _on_body_exited(body: Node):
	if body.is_in_group("Enemy"):
		enemy_count -= 1
		print("Enemy exited, count:", enemy_count)
		if enemy_count <= 0:
			should_move = true

func _physics_process(delta: float) -> void:
	if should_move:
		move_target_up(delta)

func move_target_up(delta: float) -> void:
	var pos := target.global_position
	var target_y := initial_y + move_height
	pos.y = move_toward(pos.y, target_y, move_speed * delta)
	target.global_position = pos
