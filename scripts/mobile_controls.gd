extends CanvasLayer



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
	is_mobile_platform = OS.get_name() in ["Android", "iOS"]
	set_mobile_controls_visibility(is_mobile_platform or mobile_controls_enabled)
	layer = 100

func set_mobile_controls_visibility(show_controls: bool):
	self.visible = show_controls

func toggle_mobile_controls():
	mobile_controls_enabled = not mobile_controls_enabled
	set_mobile_controls_visibility(mobile_controls_enabled)

func _input(event):
	if event.is_action_pressed("toggle_controls_button"):
		toggle_mobile_controls()
