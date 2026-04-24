class_name TankContainer extends Node

@export var spawner : MultiplayerSpawner
@export var tankScene : PackedScene
@export var maxTanks : int = 1
@export var myTanks : Array[Tank]
@export var Upgrades : Array[UpgradeObject]
@export var persistent : bool = false
@export var InstantSpawns : int = 1
#@export var RespawnButton: Button
@export

var Temporaries : Array = []

var baseStats : Dictionary
var originalChildCount : int

signal choseUpgrade(up : UpgradeObject)
signal tankDied(t : TankContainer, force : bool)

func _ready() -> void:
	originalChildCount = get_child_count()
	#if RespawnButton and not is_multiplayer_authority(): RespawnButton.hide()
	
	spawner.spawn_function = SpawnObj
	
	var t : Tank = tankScene.instantiate()
	var stats = t.get_property_list()

	for property : int in Upgrade.StatChange.size():
		var string : String = Upgrade.StatChange.find_key(property)
		if string:
			string = string.to_upper()
			for stat in stats:
				if stat["name"].to_upper() == string:
					baseStats[string] = (t.get(string))

	t.free()
	
	for i in InstantSpawns:
		Respawn(true)

@rpc("any_peer","call_local")
func Respawn(Invinsible : bool = false):
	#if is_multiplayer_authority():
		if myTanks.size() >= maxTanks: 
			return
		if Level.MainLevel == null:
			await Level.MainLevel.ready
		var data = {
			"spawn" : tankScene.resource_path,
			"position" : Level.MainLevel.GetRandomCoordinate(),
			"rotation" : randf_range(-PI,PI),
			"id" : str(multiplayer.get_unique_id()),
			"invinsible" : Invinsible
		}
		var t = spawner.spawn(data)
		if t is Tank:
			t.spawner = spawner
			#t.SetUp(multiplayer.get_unique_id())
	
func TankDied(tank : Tank, force : bool = false):
	#DropUpgrade(tank)
	if force:
		for thing in Temporaries:
			if thing:
				if thing is Bullet:
					thing.Destroy.rpc(true)
				if thing is LandMine:
					thing.Destroy.rpc(true)
	tankDied.emit(self, force)
	RoundHandler.handler.TankDied.rpc(get_path(), force)
	PublicEraseTank.rpc(tank.get_path())
	#myTanks.erase(tank)

func DropUpgrade(tank : Tank):
	if Upgrades.size() > 0:
		var rand : UpgradeObject = Upgrades.pick_random()
		rand.UnClaim.rpc(tank.get_path())

func DropUpgradeHere(vec : Vector3):
	if Upgrades.size() > 0:
		var rand : UpgradeObject = Upgrades.pick_random()
		rand.position = vec

func ChildDied(_node : Node):
	var childrenRemaining = (get_child_count())
	if not persistent and originalChildCount == childrenRemaining:
		queue_free()

func ResetAllStats():
	for p in myTanks:
		ResetStats(p)
		DoAllUpgrades(p)

func ResetStats(p: Tank):
	for stat : String in baseStats.keys():
		p.set(stat.to_upper(), baseStats[stat.to_upper()])

func DoAllUpgrades(p : Tank):
	for obj in Upgrades:
		for up in obj.Upgrades:
			UpgradeTank(up, p)

func UpgradeTank(up : Upgrade, p : Tank):
	#if not multiplayer.is_server():
		#return
	
	if not up or not p:
		return
	var stat : String = Upgrade.StatChange.find_key(up.Mod)
	stat = stat.to_upper()
	var value = p.get(stat.to_upper())
	match up.ModHow:
		Upgrade.HowToApply.Multiply:
			value = value * up.ModAmount
			pass
		Upgrade.HowToApply.Add:
			value = value + up.ModAmount
			pass
		Upgrade.HowToApply.Set:
			value = up.ModAmount
			pass
		Upgrade.HowToApply.None:
			pass
	p.set(stat, value)


func DowngradeTank(up : Upgrade, p : Tank):
	#if not multiplayer.is_server():
		#return
	if not up or not p:
		return
	var stat : String = Upgrade.StatChange.find_key(up.Mod)
	stat = stat.to_upper()
	var value = p.get(stat.to_upper())
	match up.ModHow:
		Upgrade.HowToApply.Multiply:
			value = value / up.ModAmount
			pass
		Upgrade.HowToApply.Add:
			value = value - up.ModAmount
			pass
		Upgrade.HowToApply.Set:
			pass
		Upgrade.HowToApply.None:
			pass
	p.set(stat, value)

func SpawnObj(data : Dictionary) -> Node:
	var obj : Node = load(data["spawn"]).instantiate()
	if data.has("id"):
		obj.set_multiplayer_authority(data["id"].to_int())
	if obj is Node3D:
		if data.has("position"):
			obj.position = data["position"]
		if data.has("rotation"):
			obj.rotation.y = data["rotation"]
		if data.has("scale"):
			obj.scale = data["scale"]
	if obj is Bullet:
		Temporaries.append(obj)
		obj.Died.connect(EraseThing)
		var string : String = data["parentTank"]
		var tank = get_node(string)
		obj.parentTank = tank
		if tank is Tank:
			tank.bulletsOut += 1
			var changingStats : Array = Upgrade.StatChange.keys()
			changingStats = changingStats.map(func(x):return x.to_upper())
			
			for stat in changingStats:
				if stat in obj:
					obj.set(stat, obj.parentTank.get(stat))
			#for stat in obj.get_property_list():
				#if stat["name"].to_upper() in changingStats:
					#obj.set(stat["name"].to_upper(), obj.parentTank.get(stat["name"].to_upper()))
			obj.Died.connect(obj.parentTank.BulletFreed)
	if obj is Tank:
		obj.position = Level.MainLevel.GetRandomCoordinate()
		obj.scale *= obj.PLAYERSIZE
		obj.spawner = spawner
		obj.connect("Died",TankDied)
		myTanks.append(obj)
		obj.container = self
		DoAllUpgrades(obj)
		obj.rotation.y = randf_range(-PI,PI)
		obj.SetUp()
		if data.has("invinsible"):
			obj.Invinsible = data["invinsible"]
	if obj is LandMine:
		Temporaries.append(obj)
		obj.Died.connect(EraseThing)
		var string : String = data["parentTank"]
		var tank = get_node(string)
		obj.connect("Died", tank.MineFreed)
		obj.spawner = spawner
		
		var changingStats : Array = Upgrade.StatChange.keys()
		changingStats = changingStats.map(func(x):return x.to_upper())
		for stat in changingStats:
			if stat in obj and stat in tank:
				obj.set(stat, tank.get(stat))
		if data.has("velocity"):
			if tank is Tank:
				obj.StartVelocity = (-tank.BarrelAiming.global_basis.z * data["velocity"])
	return obj

func Disconnect():
	if not multiplayer.is_server():
		for up in Upgrades:
			if up:
				up.Destory.rpc()
	queue_free()

@rpc("any_peer","call_local","reliable")
func PublicEraseTank(s : String):
	var tank = get_node_or_null(s)
	if tank:
		if tank is Tank:
			if tank in myTanks:
				myTanks.erase(tank)

func EraseThing(thing):
	if thing in Temporaries:
		thing.Destroy(true)
