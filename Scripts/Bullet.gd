class_name Bullet extends CharacterBody3D

@export var BULLETSPEED : float = 5.0:
	set(value):
		var ratio = value / BULLETSPEED
		cast.target_position *= ratio
		BULLETSPEED = value
@export var BULLETHEALTH : float = 1.0
@export var BULLETBOUNCES : int = 2
@export var BULLETBOUNCEOFFENEMY : int = 0
@export var BULLETLIFETIME : float = 25.0
@export var BULLETDAMAGE : float = 0.5:
	set(value):
		BULLETDAMAGE = max(value, 0.1)
@export var BULLETSIZE : float = 1:
	set(value):
		var ratio = value / BULLETSIZE
		scale *= ratio
		BULLETSIZE = value
@export var BULLETTRON : int = 0:
	set(value):
		BULLETTRON = value
		trailTron.troning = value > 0
@export var BULLETTRAILLENGTH : float = 1:
	set(value):
		BULLETTRAILLENGTH = value
		trail.lifetime = value


@export var trail : TrailRenderer
@export var trailLen : int
@export var cast : ShapeCast3D
@export var sync : MultiplayerSynchronizer
@export var trailTron : Tronizer
signal Died
var died :bool = false
var points : Array[Vector3]
var parentTank : Tank
var armed : float = 0.25

func _ready() -> void:
	cast.scale = Vector3(1/scale.x,1/scale.y,1/scale.z)
	if sync:
		var stats = Upgrade.StatChange.keys()
		stats.sort()
		for stat : String in stats:
			stat =  stat.to_upper()
			if stat in self:
				stat = ".:" + stat
				if sync.replication_config.has_property(stat):
					continue
				sync.replication_config.add_property(stat)
				sync.replication_config.property_set_replication_mode(stat,SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)

func _physics_process(delta: float) -> void:
	#if is_multiplayer_authority():
		armed -= delta
		if BULLETLIFETIME <= 0:
			Destroy()
		else:
			BULLETLIFETIME -= delta
		
		if cast.is_colliding():
			var d : float = (cast.get_collision_point(0) - global_position).length()
			velocity = transform.basis.z.normalized() * min(d ,BULLETSPEED * delta)
		else:
			velocity = transform.basis.z.normalized() * (BULLETSPEED) * delta
		var col = move_and_collide(velocity)
		if col:
			Collision(col.get_collider(), col.get_normal())

func HitArea(node : Area3D):
	if is_multiplayer_authority():
		if armed < 0:
			Collision(node.get_parent_node_3d())

func Collision(node : Node3D, norm : Vector3 = Vector3.UP):
	if node is Bullet:
		TakeDamage(node.BULLETDAMAGE)
		node.TakeDamage.rpc(BULLETDAMAGE)
		return
	elif node is Tank:
		node.TakeDamage.rpc(BULLETDAMAGE)
		if BULLETBOUNCEOFFENEMY == 0:
			Destroy()
		else:
			BULLETDAMAGE -= node.HEALTH
			if BULLETDAMAGE <= 0:
				Destroy()
	elif node is UpgradeObject:
		if parentTank != null:
			if not node.claimed:
				node.Claim.rpc(parentTank.get_path())
				Destroy()
	elif node is RigidBody3D:
		node.apply_impulse(-norm * BULLETSPEED)
	rotate(Vector3.UP, basis.z.signed_angle_to(basis.z.bounce(norm),Vector3.UP)) 
	if BULLETBOUNCES <= 0:
		Destroy()
	BULLETBOUNCES -= 1

@rpc("any_peer","call_local")
func TakeDamage(dmg : float):
	#if !is_multiplayer_authority():
		BULLETHEALTH -= dmg
		if BULLETHEALTH <= 0:
			Destroy()

func Destroy() -> void:
	if !died:
		hide()
		Died.emit()
		died = true
		ReparentTrail.rpc()
		queue_free()

@rpc("any_peer","call_local")
func ReparentTrail():
	trail.reparent(get_parent())
	trail.is_emitting = false
