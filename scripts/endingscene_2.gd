extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var text_finished: bool = false

func _ready() -> void:
	pass
	# Connect the built-in signal (only needed if not connected in the editor)
	#animation_player.connect("animation_finished", Callable(self, "_on_animation_player_animation_finished"))

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print(anim_name)
	if anim_name == "typewriter_text":
		text_finished = true
	print("Number of goals: ", Save.goal_count)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and text_finished:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
