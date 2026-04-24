class_name Tronizer extends CollisionShape3D

@export var b : Bullet
@export var trail : TrailRenderer
var dying : bool = false
var troning : bool = false

@export var points : Array[Vector3]
var full : bool = false
var s = ConcavePolygonShape3D.new()

func _ready() -> void:
	b.connect("Died", IsDying)
	s.backface_collision = true

func IsDying(_bullet : Bullet):
	dying = true



func _process(_delta: float) -> void:
	if dying and trail._trail_pieces.size() < 2:
		trail.queue_free()
		queue_free()
		
		return
	if not troning:
		return
	if not full or not dying:
		points.append(global_position)
		if not full and points.size() >= trail.lifetime/_delta:
			full = true
	if  (full and dying) or points.size() >= trail.lifetime/_delta:
		points.pop_front()
	
	
	if points.size() < 2:
		return
	var faces = PackedVector3Array()
	
	#for i in range(points.size() - 1):
	var pointClone = points.duplicate()
	var r = 0
	for x in points.size() - 2:
		var p1 = to_local(points[x])
		var p2 = to_local(points[x+1])
		var p3 = to_local(points[x+2])
		var dir1 = p1 - p2
		var dir2 = p2 - p3
		if dir1.is_equal_approx(dir2):
			pointClone.remove_at(x - r + 1)
			r += 1
	
	for i in pointClone.size() - 1:
		var p1 = to_local(pointClone[i])
		var p2 = to_local(pointClone[i+1])
		if p1 == p2:
			continue
		#var dir1 = p2 - p1
		#for x in range(i + 2, max):
			#var p3 = to_local(points[x])
			#var dir2 = p3 - p2
			#if dir1.is_equal_approx(dir2):
				#p2 = p3
				#i = x
			#else:
				#break
		
		var v0 = p1 + Vector3.UP * 10
		var v1 = p1 + Vector3.DOWN
		var v2 = p2 + Vector3.UP * 10
		var v3 = p2 + Vector3.DOWN

		faces.push_back(v0)
		faces.push_back(v1)
		faces.push_back(v2)
		
		faces.push_back(v1)
		faces.push_back(v3)
		faces.push_back(v2)
		
		faces.push_back(v0)
		faces.push_back(v2)
		faces.push_back(v1)
		
		faces.push_back(v1)
		faces.push_back(v2)
		faces.push_back(v3)
		
	
	s.data = faces
	shape = s









	
