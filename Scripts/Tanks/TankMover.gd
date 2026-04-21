class_name MoverTank extends BasicTank

func Move(_delta: float = 0) ->void:
	velocity = basis.z * -MOVESPEED + Vector3.UP * velocity.y * _delta
	super.Move(_delta)
