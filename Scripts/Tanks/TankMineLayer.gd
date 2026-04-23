class_name MineLayer extends MoverTank

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Target:
		if (global_position - Target.global_position).length() < MINEEXPLOSIONRADIUS * MINESIZE * 0.4:
			LayMine()
	
