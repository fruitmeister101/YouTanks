class_name Player extends TankContainer

@export var UI : Label

func _ready() -> void:
	GM.gm.MakeActivePlayer.rpc(get_path())
	super._ready()
	if is_multiplayer_authority():
		UpdateUI()
	else:
		UI.hide()

func UpgradeTank(up : Upgrade, p : Tank):
	super.UpgradeTank(up, p)
	UpdateUI()

func UpdateUI():
	if UI:
		for t in myTanks:
			var s : String = ""
			var stats = Upgrade.StatChange.keys()
			#stats.sort()
			for stat : String in stats:
				stat =  stat
				if stat.to_upper() in t:
					s += stat + " : " + str(t.get(stat.to_upper())) + "\n"
			UI.text = s
