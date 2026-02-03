extends CharacterBody3D

# ============================================================
# CONSTANTS
# ============================================================

const WALK_SPEED := 10.0
const JUMP_VELOCITY := 6.0
const AIR_BOOST_VERTICAL := 5.0
const AIR_BOOST_HORIZONTAL := 10.0
const MAX_AIR_BOOSTS := 1

const SENSITIVITY := 0.003
const GRAVITY := 12.0

const BASE_FOV := 75.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.01
const DASH_FOV := 92.0
const DASH_FOV_LERP := 10.0

const AIM_DOT_THRESHOLD := 0.985

const SWAP_DASH_DURATION := 0.08
const SWAP_DASH_SPEED := 90.0

const EMISSION_BASE := 0.0
const EMISSION_AIM := 300.0
const EMISSION_LERP := 14.0

const CAM_TILT_STRENGTH := 0.09
const CAM_TILT_LERP := 12.0

const RESPAWN_OFFSET := Vector2(0, 50)

# ============================================================
# STATE
# ============================================================

enum PlayerState {
	NORMAL,
	DASH,
	SWAP_DASH,
	DEAD
}

var state := PlayerState.NORMAL

# ============================================================
# VARIABLES
# ============================================================

var speed := WALK_SPEED
var moving := false
var health := 100

var dash_speed := 30.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector3.ZERO

var swap_timer := 0.0
var swap_dash_dir := Vector3.ZERO
var swap_target_enemy : CharacterBody3D

var cam_tilt := 0.0
var emission_values := {}

var suppress_enemy_collision := false

# AIR BOOST
var air_boosts_remaining := MAX_AIR_BOOSTS

# ============================================================
# NODES
# ============================================================

@onready var head = $Head
@onready var camera = $Head/PlayerCam
@onready var particles = $Head/PlayerCam/KillParticles

var respawn_canvas : CanvasLayer
var respawn_label : Label

# ============================================================
# READY
# ============================================================

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	particles.position = Vector3(0, 0, -1.2)
	particles.process_mode = Node.PROCESS_MODE_ALWAYS

	respawn_canvas = CanvasLayer.new()
	add_child(respawn_canvas)

	respawn_label = Label.new()
	respawn_label.text = "R TO RESTART"
	respawn_label.visible = false
	respawn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	respawn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	respawn_canvas.add_child(respawn_label)

# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event):
	# 🔁 Restart ANYTIME
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
		return

	if state == PlayerState.DEAD:
		return

	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# Pause handled by PauseMenu.

# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta):
	update_enemy_emission(delta)
	update_respawn_label()

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	match state:
		PlayerState.DEAD:
			velocity = Vector3.ZERO
		PlayerState.SWAP_DASH:
			process_swap_dash(delta)
		PlayerState.DASH:
			process_dash(delta)
		PlayerState.NORMAL:
			process_normal(delta)

	update_camera(delta)
	move_and_slide()
	check_enemy_collision()

# ============================================================
# STATE LOGIC
# ============================================================

func process_swap_dash(delta):
	swap_timer -= delta
	velocity = swap_dash_dir * SWAP_DASH_SPEED
	velocity.y = 0.0

	if not is_instance_valid(swap_target_enemy):
		state = PlayerState.NORMAL
		return

	if swap_timer <= 0.0 or global_position.distance_to(swap_target_enemy.global_position) < 1.2:
		perform_swap_kill()

func process_dash(delta):
	dash_timer -= delta
	velocity.x = dash_direction.x * dash_speed
	velocity.z = dash_direction.z * dash_speed

	if dash_timer <= 0.0:
		state = PlayerState.NORMAL

func process_normal(delta):
	if is_on_floor():
		air_boosts_remaining = MAX_AIR_BOOSTS
	else:
		velocity.y -= GRAVITY * delta

	handle_jump()
	handle_swap_input()
	handle_dash_input()
	handle_movement(delta)

# ============================================================
# MOVEMENT
# ============================================================

func handle_jump():
	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif air_boosts_remaining > 0:
		air_boosts_remaining -= 1

		var back_dir = -head.global_transform.basis.z.normalized()
		velocity.y = max(velocity.y, 0.0)
		velocity += back_dir * AIR_BOOST_HORIZONTAL
		velocity.y += AIR_BOOST_VERTICAL

func handle_dash_input():
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		start_dash()

func handle_swap_input():
	if Input.is_action_just_pressed("swap"):
		try_swap_with_enemy()

func handle_movement(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	moving = direction.length() > 0.0

	if is_on_floor():
		dash_speed = 28.0
		if moving:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		dash_speed = 50.0
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

# ============================================================
# DASH
# ============================================================

func start_dash():
	state = PlayerState.DASH
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	moving = true

	var input_dir = Input.get_vector("left", "right", "up", "down")
	dash_direction = (
		-head.global_transform.basis.z
		if input_dir == Vector2.ZERO
		else (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	)

# ============================================================
# SWAP DASH
# ============================================================

func try_swap_with_enemy():
	if state != PlayerState.NORMAL:
		return

	var cam_pos = camera.global_transform.origin
	var cam_forward = -camera.global_transform.basis.z.normalized()

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy is CharacterBody3D:
			var to_enemy = enemy.global_position - cam_pos
			if cam_forward.dot(to_enemy.normalized()) >= AIM_DOT_THRESHOLD:
				start_swap_dash(enemy)
				return

func start_swap_dash(enemy):
	state = PlayerState.SWAP_DASH
	swap_target_enemy = enemy
	swap_timer = SWAP_DASH_DURATION
	swap_dash_dir = (enemy.global_position - global_position).normalized()
	velocity = Vector3.ZERO

func perform_swap_kill():
	state = PlayerState.NORMAL
	suppress_enemy_collision = true

	global_position = swap_target_enemy.global_position
	velocity = Vector3.ZERO
	swap_target_enemy.queue_free()

	camera_shake(0.05, 0.08)

	Engine.time_scale = 0.0
	await get_tree().create_timer(0.04, true, false, true).timeout
	Engine.time_scale = 1.0

	await get_tree().physics_frame
	camera.fov = BASE_FOV + 12.0

	particles.emitting = false
	particles.restart()
	particles.emitting = true

	await get_tree().physics_frame
	suppress_enemy_collision = false

# ============================================================
# CAMERA
# ============================================================

func update_camera(delta):
	var target_fov = BASE_FOV
	if state == PlayerState.DASH:
		target_fov = DASH_FOV
		camera.rotation.x += randf_range(-0.003, 0.003)
		camera.rotation.y += randf_range(-0.003, 0.003)

	camera.fov = lerp(camera.fov, target_fov, delta * DASH_FOV_LERP)
	camera.rotation.z = lerp(camera.rotation.z, cam_tilt, delta * CAM_TILT_LERP)
	cam_tilt = lerp(cam_tilt, 0.0, delta * CAM_TILT_LERP)

func camera_shake(strength, duration):
	var base_rot = camera.rotation
	var t := 0.0
	while t < duration:
		t += get_physics_process_delta_time()
		camera.rotation.x = base_rot.x + randf_range(-strength, strength)
		camera.rotation.y = base_rot.y + randf_range(-strength, strength)
		await get_tree().physics_frame
	camera.rotation = base_rot

# ============================================================
# ENEMIES
# ============================================================

func update_enemy_emission(delta):
	var cam_pos = camera.global_position
	var best_enemy = null
	var best_dot := AIM_DOT_THRESHOLD

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy is CharacterBody3D:
			var to_enemy = (enemy.global_position - cam_pos).normalized()
			var dot = -camera.global_transform.basis.z.normalized().dot(to_enemy)
			if dot > best_dot:
				best_dot = dot
				best_enemy = enemy

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not emission_values.has(enemy):
			emission_values[enemy] = EMISSION_BASE
		var target = EMISSION_AIM if enemy == best_enemy else EMISSION_BASE
		emission_values[enemy] = lerp(emission_values[enemy], target, delta * EMISSION_LERP)
		enemy.set_emission(emission_values[enemy])

func check_enemy_collision():
	if suppress_enemy_collision:
		return

	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() and c.get_collider().is_in_group("Enemy"):
			die()

# ============================================================
# DEATH / UI
# ============================================================

func die():
	state = PlayerState.DEAD
	respawn_label.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func update_respawn_label():
	if respawn_label.visible:
		respawn_label.global_position = get_viewport().get_visible_rect().size * 0.5 + RESPAWN_OFFSET
