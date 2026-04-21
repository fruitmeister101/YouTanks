class_name BasicTank extends Tank

@export var barrelSway : int = 1
@export var sway : int = 1
@export var randSwayTimer : float
@export var randAngleTimer : float

var Target

func _enter_tree() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return
	if GM.gm.ActivePlayers.size() > 0:
		var pl : Array[TankContainer] = GM.gm.ActivePlayers
		var players : Array[Tank] = []
		for p in pl:
			players.append_array(p.myTanks)
		players.sort_custom(func(x, _y)->float:return (global_position - x.global_position).length_squared())
		if players.size() > 0:
			Target = players[0]
		#set_multiplayer_authority(players[0].name.to_int())
	ShootCooldown -= delta
	Move(delta)
	move_and_slide()
	HandleTargeting(delta)
	HandleShooting(delta)

func SetUp(id:int) -> void:
	super.SetUp(id)
	sway = randi_range(0,1) * 2 - 1
	barrelSway = randi_range(0,1) * 2 - 1

func HandleTargeting(_delta: float = 0) -> void:
	BarrelAiming.rotation_degrees.y = move_toward(BarrelAiming.rotation_degrees.y, MaxAimFromForward * barrelSway, BARRELAIMSPEED)
	
	if abs(BarrelAiming.rotation_degrees.y) >= MaxAimFromForward:
		barrelSway *= -1

func HandleShooting(_delta: float = 0) -> void:
	if ShootCooldown > 0:
		ShootCooldown -= _delta
	var point = FiringPoint.global_position
	var points : Array[Vector3] = [point]
	var dir = FiringPoint.global_basis.z
	for i in BULLETBOUNCES + 1:
		var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(point, point + dir * 150, 1)
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		if hit:
			point = hit.position
			points.append(point)
			dir = dir.bounce(hit.normal)
			if hit.collider is Tank or hit.collider is UpgradeObject:
				if hit.collider is PlayerTank or hit.collider is UpgradeObject:
					if randi_range(0,9) == 0:
						Shoot()
				break
		else:
			break
	line.points = points

func Shoot() -> void :

		super.Shoot()

func Move(_delta: float = 0) ->void:
	
	if (lastTrackPlaced - global_position).length() >= trackDist:
		PlaceTrack(_delta)
	rotation.y = rotation.y + (TURNSPEED * _delta / TAU)
	randAngleTimer -= _delta
	if randAngleTimer <= 0:
		PickRandomTimer(1,3)
		PickRandomTurn()
	move_and_slide()

func PickRandomTimer(mn: int, mx: int):
	randAngleTimer = GM.gm.GetRandomFloat(mn,mx)

func PickRandomTurn():
	if Target:
		TURNSPEED = abs(TURNSPEED) * sign(basis.z.signed_angle_to(global_position - Target.global_position, Vector3.UP))
	else:
		TURNSPEED *= -1
