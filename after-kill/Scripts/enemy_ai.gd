extends CharacterBody3D

@export var speed := 15.0
@export var gravity := 9.8
@export var damage := 10
@export var attack_cooldown := 0.5

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var detection_area: Area3D = $DetectionArea
@onready var anim_player: AnimationPlayer = $EnemyMesh/AnimationPlayer

var player: Node3D
var state := IDLE
var attack_timer := 0.0

enum {
	IDLE,
	CHASE
}

func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if attack_timer > 0.0:
		attack_timer -= delta

	match state:
		IDLE:
			velocity.x = 0
			velocity.z = 0
			anim_player.play("CharacterArmature|Flying_Idle")

		CHASE:
			chase_player(delta)
			anim_player.play("CharacterArmature|Fast_Flying")

	move_and_slide()
	check_player_collision()

func chase_player(delta):
	if player == null:
		state = IDLE
		return

	nav_agent.target_position = player.global_position
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	var to_player = (player.global_position - global_position)
	var opposite_pos = global_position - to_player
	look_at(Vector3(opposite_pos.x, global_position.y, opposite_pos.z))

	

func check_player_collision():
	if attack_timer > 0.0:
		return

	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()

		if collider and collider.is_in_group("Player"):
			if collider.has_method("take_damage"):
				anim_player.play("CharacterArmature|Punch")
				collider.take_damage(damage)
				attack_timer = attack_cooldown

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		state = CHASE

func _on_body_exited(body):
	if body == player:
		player = null
		state = IDLE
