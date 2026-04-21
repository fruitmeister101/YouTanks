class_name Player extends TankContainer

func _ready() -> void:
	GM.gm.ActivePlayers.append(self)
	super._ready()
