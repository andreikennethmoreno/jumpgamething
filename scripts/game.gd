extends Node2D

@onready var line = $Line2D
@onready var shoot_point_node= $Player/gun/WeaponPivot/ShootPoint

var max_points = 200
var point_spacing = 0.05  # Time step for prediction

func _physics_process(delta: float) -> void:
	update_trajectory()

func _ready() -> void:
	if shoot_point_node == null:
		print("ShootPoint node not found!")
	else:
		print("ShootPoint node found.")

func update_trajectory():
	line.clear_points()
	var shoot_point = shoot_point_node.global_position
	var dir = shoot_point_node.global_transform.x.normalized()
	var speed = $Player.bullet_velocity
	var gravity = $Player.gravity

	var pos = shoot_point
	var vel = dir * speed

	for i in max_points:
		line.add_point(pos)
		vel.y += gravity * point_spacing
		pos += vel * point_spacing

		# Stop if hitting the terrain polygon
		if Geometry2D.is_point_in_polygon($Terrain/Polygon2D.to_local(pos), $Terrain/Polygon2D.polygon):
			break


func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
