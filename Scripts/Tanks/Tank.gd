class_name Tank extends CharacterBody3D
@export_category("TankVars")
@export var MOVESPEED : float = 5.0
@export var TURNSPEED : float = 30.0
@export var BARRELAIMSPEED : float = 3
@export var HEALTH : float = 1
@export var FRICTION : float = 1
@export var ACCELERATION : float = 1
@export var MAXBULLETSOUT : int = 5:
	set(value):
		MAXBULLETSOUT = max(value, 1)
@export var PLAYERSIZE : float = 0.6:
	set(value):
		trackDist *= value / PLAYERSIZE
		PLAYERSIZE = value
		scale = Vector3(PLAYERSIZE,PLAYERSIZE,PLAYERSIZE)
@export var BULLETCOOLDOWN : float
@export var BULLETEVENSPREAD : int = 0

@export_category("BulletVars")
@export var BULLETDAMAGE : float = 0.5
@export var BULLETSPEED : float = 5.0
@export var BULLETHEALTH : float = 1
@export var BULLETSPREAD : float = 0
@export var BULLETBOUNCES : int = 2
@export var BULLETCOUNT : int = 1
@export var BULLETBURST : int = 1
@export var BULLETSIZE : float = 0.6
@export var BULLETBOUNCEOFFENEMY : int = 0
@export var BULLETLIFETIME : float = 25

@export var BULLETTRON : int = 0
@export var BULLETTRAILLENGTH : float = 1

@export_category("MineVars")
@export var MINEEXPLOSIONRADIUS : float = 15
@export var MINEEXPLOSIONDAMAGE : float = 2
@export var MINEEXPLOSIONTIMER : float = 25
@export var MINESIZE : float = 0.6:
	set(value):
		MINESIZE = max(0.1, value)
@export var MAXMINESOUT : int = 2:
	set(value):
		MAXMINESOUT = max(1, value)
@export var MINEVELOCITY : float = 0

@export_category("Dont Touch")
@export var bullet : PackedScene
@export var landMine : PackedScene
@export var FiringPoint : Node3D
@export var TrackPlacers : Array[Node3D]
@export var Track : PackedScene
@export var trackDist : float = 1
@export var BarrelAiming : Node3D
@export var MaxAimFromForward : float = 30
#@export var DestructionMark : PackedScene
@export var line : LineRenderer
@export var spawner : MultiplayerSpawner
@export var targetingCursor : Node3D

var mineCooldown : float = 0
var Invinsible : bool = false

signal Died(tank : Tank)

var ShootCooldown : float

var bulletsOut : int = 0
var landMinesOut : int = 0

var mainCam : Camera3D
var mainView : Viewport
var angularVelocity : float
var lastTrackPlaced : Vector3 = Vector3.ZERO

var container : TankContainer

var InputMove : Vector2
var targetPlane : Plane
var InputMousePos : Vector2
var intercept

@export var sync : MultiplayerSynchronizer

func _ready() -> void:
	if targetingCursor:
		targetingCursor.position = Vector3.ZERO
		if not is_multiplayer_authority():
			targetingCursor.hide()
	mainView = get_viewport()
	mainCam = mainView.get_camera_3d()

func SetUp() -> void:
	#rotation.y = basis.z.signed_angle_to(Vector3(), Vector3.UP)
	show()
	mainView = get_viewport()
	mainCam = GM.gm.mainCam
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


func HandleTargeting(_delta: float = 0) -> void:
	pass

func HandleShooting(_delta: float = 0) -> void:
	pass

func PlaceTrack(_delta : float) -> void:
	if is_multiplayer_authority():
		if is_on_floor():
			lastTrackPlaced = global_position
			for placer in TrackPlacers:
				var data = {}
				data["spawn"] = Track.resource_path
				data["position"] = placer.global_position
				data["rotation"] = placer.global_rotation.y
				data["scale"] = scale
				data["id"] = str(multiplayer.get_unique_id())
				spawner.spawn(data)

func Shoot() -> void :
	if not is_multiplayer_authority():
		return
	if ShootCooldown > 0:
		return
	if bulletsOut < MAXBULLETSOUT:
		ShootCooldown = BULLETCOOLDOWN
		for b in BULLETBURST:
			for i in BULLETCOUNT:
				var offset : Vector3 = Vector3.ZERO
				var spread : float = 0
				if BULLETCOUNT > 1:
					offset = FiringPoint.basis.x.normalized() * BULLETSIZE / 3.0
				
				if BULLETEVENSPREAD > 0:
					spread = BULLETSPREAD - BULLETSPREAD * i
				else:
					spread = randf_range(-BULLETSPREAD, BULLETSPREAD)
				MakeBullet(offset, spread / 360 * TAU)
			await get_tree().create_timer(BULLETCOOLDOWN / BULLETBURST / 1.5).timeout

func LayMine():
	if not is_multiplayer_authority():
		return
	if landMinesOut < MAXMINESOUT:
		if mineCooldown <= 0:
			mineCooldown = BULLETCOOLDOWN * MINESIZE * 2
			landMinesOut += 1
			return MakeMine()

func MakeBullet(offset : Vector3 = Vector3.ZERO, Spread : float = 0):
	var data = {
		"spawn" : bullet.resource_path,
		"position" : FiringPoint.global_position + offset,
		"rotation" : FiringPoint.global_rotation.y + Spread,
		"id" : str(multiplayer.get_unique_id()),
		"parentTank" : name,
	}
	return spawner.spawn(data)

func MakeMine():
	var data = {
		"spawn" : landMine.resource_path,
		"position" : global_position,
		"id" : str(multiplayer.get_unique_id()),
		"parentTank" : name,
		"velocity" : MINEVELOCITY
	}
	return spawner.spawn(data)












func Move(_delta: float = 0) ->void:
	var input_dir := InputMove
	if (lastTrackPlaced - global_position).length() >= trackDist:
		PlaceTrack(_delta)

	velocity = velocity.move_toward(transform.basis.z.normalized() * input_dir.y * MOVESPEED, FRICTION * 0.125) + velocity.y * Vector3.UP
	velocity += get_gravity() * _delta
	angularVelocity = move_toward(angularVelocity, input_dir.x * TURNSPEED / TAU * _delta, FRICTION * 0.125 * 0.125)
	rotate_y(angularVelocity)

@rpc("any_peer","call_local")
func TakeDamage(dmg : float):
	if Invinsible:
		return
	if is_multiplayer_authority():
		HEALTH -= dmg
		if HEALTH <= 0:
			Destroy()

@rpc("any_peer","call_local")
func Destroy(force : bool = false) -> void:
	Died.emit(self, force)
	hide()
	queue_free()

func BulletFreed(_bullet : Bullet) -> void:
	bulletsOut -= 1

func MineFreed(_mine : LandMine) -> void:
	landMinesOut -= 1

@rpc("any_peer","call_local")
func MakeVincible():
	Invinsible = false
