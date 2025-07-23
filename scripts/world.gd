# World.gd
extends Node

func _ready():
	$ThemePlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	$ThemePlayer.play()
