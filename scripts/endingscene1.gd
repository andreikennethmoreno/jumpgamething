extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var climb: Button = $GridContainer/climb
@onready var rest: Button = $GridContainer/rest
@onready var label: Label = $Label

var text_finished: bool = false
var selected_path: String = ""  # path to scene selected
var choice_made: bool = false  # whether climb or rest was pressed

func _ready() -> void:
	climb.visible = false
	rest.visible = false
	animation_player.connect("animation_finished", Callable(self, "_on_animation_player_animation_finished"))

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "typewriter_text":
		text_finished = true
		if not choice_made:
			climb.visible = true
			rest.visible = true
		_check_and_transition()

func _on_climb_pressed() -> void:
	if choice_made:
		return
	choice_made = true
	_hide_buttons()
	label.text = ""
	selected_path = "res://scenes/game.tscn"
	_play_new_text("You chose to climb again.\n\nNo guidance. No glory.")

func _on_rest_pressed() -> void:
	if choice_made:
		return
	choice_made = true
	Save.goal_count = 0
	_hide_buttons()
	label.text = ""
	selected_path = "res://scenes/main_menu.tscn"
	_play_new_text("You chose to rest.\n\nThey will remember the mask.")

func _hide_buttons() -> void:
	climb.visible = false
	rest.visible = false

func _play_new_text(new_text: String) -> void:
	label.text = new_text
	text_finished = false
	animation_player.play("typewriter_text")

func _check_and_transition() -> void:
	if text_finished and choice_made:
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file(selected_path)
