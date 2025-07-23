extends CanvasLayer

# Mobile control signals that the player will listen to
signal move_left_pressed
signal move_left_released
signal move_right_pressed
signal move_right_released
signal jump_pressed
signal roll_pressed
signal shield_pressed
signal shield_released
signal attack_0_pressed
signal attack_1_pressed
signal attack_2_pressed
signal pause_pressed

# Movement state tracking
var is_moving_left = false
var is_moving_right = false
var is_shielding = false

func _ready():
	# Connect movement buttons
	$LeftControls/MoveLeftButton.button_down.connect(_on_move_left_pressed)
	$LeftControls/MoveLeftButton.button_up.connect(_on_move_left_released)
	$LeftControls/MoveRightButton.button_down.connect(_on_move_right_pressed)
	$LeftControls/MoveRightButton.button_up.connect(_on_move_right_released)
	
	# Connect action buttons
	$RightControls/JumpButton.pressed.connect(_on_jump_pressed)
	$RightControls/RollButton.pressed.connect(_on_roll_pressed)
	$RightControls/ShieldButton.button_down.connect(_on_shield_pressed)
	$RightControls/ShieldButton.button_up.connect(_on_shield_released)
	
	# Connect attack buttons
	$AttackControls/AttackButton.pressed.connect(_on_attack_pressed)

	
	# Connect pause button
	$PauseButton.pressed.connect(_on_pause_pressed)

# Movement button handlers
func _on_move_left_pressed():
	is_moving_left = true
	move_left_pressed.emit()

func _on_move_left_released():
	is_moving_left = false
	move_left_released.emit()

func _on_move_right_pressed():
	is_moving_right = true
	move_right_pressed.emit()

func _on_move_right_released():
	is_moving_right = false
	move_right_released.emit()

# Action button handlers
func _on_jump_pressed():
	jump_pressed.emit()

func _on_roll_pressed():
	roll_pressed.emit()

func _on_shield_pressed():
	is_shielding = true
	shield_pressed.emit()

func _on_shield_released():
	is_shielding = false
	shield_released.emit()

# Attack button handlers
func _on_attack_pressed():
	attack_0_pressed.emit()

func _on_pause_pressed():
	pause_pressed.emit()

# Helper functions for the player to check button states
func get_movement_direction() -> float:
	var direction = 0.0
	if is_moving_left:
		direction -= 1.0
	if is_moving_right:
		direction += 1.0
	return direction

func is_shield_active() -> bool:
	return is_shielding
