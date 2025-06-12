extends Node

var starting_y_position: float = 0.0
var highest_y_position: float = 0.0
var fall_start_y: float = 0.0
var fall_count: int = 0
var teleport_count: int = 0
var play_timer := 0.0
var is_playing := false  # starts when entering gameplay
var goal_count = 0

func _process(delta):
	if is_playing:
		play_timer += delta
