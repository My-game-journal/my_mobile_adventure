extends CanvasLayer

# Mobile controls management script
# Handles showing/hiding mobile controls based on platform and settings

@onready var pause_button = $PauseButton
@onready var move_left_button = $MoveLeftButton
@onready var move_right_button = $MoveRightButton
@onready var shield_button = $ShieldButton
@onready var roll_button = $RollButton
@onready var jump_button = $JumpButton
@onready var attack_button = $AttackButton

var is_mobile_platform: bool = false
var mobile_controls_enabled: bool = true

func _ready():
	# Detect if we're on a mobile platform
	is_mobile_platform = OS.get_name() in ["Android", "iOS"]
	
	# Show mobile controls only on mobile platforms or when explicitly enabled
	set_mobile_controls_visibility(is_mobile_platform or mobile_controls_enabled)
	
	# Ensure mobile controls are on top layer
	layer = 100
	
	# Set up responsive positioning
	_setup_responsive_controls()
	
	# Connect to screen size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _setup_responsive_controls():
	"""Position controls based on current screen size"""
	var screen_size = get_viewport().get_visible_rect().size
	var margin = 20  # Base margin from screen edges
	var button_size = 80  # Base button size
	
	# Calculate scale factor based on screen size (minimum 1920x1080 as reference)
	var scale_factor = min(screen_size.x / 1920.0, screen_size.y / 1080.0)
	scale_factor = max(scale_factor, 0.5)  # Minimum scale
	scale_factor = min(scale_factor, 1.5)  # Maximum scale
	
	var scaled_margin = margin * scale_factor
	var scaled_button_size = button_size * scale_factor
	
	# Pause button - top right
	pause_button.position = Vector2(screen_size.x - scaled_button_size - scaled_margin, scaled_margin)
	pause_button.scale = Vector2(scale_factor, scale_factor)
	
	# Movement buttons - bottom left
	move_left_button.position = Vector2(scaled_margin, screen_size.y - scaled_button_size - scaled_margin)
	move_left_button.scale = Vector2(scale_factor, scale_factor)
	
	move_right_button.position = Vector2(scaled_margin * 2 + scaled_button_size, screen_size.y - scaled_button_size - scaled_margin)
	move_right_button.scale = Vector2(scale_factor, scale_factor)
	
	# Action buttons - bottom right
	var right_margin = screen_size.x - scaled_margin
	shield_button.position = Vector2(right_margin - scaled_button_size, screen_size.y - scaled_button_size - scaled_margin)
	shield_button.scale = Vector2(scale_factor, scale_factor)
	
	roll_button.position = Vector2(right_margin - scaled_button_size * 2 - scaled_margin, screen_size.y - scaled_button_size - scaled_margin)
	roll_button.scale = Vector2(scale_factor, scale_factor)
	
	attack_button.position = Vector2(right_margin - scaled_button_size * 3 - scaled_margin * 2, screen_size.y - scaled_button_size - scaled_margin)
	attack_button.scale = Vector2(scale_factor, scale_factor)
	
	# Jump button - positioned above attack buttons
	jump_button.position = Vector2(right_margin - scaled_button_size * 2 - scaled_margin, screen_size.y - scaled_button_size * 2 - scaled_margin * 2)
	jump_button.scale = Vector2(scale_factor, scale_factor)

func _on_viewport_size_changed():
	"""Called when screen size changes (orientation, window resize, etc.)"""
	_setup_responsive_controls()

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

func set_button_opacity(opacity: float):
	"""Change the opacity of all buttons (0.0 to 1.0)"""
	var new_modulate = Color(1, 1, 1, opacity)
	
	pause_button.modulate = new_modulate
	move_left_button.modulate = new_modulate
	move_right_button.modulate = new_modulate
	shield_button.modulate = new_modulate
	roll_button.modulate = new_modulate
	jump_button.modulate = new_modulate
	attack_button.modulate = new_modulate

# Optional: Handle input events for debugging
func _input(event):
	# Toggle mobile controls 
	if event.is_action_pressed("toggle_controls_button"):
		toggle_mobile_controls()
