extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -250.0
const GRAVITY = 900.0
const ROLL_SPEED = 175.0
const COMBO_TIMEOUT = 0.8  # Czas na kolejny atak w combo

enum PlayerState { IDLE, RUNNING, JUMPING, ATTACKING, ROLLING, SHIELDING }
var state = PlayerState.IDLE

var direction := 0.0
var last_direction := 1.0

var health := 100
var health_decrease_rate := 5
var health_decrease_interval := 5.0
var time_accumulator := 0.0

# Camera smoothing variables
var camera_target_position := Vector2.ZERO
var camera_smooth_speed := 0.5

# Combo system variables
var combo_sequence = ["attack_0", "attack_1", "attack_2"]
var current_combo_index := 0
var queued_attack := false
var combo_timer: Timer

# Mobile controls reference
var mobile_controls: CanvasLayer = null

# Mobile input state
var mobile_direction := 0.0
var mobile_jump_pressed := false
var mobile_roll_pressed := false
var mobile_shield_active := false
var mobile_attack_pressed := false  # Jeden przycisk ataku zamiast trzech

func _ready():
	$AnimatedSprite2D.frame_changed.connect(_on_AnimatedSprite2D_frame_changed)
	$HitBoxAttack0.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))
	$HitBoxAttack1.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))
	$HitBoxAttack2.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))

	var health_bar = get_node_or_null("CanvasLayer/HealthBar")
	if health_bar:
		health_bar.value = health
	
	# Initialize camera target position
	camera_target_position = global_position
	# Disable built-in smoothing to use our custom implementation
	$Camera2D.position_smoothing_enabled = false
	
	# Setup combo timer
	combo_timer = Timer.new()
	combo_timer.wait_time = COMBO_TIMEOUT
	combo_timer.one_shot = true
	combo_timer.connect("timeout", Callable(self, "_on_combo_timeout"))
	add_child(combo_timer)
	
	# Setup mobile controls
	setup_mobile_controls()

func _on_combo_timeout():
	# Reset combo po upływie czasu
	current_combo_index = 0
	queued_attack = false

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_inputs()
	handle_movement()
	update_animation()
	move_and_slide()
	
	# Snap player position to pixel boundaries
	global_position = Vector2(round(global_position.x), round(global_position.y))
	
	# Custom smooth camera with pixel-perfect positioning
	update_smooth_camera(delta)

	time_accumulator += delta
	if time_accumulator >= health_decrease_interval:
		health = max(health - health_decrease_rate, 0)
		var health_bar = get_node_or_null("CanvasLayer/HealthBar")
		if health_bar:
			health_bar.value = health
			if health_bar.value <= 0:
				get_tree().reload_current_scene()
		time_accumulator = 0.0

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

func update_smooth_camera(delta: float) -> void:
	# Dynamic look-ahead based on player state and movement
	var look_ahead_distance = 30.0
	var vertical_offset = 0.0
	var vertical_smoothing_factor = 1.0
	
	# Adjust camera behavior based on player state
	match state:
		PlayerState.RUNNING:
			look_ahead_distance = 60.0
			vertical_smoothing_factor = 0.8  # Slightly less Y smoothing when running
		PlayerState.JUMPING:
			vertical_offset = -25.0  # Look up more when jumping
			look_ahead_distance = 40.0
			vertical_smoothing_factor = 1.5  # More responsive Y movement when jumping
		PlayerState.ROLLING:
			look_ahead_distance = 80.0
			vertical_smoothing_factor = 0.6  # Less Y movement when rolling
		_:
			look_ahead_distance = 30.0
			vertical_smoothing_factor = 1.0
	
	# Calculate target position with both X and Y smoothing
	var target_x = global_position.x
	var target_y = global_position.y + vertical_offset
	
	# Only apply look-ahead when moving horizontally
	if abs(velocity.x) > 10.0:
		target_x += last_direction * look_ahead_distance
	
	# Add subtle Y-axis look-ahead based on vertical velocity
	if abs(velocity.y) > 50.0:  # When falling or jumping fast
		target_y += velocity.y * 0.1  # Small look-ahead in Y direction
	
	camera_target_position = Vector2(target_x, target_y)
	
	# Adaptive smoothing speed based on movement
	var adaptive_speed_x = camera_smooth_speed
	var adaptive_speed_y = camera_smooth_speed * vertical_smoothing_factor
	
	if state == PlayerState.ROLLING:
		adaptive_speed_x = camera_smooth_speed * 1.5  # Faster X for rolls
	elif abs(velocity.x) < 10.0:
		adaptive_speed_x = camera_smooth_speed * 0.7  # Slower X when idle
	
	# Separate interpolation for X and Y axes
	var camera = $Camera2D
	var current_pos = camera.global_position
	
	var new_x = lerp(current_pos.x, camera_target_position.x, adaptive_speed_x * delta)
	var new_y = lerp(current_pos.y, camera_target_position.y, adaptive_speed_y * delta)
	
	# Snap camera to pixel boundaries to maintain crispness
	camera.global_position = Vector2(round(new_x), round(new_y))

func setup_mobile_controls():
	# Configure mobile-specific settings (mobile-only game)
	preload("res://scripts/mobile_config.gd").configure_for_mobile()
	
	# Look for mobile controls in the scene tree
	mobile_controls = get_node_or_null("/root/MobileControls")
	if mobile_controls:
		# Connect mobile control signals
		mobile_controls.move_left_pressed.connect(_on_mobile_move_left_pressed)
		mobile_controls.move_left_released.connect(_on_mobile_move_left_released)
		mobile_controls.move_right_pressed.connect(_on_mobile_move_right_pressed)
		mobile_controls.move_right_released.connect(_on_mobile_move_right_released)
		mobile_controls.jump_pressed.connect(_on_mobile_jump_pressed)
		mobile_controls.roll_pressed.connect(_on_mobile_roll_pressed)
		mobile_controls.shield_pressed.connect(_on_mobile_shield_pressed)
		mobile_controls.shield_released.connect(_on_mobile_shield_released)
		mobile_controls.attack_pressed.connect(_on_mobile_attack_pressed)
		mobile_controls.pause_pressed.connect(_on_mobile_pause_pressed)
		
		# Show mobile controls
		mobile_controls.visible = true

# Mobile input signal handlers
func _on_mobile_move_left_pressed():
	mobile_direction = -1.0

func _on_mobile_move_left_released():
	if mobile_direction < 0:
		mobile_direction = 0.0

func _on_mobile_move_right_pressed():
	mobile_direction = 1.0

func _on_mobile_move_right_released():
	if mobile_direction > 0:
		mobile_direction = 0.0

func _on_mobile_jump_pressed():
	mobile_jump_pressed = true

func _on_mobile_roll_pressed():
	mobile_roll_pressed = true

func _on_mobile_shield_pressed():
	mobile_shield_active = true

func _on_mobile_shield_released():
	mobile_shield_active = false

# ZMIANA: Jeden handler dla przycisku ataku
func _on_mobile_attack_pressed():
	mobile_attack_pressed = true

func _on_mobile_pause_pressed():
	# Handle pause functionality
	var world = get_node_or_null("/root/world")
	if world:
		var paused_menu = world.get_node_or_null("CanvasLayer/PausedMenu")
		if paused_menu:
			paused_menu.visible = true
			get_tree().paused = true

func handle_inputs():
	var can_act = state not in [PlayerState.ATTACKING, PlayerState.ROLLING]
	var can_jump_while_moving = state in [PlayerState.IDLE, PlayerState.RUNNING]
	var can_roll_while_moving = state in [PlayerState.IDLE, PlayerState.RUNNING]

	# Handle jump input
	if mobile_jump_pressed and is_on_floor() and (can_act or can_jump_while_moving):
		velocity.y = JUMP_VELOCITY
		state = PlayerState.JUMPING
	mobile_jump_pressed = false

	# Handle roll input
	if mobile_roll_pressed and is_on_floor() and (can_act or can_roll_while_moving):
		start_roll()
	mobile_roll_pressed = false

	# ZMIANA: System combo z jednym przyciskiem
	if mobile_attack_pressed and can_act:
		# Jeśli już atakujemy, ustaw kolejkowanie
		if state == PlayerState.ATTACKING:
			queued_attack = true
		else:
			start_next_attack()
	
	mobile_attack_pressed = false

	# Handle shield input
	if mobile_shield_active and can_act:
		state = PlayerState.SHIELDING
		$ShieldBox.monitoring = true
		$ShieldBox.get_node("CollisionShape2D").disabled = false
		$ShieldBox.scale.x = -1 if last_direction < 0 else 1
	else:
		if state == PlayerState.SHIELDING:
			$ShieldBox.monitoring = false
			$ShieldBox.get_node("CollisionShape2D").disabled = true
			state = PlayerState.IDLE

# ZMIANA: Nowa funkcja do obsługi systemu combo
func start_next_attack():
	# Uruchom timer combo
	combo_timer.start()
	
	# Pobierz nazwę animacji dla obecnego indeksu combo
	var anim_name = combo_sequence[current_combo_index]
	
	# Wybierz odpowiedni hitbox
	var hitbox
	match anim_name:
		"attack_0":
			hitbox = $HitBoxAttack0
		"attack_1":
			hitbox = $HitBoxAttack1
		"attack_2":
			hitbox = $HitBoxAttack2
		_:
			hitbox = $HitBoxAttack0
	
	# Uruchom atak
	state = PlayerState.ATTACKING
	$AnimatedSprite2D.play(anim_name)
	update_hitbox_flip(hitbox)
	hitbox.monitoring = false
	for child in hitbox.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
	
	# Przygotuj następny krok combo
	current_combo_index = (current_combo_index + 1) % combo_sequence.size()

# POPRAWIONE: Pełna implementacja handle_movement
func handle_movement():
	# Get direction from mobile controls only
	direction = mobile_direction
	
	if direction != 0:
		last_direction = direction

	if state == PlayerState.ROLLING:
		velocity.x = last_direction * ROLL_SPEED
	elif state not in [PlayerState.ATTACKING, PlayerState.SHIELDING]:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0

func update_animation():
	$AnimatedSprite2D.flip_h = last_direction < 0

	if not is_on_floor():
		if state == PlayerState.JUMPING:
			$AnimatedSprite2D.play("jump")
	else:
		match state:
			PlayerState.SHIELDING:
				$AnimatedSprite2D.play("shield")
			PlayerState.ROLLING:
				$AnimatedSprite2D.play("roll")
			PlayerState.ATTACKING:
				pass  # Attack animation is already being handled
			_:
				if direction != 0:
					$AnimatedSprite2D.play("run")
				else:
					$AnimatedSprite2D.play("idle")

func start_roll():
	if state == PlayerState.ROLLING:
		return
	state = PlayerState.ROLLING
	$AnimatedSprite2D.flip_h = last_direction < 0
	$AnimatedSprite2D.play("roll")

func update_hitbox_flip(hitbox: Node2D):
	$AnimatedSprite2D.flip_h = last_direction < 0
	hitbox.scale.x = -1 if last_direction < 0 else 1

func handle_hitbox_frames(hitbox: Node2D, active: bool):
	hitbox.monitoring = active
	for child in hitbox.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = not active

func is_last_frame(anim_name: String) -> bool:
	return $AnimatedSprite2D.frame == $AnimatedSprite2D.sprite_frames.get_frame_count(anim_name) - 1

func _on_AnimatedSprite2D_frame_changed():
	var anim = $AnimatedSprite2D.animation
	var frame = $AnimatedSprite2D.frame

	match anim:
		"attack_0":
			handle_hitbox_frames($HitBoxAttack0, frame == 5)
			if is_last_frame(anim):
				handle_combo_finish()

		"attack_1":
			handle_hitbox_frames($HitBoxAttack1, frame in [2, 5])
			if is_last_frame(anim):
				handle_combo_finish()

		"attack_2":
			handle_hitbox_frames($HitBoxAttack2, frame in range(2, 6))
			if is_last_frame(anim):
				handle_combo_finish()

		"roll":
			if is_last_frame(anim):
				state = PlayerState.IDLE

# ZMIANA: Nowa funkcja do obsługi zakończenia animacji ataku
func handle_combo_finish():
	# Jeśli mamy kolejkowany atak, uruchom następny
	if queued_attack:
		queued_attack = false
		start_next_attack()
	else:
		# Jeśli nie ma kolejkowanego ataku, zakończ combo
		state = PlayerState.IDLE
		combo_timer.stop()
		current_combo_index = 0

func _on_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		body.vanish()
