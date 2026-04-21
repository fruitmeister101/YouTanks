extends Node3D

@export var timeToLive : float = 10
@export var m : MeshInstance3D

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		timeToLive -= delta
		if timeToLive <= 0:
			Destroy.rpc()
		if timeToLive <= 2:
			m.set_instance_shader_parameter("Alpha", timeToLive / 2.0)
			pass

@rpc("any_peer","call_local")
func Destroy():
	queue_free()
