class_name Level extends Node

static var MainLevel : Level

@export var testTanks: Array[PackedScene]
@export var testUpgrades: Array

func _enter_tree() -> void:
	MainLevel = self
	#testTanks = GM.gm.load_all_resources("Scenes/Tanks")
	testUpgrades = load_all_resources("res://Scenes/Upgrades")

func GetRandomCoordinate() -> Vector3:
	return Vector3(GM.gm.GetRandomFloat(-10,10), 0, GM.gm.GetRandomFloat(-10,10))

func SpawnRandomEnemy():
	var data = {
		"spawn" : testTanks.pick_random().resource_path,
		"position" : GetRandomCoordinate(),
		"rotation" : Vector3(0, randf_range(-PI,PI),0),
		"scale" : Vector3(0.6,0.6,0.6),
	}
	DoSpawn.rpc(data)
	
func SpawnRandomUpgrade():
	var up = testUpgrades.pick_random()
	var data = {
		"spawn" : up.resource_path,
		"position" : GetRandomCoordinate() + Vector3.UP * 3,
		"name" : up.resource_path.split("/")[-1].split(".")[0]
	}
	DoSpawn.rpc(data)

@rpc("any_peer","call_local")
func DoSpawn(data):
	if is_multiplayer_authority():
		GM.gm.ObjectSpawner.spawn(data)
	

func load_all_resources(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	if not DirAccess.dir_exists_absolute(path):
		push_error("Directory path does not exist: " + path)
		return resources
	var files = ResourceLoader.list_directory(path)
	for file_name in files:
		if file_name.ends_with("/"): continue
		var full_path = path.path_join(file_name)
		if ResourceLoader.exists(full_path):
			var res = ResourceLoader.load(full_path)
			if res is Resource:
				resources.append(res)
	return resources
