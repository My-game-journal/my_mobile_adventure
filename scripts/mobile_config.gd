extends Node

# Mobile platform detection and configuration

static func is_mobile_platform() -> bool:
	var platform = OS.get_name()
	return platform == "Android" or platform == "iOS"

static func should_use_mobile_controls() -> bool:
	# You can add more conditions here, like checking for touch input
	return is_mobile_platform() or OS.has_feature("mobile")

static func configure_for_mobile():
	if is_mobile_platform():
		# Configure mobile-specific settings
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
		# Disable mouse cursor on mobile
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
		# Set appropriate window flags for mobile
		if OS.get_name() == "Android":
			# Keep screen on during gameplay
			OS.set_environment("GODOT_ANDROID_KEEP_SCREEN_ON", "true")

static func get_mobile_safe_area() -> Rect2i:
	# Get safe area for devices with notches, rounded corners, etc.
	if is_mobile_platform():
		return DisplayServer.get_display_safe_area()
	else:
		# Return full screen for desktop
		var size = DisplayServer.window_get_size()
		return Rect2i(Vector2i.ZERO, size)
