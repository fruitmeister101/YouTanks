class_name BasicTank extends Tank

@export var barrelSway : int = 1
@export var sway : int = 1
@export_range(0.5,10.0) var randPickTimer : float
@export var randAngleTimer : float
@export_range(1,100) var randShoot : int = 10
@export var MineDetection : Area3D

var Target : Tank


func _physics_process(delta: float) -> void:
	#if not is_multiplayer_authority(): return
	if GM.gm.ActivePlayers.size() > 0:
		var pl : Array[TankContainer] = GM.gm.ActivePlayers
		var players : Array[Tank] = []
		for p in pl:
			players.append_array(p.myTanks)
		players.filter(func(x): return x)
		players.sort_custom(func(x, _y)->float:return (global_position - x.global_position).length_squared())
		players = players.filter(func(x):return x if x else null)
		if players.size() > 0:
			Target = players[0]
		#if Target:
			#set_multiplayer_authority(Target.get_multiplayer_authority())
	ShootCooldown -= delta
	mineCooldown -= delta
	Move(delta)
	move_and_slide()
	HandleTargeting(delta)
	HandleShooting(delta)

func SetUp() -> void:
	super.SetUp()
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
					if randi_range(0,randShoot) == 0:
						Shoot()
				break
		else:
			break
	#line = points

func Shoot() -> void :

		super.Shoot()

func Move(_delta: float = 0) ->void:
	
	if (lastTrackPlaced - global_position).length() >= trackDist:
		PlaceTrack(_delta)
	velocity += get_gravity() * _delta
	var CloseToMine : bool = false
	var close : Node3D
	for b in MineDetection.get_overlapping_bodies():
		print(b.name)
		if b is LandMine:
			CloseToMine = true
			close = b
	if CloseToMine:
		TURNSPEED = abs(TURNSPEED) * sign(BarrelAiming.basis.z.signed_angle_to(close.global_position - global_position,Vector3.UP))
		pass
	angularVelocity = move_toward(angularVelocity, TURNSPEED / TAU * _delta, FRICTION * 0.125 * 0.125)
	rotate_y(angularVelocity)
	randAngleTimer -= _delta
	if randAngleTimer <= 0:
		PickRandomTimer(0.5,randPickTimer)
		PickRandomTurn()
	move_and_slide()

func PickRandomTimer(mn: float, mx: float):
	randAngleTimer = GM.gm.GetRandomFloat(mn,mx)

func PickRandomTurn():
	if Target:
		TURNSPEED = abs(TURNSPEED) * sign(basis.z.signed_angle_to(global_position - Target.global_position, Vector3.UP))
	else:
		TURNSPEED *= -1
