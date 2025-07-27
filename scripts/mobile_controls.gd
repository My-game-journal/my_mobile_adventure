extends CanvasLayer

# Mobile controls management script
# Handles showing/hiding mobile controls based on platform and settings

@onready var pause_button = $ControlPause/ControlPauseButton
@onready var move_left_button = $ControlMove/ControlMoveLeftButton
@onready var move_right_button = $ControlMove/ControlMoveRightButton
@onready var shield_button = $ControlAction/ControlShieldButton
@onready var roll_button = $ControlAction/ControlRollButton
@onready var jump_button = $ControlAction/ControlJumpButton
@onready var attack_button = $ControlAction/ControlAttackButton

var is_mobile_platform: bool = false
var mobile_controls_enabled: bool = true

func _ready():
	# Detect if we're on a mobile platform
	is_mobile_platform = OS.get_name() in ["Android", "iOS"]
	
	# Show mobile controls only on mobile platforms or when explicitly enabled
	set_mobile_controls_visibility(is_mobile_platform or mobile_controls_enabled)
	
	# Ensure mobile controls are on top layer
	layer = 100

func set_mobile_controls_visibility(show_controls: bool):
	"""Toggle visibility of all mobile control buttons"""
	self.visible = show_controls
	
	# TouchScreenButton nodes don't have a 'disabled' property
	# Visibility control is sufficient - when the CanvasLayer is hidden,
	# the buttons won't receive input events

func toggle_mobile_controls():
	"""Toggle mobile controls on/off"""
	mobile_controls_enabled = not mobile_controls_enabled
	set_mobile_controls_visibility(mobile_controls_enabled)

# Optional: Handle input events for debugging
func _input(event):
	# Toggle mobile controls 
	if event.is_action_pressed("toggle_controls_button"):
		toggle_mobile_controls()
