class_name LandMine extends RigidBody3D

@export var MINESIZE : float = 1:
	set(value):
		scale = Vector3(1,1,1) * value
@export var MINEEXPLOSIONRADIUS : float = 15
@export var MINEEXPLOSIONDAMAGE : float = 10
@export var MINEEXPLOSIONTIMER : float = 25

@export_category("Don't Touch")
@export var overlapSphere : Area3D
@export var glowyBit : MeshInstance3D
@export var dangerZone : MeshInstance3D
@export var Explosion : PackedScene
var Armed : float = 0.25
var spawner : MultiplayerSpawner


signal Died

func _ready() -> void:
	overlapSphere.scale = Vector3(1,1,1) * MINEEXPLOSIONRADIUS
	

func _physics_process(delta: float) -> void:
	
	if MINEEXPLOSIONTIMER > 1:
		glowyBit.set_instance_shader_parameter("Color", Color(remap(sin(MINEEXPLOSIONTIMER * 3), -1, 1, 0.25, 1),0,0,1))
	else:
		dangerZone.set_instance_shader_parameter("Thickness", remap(MINEEXPLOSIONTIMER, 1, 0, 0.1, 2))
		glowyBit.set_instance_shader_parameter("Color", Color(remap(sin(MINEEXPLOSIONTIMER * 50), -1, 1, 0.25, 1),0,0,1))
	
	MINEEXPLOSIONTIMER -= delta
	
	if MINEEXPLOSIONTIMER <= 0:
		Explode()
	if Armed > 0:
		Armed -= delta

func Trigger(_body : Node3D):
	if _body is Bullet:
		_body.Destroy()
	if _body is LandMine:
		return
	if Armed > 0: 
		return
	MINEEXPLOSIONTIMER = 1

@rpc("any_peer","call_local")
func TakeDamage(_dmg : float):
	#if is_multiplayer_authority():
		MINEEXPLOSIONTIMER = 1

func Explode():
	#await get_tree().create_timer(0.2).timeout
	for node in overlapSphere.get_overlapping_bodies():
		if node is Bullet:
			node.TakeDamage.rpc(MINEEXPLOSIONDAMAGE)
		elif node is Tank:
			node.TakeDamage.rpc(MINEEXPLOSIONDAMAGE)
		elif node is LandMine:
			node.TakeDamage.rpc(MINEEXPLOSIONDAMAGE)
		if node is RigidBody3D:
			node.apply_impulse((node.global_position - global_position).normalized() * MINEEXPLOSIONDAMAGE)
		elif node is CharacterBody3D:
			node.velocity += (node.global_position - global_position).normalized() * MINEEXPLOSIONDAMAGE
	
	var data = {
		"spawn" : Explosion.resource_path,
		"position" : global_position,
		"scale" : scale * MINEEXPLOSIONRADIUS,
	}
	spawner.spawn(data)
	
	Died.emit()
	queue_free()
