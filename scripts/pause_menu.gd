extends Control

@onready var pause_menu: Control = $"."  # This should be the pause menu UI root node

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const GAME_SCENE_PATH := "res://scenes/game.tscn"

@onready var stats_section: Label = $stats_section


func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var h = total_seconds / 3600
	var m = (total_seconds % 3600) / 60
	var s = total_seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]


func _ready() -> void:
	pause_menu.visible = false
	pause_menu.modulate.a = 0.0  # Fully transparent at start

func _process(delta: float) -> void:
	var formatted_time = format_time(Save.play_timer)
	var height_meters = "%.2f" % abs(Save.highest_y_position)

	stats_section.text = " ⏱️ Time: %s\n\n 📈 Highest: %s\n\n 💥 Falls: %d\n\n 🌀 Teleports: %d" % [
		formatted_time,
		height_meters,
		Save.fall_count,
		Save.teleport_count
	]

	if Input.is_action_just_pressed("esc"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume()
	else:
		pause()

func resume():
	get_tree().paused = false
	pause_menu.visible = false
	pause_menu.modulate.a = 0.0  # Fully transparent

func pause():
	get_tree().paused = true
	pause_menu.visible = true
	pause_menu.modulate.a = 1.0  # Fully opaque

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	get_tree().paused = false  # Make sure to unpause before restarting
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false  # Unpause before switching scenes
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
