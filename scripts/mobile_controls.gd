extends CanvasLayer

var mobile_controls_enabled: bool = true

func _ready():
	var is_mobile_platform = OS.get_name() in ["Android", "iOS"]
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
