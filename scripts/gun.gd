extends Area2D

var kunai_thrown = false


func _process(delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	look_at(mouse_position)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and not kunai_thrown:
		shoot()

func _on_kunai_stuck():
	print("Kunai stuck! You can shoot again.")
	kunai_thrown = false


func shoot():
	const BULLET = preload("res://scenes/bullet.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.global_rotation = %ShootingPoint.global_rotation

	get_tree().current_scene.add_child(new_bullet)
	
	# Connect signal BEFORE adding to scene tree
	new_bullet.connect("kunai_stuck", Callable(self, "_on_kunai_stuck"))

	get_tree().current_scene.add_child(new_bullet)

	kunai_thrown = true
