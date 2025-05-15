# Camera2D.gd
extends Camera2D

@export var x_margin := 100
@export var y_margin := 100
@export var enable_smoothing := false
@export var smoothing_speed := 5.0

@onready var player: CharacterBody2D = $"../Player"

func _process(delta: float) -> void:
	if not player:
		return

	var cam_pos: Vector2 = global_position
	var diff: Vector2 = player.global_position - cam_pos

	# Horizontal movement
	if abs(diff.x) > x_margin:
		cam_pos.x += diff.x - sign(diff.x) * x_margin

	# Vertical movement
	if abs(diff.y) > y_margin:
		cam_pos.y += diff.y - sign(diff.y) * y_margin

	# Apply smoothing if enabled
	if enable_smoothing:
		global_position = global_position.lerp(cam_pos, delta * smoothing_speed)
	else:
		global_position = cam_pos
