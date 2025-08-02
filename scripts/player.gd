extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -250.0
const GRAVITY = 900.0
const ROLL_SPEED = 175.0
const COMBO_TIMEOUT = 0.8

enum PlayerState { IDLE, RUNNING, JUMPING, ATTACKING, ROLLING, SHIELDING }
var state = PlayerState.IDLE

var direction := 0.0
var last_direction := 1.0

var health := 100
var health_decrease_rate := 5
var health_decrease_interval := 5.0
var time_accumulator := 0.0

var camera_target_position := Vector2.ZERO
var camera_smooth_speed := 0.5

var combo_sequence = ["attack_0", "attack_1", "attack_2"]
var current_combo_index := 0
var can_combo := false
var combo_timer: Timer

var attack_stuck_timer: Timer
var attack_stuck_timeout := 2.0

var coyote_time := 0.15
var coyote_timer := 0.0
var was_on_floor := false

var momentum_multiplier := 1.0
var combo_momentum := 0.0
var air_dash_available := false
var dynamic_camera_shake := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var health_bar = get_node_or_null("CanvasLayer/HealthBar")
@onready var hitboxes = {
	"attack_0": $HitBoxAttack0,
	"attack_1": $HitBoxAttack1,
	"attack_2": $HitBoxAttack2
}

func _ready():
	animated_sprite.frame_changed.connect(_on_AnimatedSprite2D_frame_changed)
	for hitbox in hitboxes.values():
		hitbox.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))

	if health_bar:
		health_bar.value = health
	
	camera_target_position = global_position
	camera.position_smoothing_enabled = false
	
	combo_timer = _create_timer(COMBO_TIMEOUT, "_on_combo_timeout")
	attack_stuck_timer = _create_timer(attack_stuck_timeout, "_on_attack_stuck_timeout")
	
	setup_dynamic_features()

func _create_timer(wait_time: float, callback: String) -> Timer:
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.connect("timeout", Callable(self, callback))
	add_child(timer)
	return timer

func _on_combo_timeout():
	current_combo_index = 0
	can_combo = false

func _on_attack_stuck_timeout():
	if state == PlayerState.ATTACKING:
		state = PlayerState.IDLE
		can_combo = false
		current_combo_index = 0
		velocity.x = 0

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	update_coyote_time(delta)
	update_dynamic_features(delta)
	handle_inputs()
	handle_movement()
	update_animation()
	move_and_slide()
	
	global_position = Vector2(round(global_position.x), round(global_position.y))
	
	update_smooth_camera(delta)

	time_accumulator += delta
	if time_accumulator >= health_decrease_interval:
		health = max(health - health_decrease_rate, 0)
		if health_bar:
			health_bar.value = health
			if health_bar.value <= 0:
				get_tree().reload_current_scene()
		time_accumulator = 0.0

func update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		was_on_floor = true
	elif was_on_floor:
		coyote_timer -= delta
		if coyote_timer <= 0:
			was_on_floor = false

func can_coyote_jump() -> bool:
	return coyote_timer > 0 or is_on_floor()

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

func update_smooth_camera(delta: float) -> void:
	var look_ahead_distance = 30.0
	var vertical_offset = 0.0
	var vertical_smoothing_factor = 1.0
	
	match state:
		PlayerState.RUNNING:
			look_ahead_distance = 60.0
			vertical_smoothing_factor = 0.8
		PlayerState.JUMPING:
			vertical_offset = -25.0
			look_ahead_distance = 40.0
			vertical_smoothing_factor = 1.5
		PlayerState.ROLLING:
			look_ahead_distance = 80.0
			vertical_smoothing_factor = 0.6
		_:
			look_ahead_distance = 30.0
			vertical_smoothing_factor = 1.0
	
	var target_x = global_position.x
	var target_y = global_position.y + vertical_offset
	
	if abs(velocity.x) > 10.0:
		target_x += last_direction * look_ahead_distance
	
	if abs(velocity.y) > 50.0:
		target_y += velocity.y * 0.1
	
	camera_target_position = Vector2(target_x, target_y)
	
	var adaptive_speed_x = camera_smooth_speed
	var adaptive_speed_y = camera_smooth_speed * vertical_smoothing_factor
	
	if state == PlayerState.ROLLING:
		adaptive_speed_x = camera_smooth_speed * 1.5
	elif abs(velocity.x) < 10.0:
		adaptive_speed_x = camera_smooth_speed * 0.7
	
	var current_pos = camera.global_position
	
	var new_x = lerp(current_pos.x, camera_target_position.x, adaptive_speed_x * delta)
	var new_y = lerp(current_pos.y, camera_target_position.y, adaptive_speed_y * delta)
	
	if dynamic_camera_shake > 0:
		var shake_x = randf_range(-dynamic_camera_shake, dynamic_camera_shake)
		var shake_y = randf_range(-dynamic_camera_shake, dynamic_camera_shake)
		new_x += shake_x
		new_y += shake_y
	
	camera.global_position = Vector2(round(new_x), round(new_y))

func setup_dynamic_features():
	momentum_multiplier = 1.0
	combo_momentum = 0.0
	air_dash_available = false
	dynamic_camera_shake = 0.0

func update_dynamic_features(delta: float):
	if combo_momentum > 0:
		combo_momentum = max(combo_momentum - delta * 2.0, 0.0)
	
	if is_on_floor():
		air_dash_available = true
	
	if dynamic_camera_shake > 0:
		dynamic_camera_shake = max(dynamic_camera_shake - delta * 8.0, 0.0)

func apply_camera_shake(intensity: float):
	dynamic_camera_shake = intensity

func get_hitbox_for_attack(attack_name: String) -> Node2D:
	return hitboxes.get(attack_name, hitboxes["attack_0"])

func update_sprite_flip():
	animated_sprite.flip_h = last_direction < 0

func transition_to_appropriate_state():
	state = PlayerState.RUNNING if direction != 0 else PlayerState.IDLE

func handle_inputs():
	var can_act = state not in [PlayerState.ATTACKING, PlayerState.JUMPING] and is_on_floor()
	var can_jump = state not in [PlayerState.ATTACKING, PlayerState.SHIELDING]
	var can_roll = state not in [PlayerState.ATTACKING, PlayerState.SHIELDING]
	
	var is_jump_animation_playing = animated_sprite.animation == "jump" and animated_sprite.is_playing()
	if is_jump_animation_playing:
		can_act = false

	var jump_input = Input.is_action_just_pressed("jump_button")
	if jump_input and can_coyote_jump() and can_jump:
		var jump_boost = 1.0 + (momentum_multiplier - 1.0) * 0.5
		velocity.y = JUMP_VELOCITY * jump_boost
		coyote_timer = 0
		if state != PlayerState.ROLLING:
			state = PlayerState.JUMPING
		apply_camera_shake(1.0)

	var roll_input = Input.is_action_just_pressed("roll_button")
	if roll_input and can_roll:
		if not is_on_floor() and air_dash_available:
			start_air_dash()
			air_dash_available = false
		else:
			start_roll()

	var attack_input = Input.is_action_just_pressed("attack_button")
	if attack_input:
		if can_act:
			start_next_attack()
			combo_momentum += 0.3
		elif state == PlayerState.ATTACKING and can_combo:
			start_next_attack()
			combo_momentum += 0.5

	var shield_input = Input.is_action_pressed("shield_button")
	if shield_input and can_act and is_on_floor():
		state = PlayerState.SHIELDING
		$ShieldBox.monitoring = true
		$ShieldBox.get_node("CollisionShape2D").disabled = false
		$ShieldBox.scale.x = -1 if last_direction < 0 else 1
	else:
		if state == PlayerState.SHIELDING:
			$ShieldBox.monitoring = false
			$ShieldBox.get_node("CollisionShape2D").disabled = true
			state = PlayerState.IDLE

func start_next_attack():
	combo_timer.start()
	attack_stuck_timer.start()
	can_combo = false
	var input_dir = clamp(Input.get_axis("move_left_button", "move_right_button"), -1.0, 1.0)
	if input_dir != 0:
		last_direction = input_dir
	var anim_name = combo_sequence[current_combo_index]
	var hitbox = get_hitbox_for_attack(anim_name)
	state = PlayerState.ATTACKING
	animated_sprite.play(anim_name)
	update_hitbox_flip(hitbox)
	hitbox.monitoring = false
	for child in hitbox.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
	var shake_intensity = 1.0 + (combo_momentum * 0.5)
	var shake_multipliers = {"attack_0": 1.0, "attack_1": 1.2, "attack_2": 1.5}
	apply_camera_shake(shake_intensity * shake_multipliers.get(anim_name, 1.0))
	current_combo_index = (current_combo_index + 1) % combo_sequence.size()

func handle_movement():
	direction = clamp(Input.get_axis("move_left_button", "move_right_button"), -1.0, 1.0)
	if direction != 0:
		last_direction = direction
		update_sprite_flip()
	match state:
		PlayerState.ROLLING:
			var roll_speed = ROLL_SPEED * momentum_multiplier
			velocity.x = direction * roll_speed if direction != 0 else last_direction * roll_speed * 0.7
		PlayerState.ATTACKING:
			velocity.x = velocity.x * (0.8 + (combo_momentum * 0.2))
			if direction != 0:
				var anim_name = combo_sequence[(current_combo_index - 1 + combo_sequence.size()) % combo_sequence.size()]
				var current_hitbox = get_hitbox_for_attack(anim_name)
				if current_hitbox:
					update_hitbox_flip(current_hitbox)
		PlayerState.SHIELDING:
			velocity.x = 0
		_:
			velocity.x = direction * SPEED * momentum_multiplier

func update_animation():
	if not is_on_floor():
		if state == PlayerState.JUMPING:
			animated_sprite.play("jump")
		elif state == PlayerState.ROLLING:
			animated_sprite.play("roll")
		else:
			animated_sprite.play("jump")
	else:
		if state == PlayerState.JUMPING:
			var current_anim = animated_sprite.animation
			if current_anim == "jump":
				if not animated_sprite.is_playing() or is_last_frame("jump"):
					transition_to_appropriate_state()
			else:
				transition_to_appropriate_state()
		
		match state:
			PlayerState.SHIELDING:
				animated_sprite.play("shield")
			PlayerState.ROLLING:
				animated_sprite.play("roll")
			PlayerState.ATTACKING:
				pass
			_:
				if direction != 0:
					animated_sprite.play("run")
					if state == PlayerState.JUMPING:
						state = PlayerState.RUNNING
				else:
					animated_sprite.play("idle")
					if state in [PlayerState.RUNNING, PlayerState.JUMPING]:
						state = PlayerState.IDLE

func start_roll():
	if state in [PlayerState.ATTACKING, PlayerState.SHIELDING]:
		return
	
	state = PlayerState.ROLLING
	update_sprite_flip()
	animated_sprite.play("roll")
	
	if not is_on_floor():
		velocity.x = last_direction * ROLL_SPEED * 1.2
	
	apply_camera_shake(1.5)

func start_air_dash():
	state = PlayerState.ROLLING
	update_sprite_flip()
	animated_sprite.play("roll")
	
	velocity.x = last_direction * ROLL_SPEED * 1.5
	velocity.y = min(velocity.y, -50)
	
	apply_camera_shake(2.0)

func update_hitbox_flip(hitbox: Node2D):
	update_sprite_flip()
	hitbox.scale.x = -1 if last_direction < 0 else 1

func handle_hitbox_frames(hitbox: Node2D, active: bool):
	hitbox.monitoring = active
	for child in hitbox.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = not active

func is_last_frame(anim_name: String) -> bool:
	return animated_sprite.frame == animated_sprite.sprite_frames.get_frame_count(anim_name) - 1

func _on_AnimatedSprite2D_frame_changed():
	var anim = animated_sprite.animation
	var frame = animated_sprite.frame

	match anim:
		"attack_0":
			handle_hitbox_frames(hitboxes["attack_0"], frame == 5)
			can_combo = frame >= 3
			if is_last_frame(anim):
				handle_combo_finish()

		"attack_1":
			handle_hitbox_frames(hitboxes["attack_1"], frame in [2, 5])
			can_combo = frame >= 4
			if is_last_frame(anim):
				handle_combo_finish()

		"attack_2":
			handle_hitbox_frames(hitboxes["attack_2"], frame in range(2, 6))
			can_combo = frame >= 4
			if is_last_frame(anim):
				handle_combo_finish()

		"roll":
			if is_last_frame(anim):
				if not is_on_floor():
					state = PlayerState.JUMPING
				elif direction != 0:
					state = PlayerState.RUNNING
				else:
					state = PlayerState.IDLE
		
		"jump":
			if is_last_frame(anim) and is_on_floor():
				transition_to_appropriate_state()

func handle_combo_finish():
	attack_stuck_timer.stop()
	
	if state == PlayerState.ATTACKING:
		state = PlayerState.IDLE
	
	can_combo = false
	
	if abs(velocity.x) < 1.0:
		velocity.x = 0

func _on_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		body.vanish()
		
		combo_momentum += 0.4
		apply_camera_shake(1.7)
		
		momentum_multiplier = min(momentum_multiplier + 0.1, 2.0)
		
		Engine.time_scale = 0.7
		await get_tree().create_timer(0.05).timeout
		Engine.time_scale = 1.0
