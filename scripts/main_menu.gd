extends Control

@onready var mainmenu_bgmusic: AudioStreamPlayer = $mainmenu_bgmusic

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	$BlackScreen.visible = true
	$BlackScreen.modulate.a = 0.0  # Start transparent

	var tween = get_tree().create_tween()
	tween.tween_property($BlackScreen, "modulate:a", 1.0, 1.0)  # Fade to black in 0.5 sec
	tween.connect("finished", Callable(self, "_on_black_screen_fade_complete"))

func _on_black_screen_fade_complete():
	get_tree().change_scene_to_file("res://opening_scene.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
