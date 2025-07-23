extends Node

# Mobile platform detection and configuration

static func is_mobile_platform() -> bool:
	var platform = OS.get_name()
	return platform == "Android" or platform == "iOS"

static func should_use_mobile_controls() -> bool:
	# Mobile-only game - always use touch controls
	return true

static func configure_for_mobile():
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
	return DisplayServer.get_display_safe_area()
