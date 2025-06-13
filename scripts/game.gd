extends Node2D
@onready var resume: Control = $TileMap/Player/Resume

var player_inside := false  # track if player is inside the finish zone
@onready var reflect_label: Label = $TileMap/SECTION_5/reflect_label
@onready var sunset_label: Label = $TileMap/SECTION_5/sunset_label
@onready var how_to_label: Label = $TileMap/SECTION_1/how_to_label

func _ready():
	reflect_label.visible = false
	sunset_label.visible = false

	# Hide how-to label only on second+ climb
	if Save.goal_count == 1:
		how_to_label.visible = false


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
		reflect_label.visible = true  # Show label

func _on_goal_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
		reflect_label.visible = false  # Hide label

func _on_sunset_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		sunset_label.visible = true
		print("Player entered the sunset zone!")

func _on_sunset_body_exited(body: Node2D) -> void:
	print(body.name)
	if body.name == "Player":
		sunset_label.visible = false
		print("Player exited the sunset zone!")
