extends RichTextLabel

func _ready():
	visible = true
	await get_tree().create_timer(20.0).timeout
	visible = false
	
