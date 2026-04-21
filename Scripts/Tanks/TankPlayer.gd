class_name PlayerTank extends Tank

func _enter_tree() -> void:
	#set_multiplayer_authority(name.split(" ")[0].to_int())
	pass

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		if ShootCooldown > 0:
			ShootCooldown -= delta
		HandleInputs()
		Move(delta)
		move_and_slide()
		HandleTargeting(delta)
		HandleShooting(delta)

func _ready() -> void:
	super._ready()
	mainView = get_viewport()
	mainCam = mainView.get_camera_3d()

func HandleInputs():
	if is_multiplayer_authority():
		InputMove = Input.get_vector("TurnRight","TurnLeft","Forward","Reverse")
		targetPlane = Plane(Vector3.UP, FiringPoint.global_position.y)
		InputMousePos = mainView.get_mouse_position()
		var point = mainCam.project_ray_origin(InputMousePos)
		intercept = targetPlane.intersects_ray(point, mainCam.project_ray_normal(InputMousePos))
		if Input.is_action_pressed("Shoot"):
			Shoot()

func HandleTargeting(_delta: float = 0) -> void:
	if intercept:
		BarrelAiming.rotation_degrees.y = move_toward(BarrelAiming.rotation_degrees.y,clamp(basis.z.signed_angle_to(BarrelAiming.global_position-intercept,Vector3.UP),-0.5,0.5) / TAU * 360,BARRELAIMSPEED)
		var targetpos = -clamp((FiringPoint.global_position - intercept).dot(FiringPoint.global_basis.z),-10, 0)
		targetingCursor.position.z = targetpos / FiringPoint.global_basis.z.length_squared()
