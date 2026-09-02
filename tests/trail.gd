extends Node2D

@export var line: Line2D
@export var max_points := 10
@export var point_spacing := 1.0
@export var trail_length := 30

var distance_accum := 10.0


func _ready() -> void:
	if line == null:
		printerr("line is null")
		return
	line.clear_points()


func _process(_delta: float) -> void:
	if line == null:
		return
	var mouse_pos = get_viewport().get_mouse_position()
	if line.get_point_count() > 0:
		var first_point = line.get_point_position(0)
		var dist = first_point.distance_to(mouse_pos)
		var length = min(dist, trail_length)
		line.set_point_position(1, mouse_pos)
		line.set_point_position(0, mouse_pos + mouse_pos.direction_to(first_point) * length)
	else:
		line.add_point(mouse_pos)
		line.add_point(mouse_pos)
	#if line.get_point_count() > 0:
		#var last_point = line.get_point_position(line.get_point_count() - 1)
		#var distance = mouse_pos.distance_to(last_point)
		#distance_accum += distance
	#else:
		#distance_accum = point_spacing
	#if distance_accum >= point_spacing:
		#line.add_point(mouse_pos)
		#distance_accum = 0.0
		#if line.get_point_count() > max_points:
			#line.remove_point(0)


func reset_trail():
	if line != null:
		line.clear_points()
		distance_accum = 0.0
