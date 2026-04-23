class_name UpgradeObject extends RigidBody3D

@export var label : Label
@export var claimed : bool = false
@export var statUpBanner : PackedScene

var Upgrades : Array
var prefabName: String
var viewport : Viewport
var mainCam : Camera3D

func _ready() -> void:
	viewport = get_viewport()
	mainCam = viewport.get_camera_3d()
	Upgrades = find_children("*", "Upgrade", false)
	SetLabel()

func SetLabel():
	var s = ""
	s += str(prefabName)
	label.text = s
	

func _physics_process(_delta: float) -> void:
	if not claimed:
		var mypos : Vector2 = mainCam.unproject_position(global_position)
		label.position = mypos - label.size / 2.0

@rpc("any_peer","call_local","reliable")
func Claim(s : String):
	var tank = get_node_or_null(s)
	if tank:
		if tank is Tank:
			if statUpBanner:
				var note = statUpBanner.instantiate()
				if note is PowerUpLabel:
					note.Lifetime += Upgrades.size()
					note.Speed /= Upgrades.size()
					var tex : String = ""
					for up in Upgrades:
						if up is not Upgrade:
							continue
						tex += str(Upgrade.StatChange.find_key(up.Mod))
						var amount = up.ModAmount
						if up.ModHow == Upgrade.HowToApply.Multiply:
							amount = (amount - 1) * 100
						if int(amount) == amount:
							amount = int(amount)
						tex += " = " if up.ModHow == Upgrade.HowToApply.Set else " + " if amount > 0 else " - "
						tex += str(abs(amount))
						tex += "%" if up.ModHow == Upgrade.HowToApply.Multiply else ""
						tex += "\n"
					note.text = tex
					note.position = mainCam.unproject_position(global_position)
					add_child(note)
			
			if not claimed :
				tank.container.Upgrades.append(self)
				for up in Upgrades:
					tank.container.UpgradeTank(up, tank)
				position += Vector3.UP * 100
				freeze = true
				claimed = true
				label.hide()
				hide()

@rpc("any_peer","call_local","reliable")
func UnClaim(s : String):
	var tank = get_node_or_null(s)
	if tank:
		if tank is Tank:
			if claimed:
				tank.container.Upgrades.erase(self)
				var ups = Upgrades.duplicate()
				ups.reverse()
				for up in ups:
					tank.container.DowngradeTank(up, tank)
				position = tank.position + Vector3.UP * 2.0
				freeze = false
				claimed = false
				label.show()
				show()

func Destory():
	if not claimed:
		queue_free()
