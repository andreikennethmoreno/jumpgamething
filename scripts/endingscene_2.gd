extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var text_finished: bool = false

func _ready() -> void:
	pass
	# Connect the built-in signal (only needed if not connected in the editor)
	#animation_player.connect("animation_finished", Callable(self, "_on_animation_player_animation_finished"))

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "typewriter_text":
		text_finished = true
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
