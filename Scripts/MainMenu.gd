class_name GM extends Node

var lobbyID : int = 0
var peer : SteamMultiplayerPeer
@export var PlayerScene : PackedScene
@export var levelScene : PackedScene
var isHost : bool = false
@export var UI : Node
@export var GameUI : Node
@export var JoinButton : Button
@export var LobbyText : LineEdit
var isJoining : bool = false
var Randy : RandomNumberGenerator = RandomNumberGenerator.new()
@export var randSeed : int

static var gm : GM
@export var objectSpawnLocation : Node
@export var mainCam : Camera3D


const localAddress = "localhost"
const port = 42069

@export var LevelSpawner : MultiplayerSpawner
@export var ObjectSpawner : MultiplayerSpawner

@export var ActivePlayers : Array[TankContainer]

func load_all_resources(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	# list_directory returns original file names even in exported builds
	var files = ResourceLoader.list_directory(path)
	
	for file_name in files:
		var full_path = path.path_join(file_name)
		var res = ResourceLoader.load(full_path)
		if res:
			resources.append(res)
			
	return resources




func HostLocal():
	var p = ENetMultiplayerPeer.new()
	p.create_server(port)
	multiplayer.multiplayer_peer = p
	
	if not multiplayer.peer_connected.is_connected(AddPlayer):
		multiplayer.peer_connected.connect(AddPlayer)
	if not multiplayer.peer_disconnected.is_connected(RemovePlayer):
		multiplayer.peer_disconnected.connect(RemovePlayer)
	StartLevel("")
	AddPlayer(multiplayer.get_unique_id())
	UI.hide()
	GameUI.show()

func JoinLocal():
	var p = ENetMultiplayerPeer.new()
	if p.create_client(localAddress, port) != Error.OK:
		return
	multiplayer.multiplayer_peer = p
	multiplayer.server_disconnected.connect(DisconnectFromServer)
	UI.hide()
	GameUI.show()

func _ready() -> void:
	randSeed = Randy.seed
	
	gm = self
	LevelSpawner.spawn_function = Spawn
	ObjectSpawner.spawn_function = SpawnObj
	
	set_multiplayer_authority(1)
	
	print("Steam Initialized: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(LobbyCreated)
	Steam.lobby_joined.connect(LobbyJoined)
	
	for loaded in load_all_resources("res://Scenes/Levels/"):
		LevelSpawner.add_spawnable_scene(loaded.resource_path)
		var l = loaded.instantiate()
		l.free()
		
	#for loaded in load_all_resources("res://Scenes/Tanks/"):
		#LevelSpawner.add_spawnable_scene(loaded.resource_path)
		#var l = loaded.instantiate()
		#l.free()
		
	for loaded in load_all_resources("res://Scenes/ObjectSpawns/"):
		ObjectSpawner.add_spawnable_scene(loaded.resource_path)
		var l = loaded.instantiate()
		l.free()
		
	for loaded in load_all_resources("res://Scenes/Upgrades/"):
		ObjectSpawner.add_spawnable_scene(loaded.resource_path)
		var l = loaded.instantiate()
		l.free()

func HostPressed() -> void:
	HostLobby()

func HostLobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)
	isHost = true

func LobbyCreated(result : int, LobbyID : int):
	if result == Steam.Result.RESULT_OK:
		UI.hide()
		
		lobbyID = LobbyID
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		if not multiplayer.peer_connected.is_connected(AddPlayer):
			multiplayer.peer_connected.connect(AddPlayer)
		if not multiplayer.peer_disconnected.is_connected(RemovePlayer):
			multiplayer.peer_disconnected.connect(RemovePlayer)
		
		print("Lobby ID: ",lobbyID)
		DisplayServer.clipboard_set(str(lobbyID))
		#add_child(levelScene.instantiate(), true)
		StartLevel("")
		AddPlayer(multiplayer.get_unique_id())

func JoinPressed() -> void:
	JoinLobby(LobbyText.text.to_int())

func JoinLobby(LobbyID : int):
	if isJoining:
		return
	isJoining = true
	Steam.joinLobby(LobbyID)

func LobbyJoined(LobbyID : int, _Permissions : int, _Locked : bool, _Response : int):
	if !isJoining:
		return
	
	lobbyID = LobbyID
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobbyID))
	multiplayer.multiplayer_peer = peer
	UI.hide()
	GameUI.show()
	
	isJoining = false

func TextUpdated(new_text: String) -> void:
	JoinButton.disabled = new_text.length() == 0
	#lobbyID = new_text.to_int()

func AddPlayer(id : int = 1):
	#if multiplayer.is_server():
		var data = {
			"spawn" : PlayerScene.resource_path,
			"id" : str(id),
		}
		LevelSpawner.spawn(data)
	

func RemovePlayer(_id : int):
	pass

func DisconnectFromServer():
	UI.show()
	GameUI.hide()
	for child in objectSpawnLocation.get_children():
		if child is TankContainer:
			child.Disconnect()
		elif child is Bullet:
			child.Destroy()
		else:
			child.queue_free()
	ActivePlayers.clear()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func StartLevel(_path : String) -> void:
	var data = {
		"spawn" : levelScene.resource_path
	}
	LevelSpawner.spawn(data)
	UI.hide()
	GameUI.show()

func SpawnObj(data : Dictionary) -> Node:
	var obj : Node = load(data["spawn"]).instantiate()
	if data.has("id"):
		obj.set_multiplayer_authority(data["id"].to_int())
	if data.has("name"):
		obj.prefabName = data["name"]
	if obj is Node3D:
		if data.has("position"):
			obj.position = data["position"]
		if data.has("rotation"):
			obj.rotation.y = data["rotation"].y
		if data.has("scale"):
			obj.scale = data["scale"]
	return obj

func Spawn(data : Dictionary) -> Node:
	var obj = load(data["spawn"]).instantiate()
	if obj is Level:
		Level.MainLevel = obj
	if data.has("id"):
		obj.set_multiplayer_authority(data["id"].to_int())
	return obj

func Pause() -> void:
	pass

func Respawn() -> void:
	AddPlayer(multiplayer.get_unique_id())

func ExitToMenu() -> void:
	DisconnectFromServer()
	for child : Node in objectSpawnLocation.get_children():
		if child is Tank:
			child.Destroy()
		elif child is Bullet:
			child.Destroy()
		else:
			child.queue_free()
	ActivePlayers.clear()

func GetRandomFloat(mn: float,mx: float):
	return Randy.randf_range(mn,mx)
	
func GetRandomInt(mn: int,mx: int):
	return Randy.randi_range(mn,mx)

@rpc("any_peer","call_local")
func MakeActivePlayer(s : String):
	var p = get_node_or_null(s)
	if p is TankContainer:
		if not ActivePlayers.has(p):
			ActivePlayers.append(p)
