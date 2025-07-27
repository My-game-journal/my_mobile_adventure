extends CharacterBody2D

@export var speed: float = 25.0
@export var gravity: float = 400.0
@export var max_fall_speed: float = 200.0

@onready var rng = RandomNumberGenerator.new()
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var behavior_timer: Timer = Timer.new()

var direction := Vector2.ZERO

func _ready():
	rng.randomize()
	behavior_timer.one_shot = true
	behavior_timer.connect("timeout", _on_behavior_timer_timeout)
	add_child(behavior_timer)
	_on_behavior_timer_timeout()

func _on_behavior_timer_timeout():
	if rng.randi_range(0, 1) == 0:
		direction = Vector2.ZERO
		animated_sprite.play("idle")
		behavior_timer.wait_time = 7.0
	else:
		direction = Vector2.RIGHT if rng.randi_range(0, 1) else Vector2.LEFT
		animated_sprite.flip_h = direction.x > 0
		animated_sprite.play("walk")
		behavior_timer.wait_time = rng.randf_range(1.0, 5.0)
	behavior_timer.start()

func _reverse_direction():
	direction.x *= -1
	direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	animated_sprite.flip_h = direction.x > 0

func _physics_process(delta):
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, max_fall_speed)
	velocity.x = direction.x * speed
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision and collision is KinematicCollision2D:
			if abs(collision.get_normal().x) > 0:
				_reverse_direction()
				break
