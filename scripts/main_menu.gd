extends Control

@onready var start_button = $"VBoxContainer/Nowa gra"
@onready var exit_button = $VBoxContainer/Zamknij
@onready var options_button = $VBoxContainer/Ustawienia
@onready var options_menu = $OptionsMenu
@onready var v_box_container = $VBoxContainer

@onready var start_level = preload("res://scenes/world.tscn")
@onready var music_player = $MusicMenuPlayer

func _ready():
	handle_connecting_signals()
	var stream = music_player.stream
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = 325500
		music_player.play()

func on_start_pressed() -> void:
	get_tree().change_scene_to_packed(start_level)

func _on_wczytaj_pressed() -> void:
	var save_data = saveloadglobal.load_game_data()
	if save_data.size() == 0:
		return
		
	var loaded_scene = start_level.instantiate()
	var player = loaded_scene.get_node_or_null("level_layers/player")
	if player:
		player.position = save_data["position"]
		player.health = save_data["health"]
		var health_bar = player.get_node_or_null("CanvasLayer/HealthBar")
		if health_bar:
			health_bar.value = save_data["health"]
	_switch_scene(loaded_scene)

func _switch_scene(new_scene: Node) -> void:
	get_tree().root.add_child(new_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = new_scene

func on_options_pressed() -> void:
	v_box_container.visible = false
	options_menu.set_process(true)
	options_menu.visible = true

func on_exit_pressed() -> void:
	get_tree().quit()

func on_exit_options_menu() -> void:
	v_box_container.visible = true
	options_menu.visible = false

func handle_connecting_signals() -> void:
	start_button.button_down.connect(on_start_pressed)
	options_button.button_down.connect(on_options_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	options_menu.exit_options_menu.connect(on_exit_options_menu)
