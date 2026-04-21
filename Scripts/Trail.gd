class_name Trail extends Node3D

@export var line : LineRenderer
var trailLen : int = 60
var trailing : bool = true

func _physics_process(_delta: float) -> void:
	if trailing:
		line.points.push_front(global_position)
	if !trailing or line.points.size() >= trailLen:
		line.points.pop_back()
	if line.points.size() == 0:
		line.queue_free()
