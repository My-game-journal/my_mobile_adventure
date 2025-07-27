extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_wróć_do_gry_pressed() -> void:
	$/root/world/CanvasLayer/PausedMenu.visible = false
	get_tree().paused = false

func _on_zapisz_pressed() -> void:
	var player = get_node_or_null("/root/world/level_layers/player")
	if player:
		saveloadglobal.save_game_data(player.position, player.health)

func _on_wczytaj_pressed() -> void:
	var save_data = saveloadglobal.load_game_data()
	if save_data.size() == 0:
		return
	var player = get_node_or_null("/root/world/level_layers/player")
	if not player:
		return
	player.position = save_data["position"]
	player.health = save_data["health"]
	var health_bar = player.get_node_or_null("CanvasLayer/HealthBar")
	if health_bar:
		health_bar.value = save_data["health"]

func _on_zakończ_pressed() -> void:
	get_tree().quit()
