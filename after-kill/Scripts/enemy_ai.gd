extends CharacterBody3D

@export var speed := 15.0
@export var gravity := 9.8
@export var attack_range := 2.0
@export var damage := 10

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var detection_area: Area3D = $DetectionArea
@onready var mesh := $EnemyMesh
@onready var mat: StandardMaterial3D = mesh.get_active_material(0)

var player: Node3D
var state := IDLE

enum {
	IDLE,
	CHASE,
	ATTACK
}

func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	if mat:
		mesh.set_surface_override_material(0, mat.duplicate())
		mat = mesh.get_surface_override_material(0)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	match state:
		IDLE:
			velocity.x = 0
			velocity.z = 0

		CHASE:
			chase_player(delta)

		ATTACK:
			attack_player()

	move_and_slide()

func chase_player(delta):
	if player == null:
		state = IDLE
		return

	nav_agent.target_position = player.global_position
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))

	if global_position.distance_to(player.global_position) <= attack_range:
		state = ATTACK

func attack_player():
	if player == null:
		state = IDLE
		return

	velocity.x = 0
	velocity.z = 0

	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))

	if global_position.distance_to(player.global_position) > attack_range:
		state = CHASE
		return

	if player.has_method("take_damage"):
		player.take_damage(damage)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		state = CHASE

func _on_body_exited(body):
	if body == player:
		player = null
		state = IDLE

func set_emission(multiplier: float):
	if mat:
		mat.emission_energy_multiplier = multiplier
