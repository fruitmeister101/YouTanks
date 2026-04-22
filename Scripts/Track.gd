extends Node3D

@export var timeToLive : float = 10
@export var m : MeshInstance3D

func _physics_process(delta: float) -> void:
	timeToLive -= delta
	if timeToLive <= 0 and is_multiplayer_authority():
		Destroy.rpc()
	if timeToLive <= 4:
		m.set_instance_shader_parameter("Alpha", clamp(timeToLive / 4.0, 0, 1))
		pass

@rpc("any_peer","call_local")
func Destroy():
	queue_free()
