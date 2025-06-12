extends Node2D
@onready var resume: Control = $TileMap/Player/Resume

var player_inside := false  # track if player is inside the finish zone


func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var h = total_seconds / 3600
	var m = (total_seconds % 3600) / 60
	var s = total_seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]



func _process(delta: float) -> void:
	var formatted_time = format_time(Save.play_timer)
	var height_meters = "%.2f" % abs(Save.highest_y_position)

	if player_inside and Input.is_action_just_pressed("ui_accept"):
		Save.is_playing = false
		print("____________________________")
		print("Time taken: ", Save.play_timer)
		print("Highest Y: ", Save.highest_y_position)
		print("Number of falls: ", Save.fall_count)
		print("Number of teleports: ", Save.teleport_count)
		print("____________________________")
		Save.goal_count += 1
		if Save.goal_count == 1:
			get_tree().change_scene_to_file("res://endingscene1.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/endingscene2.tscn")


func _on_goal_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = true
		print("Player reached the finish zone!")



func _on_goal_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
