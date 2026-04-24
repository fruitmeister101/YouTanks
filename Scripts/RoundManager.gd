class_name RoundHandler extends Node

@export var StartGameButton : Button
@export var textLabel : Label

@export var upgradeSpawnsPerPlayer : int = 5
@export var upgradesLeftBehind : int = 1

static var handler : RoundHandler
var winners : Array[TankContainer]
var losers : Array[TankContainer]
var spawnedUpgrades : Array[UpgradeObject]

#var ActivePlayers : Array[TankContainer]

var InGame : bool = false

var SomebodyWon : bool = false


func _ready() -> void:
	textLabel.text = "Waiting for Players to Join"
	handler = self
	multiplayer.connected_to_server.connect(ConnectedToServer)

func ShowLabel():
	textLabel.show()

func ConnectedToServer() -> void:
	if not multiplayer.is_server():
		StartGameButton.hide()

func StartGame():
	UpdateText.rpc("Starting Match -- GetReady")
	#ActivePlayers = GM.gm.ActivePlayers
	StartGameButton.hide()
	
	
	InGame = true
	
	losers = GM.gm.ActivePlayers.duplicate()
	
	await EndRound()
	



func StartRound():
	losers.clear()
	for p in GM.gm.ActivePlayers:
		for t in p.myTanks:
			t.Destroy.rpc(true)
		p.Respawn.rpc(true)
	UpdateText.rpc("GetReady")
	await get_tree().create_timer(3).timeout
	for p in GM.gm.ActivePlayers:
		for t in p.myTanks:
			t.MakeVincible.rpc()
	UpdateText.rpc("FIGHT!!")
	

func EndRound(whoWon : Array[TankContainer] = []):
	SomebodyWon = true
	if whoWon.size() > 0:
		winners = whoWon
	await get_tree().create_timer(3).timeout
	UpdateText.rpc("Upgrade Time")
	for p in GM.gm.ActivePlayers:
		for t in p.myTanks:
			t.Destroy.rpc(true)
	await get_tree().create_timer(1).timeout
	#else:
		#for i in 3:
			#spawnedUpgrades.append(Level.MainLevel.SpawnRandomUpgrade())
	
	var tempArray = losers.duplicate()
	losers.clear()
	for x in tempArray.size():
		var t = tempArray.pick_random()
		tempArray.erase(t)
		losers.append(t)
	
	for l in losers:
		if spawnedUpgrades.size() > 0:
			for i in spawnedUpgrades.size() - upgradesLeftBehind:
				var up = spawnedUpgrades.pick_random()
				spawnedUpgrades.erase(up)
				up.Destory.rpc()
		await ChooseUpgrade()
		l.Respawn.rpc(true)
		spawnedUpgrades.erase( await l.choseUpgrade)
		for t in l.myTanks:
			t.Destroy.rpc(true)
	
	for up in spawnedUpgrades:
		if up:
			up.Destory.rpc()
	spawnedUpgrades.clear()

	UpdateText.rpc("Upgrading Done")
	await get_tree().create_timer(2).timeout
	StartRound()
	SomebodyWon = false
	

func ChooseUpgrade():
	await get_tree().create_timer(1.5).timeout
	for i in upgradeSpawnsPerPlayer:
		spawnedUpgrades.append( Level.MainLevel.SpawnRandomUpgrade() )
		await get_tree().create_timer(0.25).timeout
	

@rpc("any_peer","call_local")
func TankDied(container : String, force : bool = false):
	if not multiplayer.is_server():
		return
	if SomebodyWon:
		return
	if force:
		return
	var c = get_node_or_null(container)
	if c is TankContainer:
		
		losers.append(c)
		if losers.size() >= (GM.gm.ActivePlayers.size() - 1):
			var whoWon = GM.gm.ActivePlayers.filter(func(x):return x not in losers)
			UpdateText.rpc("FINISH!!")
			EndRound(whoWon)

func SpawnRandomUpgrade():
	var up : UpgradeObject = Level.MainLevel.SpawnRandomUpgrade()
	spawnedUpgrades.append(up)
	up.destoryed.connect(UpgradeDestoryed)

func UpgradeDestoryed(up: UpgradeObject):
	spawnedUpgrades.erase(up)

@rpc("call_local")
func UpdateText(s : String):
	textLabel.show()
	textLabel.text = s
