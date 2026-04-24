class_name Player extends TankContainer

@export var StatDisplayLabel : Label
@export var StatDisplayButton : Button
@export var PlayerColorBody : ColorPickerButton
@export var PlayerColorWheels : ColorPickerButton
@export var PlayerColorBarrel : ColorPickerButton

func _ready() -> void:
	GM.gm.MakeActivePlayer.rpc(get_path())
	super._ready()
	if is_multiplayer_authority():
		UpdateUI()
	else:
		StatDisplayButton.hide()

func ChangeColor(_color : Color = Color()):
	for t in myTanks:
		if t is PlayerTank:
			t.MainBodyForColoring.set_instance_shader_parameter("Color", PlayerColorBody.color)
			t.startColor = PlayerColorBody.color
			for wheel in t.WheelsForColoring:
				wheel.set_instance_shader_parameter("Color", PlayerColorWheels.color)
			t.BarrelForColoring.set_instance_shader_parameter("Color", PlayerColorBarrel.color)
		if t.targetingCursor:
			t.targetingCursor.get_child(0).set_instance_shader_parameter("Color", PlayerColorBarrel.color)
			

func UpgradeTank(up : Upgrade, p : Tank):
	super.UpgradeTank(up, p)
	UpdateUI()

func UpdateUI():
	if StatDisplayLabel:
		var max = 0
		for stat : String in Upgrade.StatChange.keys():
			if stat.length() > max:
				max = stat.length()
		for t in myTanks:
			var s : String = ""
			var stats = Upgrade.StatChange.keys()
			#stats.sort()
			for stat : String in stats:
				stat =  stat
				if stat.to_upper() in t:
					s += stat + " "
					for i in max - stat.length() + 1:
						s += "-"
					s += " : " + str(t.get(stat.to_upper())) + "\n"
			StatDisplayLabel.text = s

func ShowHideStats():
	if StatDisplayLabel.visible:
		StatDisplayLabel.hide()
	else:
		StatDisplayLabel.show()

func Respawn(Invinsible : bool = false):
	super.Respawn(Invinsible)
	ChangeColor()
