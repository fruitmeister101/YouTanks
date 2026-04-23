extends Node3D

@export var m : MeshInstance3D
@export var lifetime : float = 2

var maxLife : float

func _ready() -> void:
	maxLife = lifetime

func _process(delta: float) -> void:
	m.set_instance_shader_parameter("Fade", 1 - (lifetime / maxLife))
	if lifetime < 0:
		queue_free()
	lifetime -= delta
