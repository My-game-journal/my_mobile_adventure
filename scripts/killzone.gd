extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.queue_free()
		get_tree().call_deferred("reload_current_scene")
