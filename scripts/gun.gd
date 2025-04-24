#gun.gd
extends Area2D

var kunai_thrown = false
var teleport_target_position: Vector2 = Vector2.ZERO  # Declare teleport_target_position

@onready var animated_sprite_2d: AnimatedSprite2D = $WeaponPivot/AnimatedSprite2D


func _process(delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	look_at(mouse_position)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and not kunai_thrown:
		shoot()


func shoot():
	if kunai_thrown:
		print("Kunai is not ready to be thrown")
		return
	const BULLET = preload("res://scenes/bullet.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.global_rotation = %ShootingPoint.global_rotation
	# Connect to kunai_hit_player instead of kunai_stuck
	new_bullet.connect("kunai_hit_player", Callable(self, "_on_kunai_hit_player"))
	new_bullet.connect("teleport_ready", Callable(self, "_on_teleport_ready"))

	get_tree().current_scene.add_child(new_bullet)
	# Hide shuriken after shooting
	animated_sprite_2d.visible = false

	kunai_thrown = true
	print("Kunai shot!")


func _on_kunai_hit_player():
	print("Kunai hit the player! You can shoot again.")
	kunai_thrown = false
	# Show shuriken again when it hits the player
	animated_sprite_2d.visible = true

func _on_teleport_ready(pos: Vector2):
	print("Teleport signal received with pos: ", pos)
	TeleportManager.teleport_target_position = pos
	TeleportManager.can_teleport = true
