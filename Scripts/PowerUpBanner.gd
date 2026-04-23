class_name PowerUpLabel extends Label

@export var Lifetime : float = 3
@export var Speed : float = 1


func _process(delta: float) -> void:
	position += Vector2.UP * Speed
	Lifetime -= delta
	if Lifetime <= 0:
		queue_free()
