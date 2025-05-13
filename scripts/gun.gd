extends Area2D

var kunai_thrown = false
var teleport_target_position: Vector2 = Vector2.ZERO  # Declare teleport_target_position

@onready var animated_sprite_2d: AnimatedSprite2D = $WeaponPivot/AnimatedSprite2D
@onready var shooting_point: Marker2D = %ShootingPoint
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var line_2d: Line2D = $Line2D
var muzzle_velocity := 200.0   # Gun's muzzle velocity
var custom_gravity := 500      # Gravity for the arc (for gun trajectory)
var gravity_increase_rate := 100  # Increase gravity over time for a sharper fall

# gun.gd (excerpt)
const SPEED   = 200      # must match bullet.gd SPEED
const RANGE   = 100      # must match bullet.gd RANGE
const GRAVITY = 500.0    # must match bullet.gd GRAVITY

var max_points := 200    # cap on how many points we'll draw
var delta_time := 1/60.0 # assume 60fps for simulation step
var aiming = false       # To track if the player is holding the right mouse button

func _ready():
	line_2d.hide()

func update_trajectory(delta):
	line_2d.clear_points()

	var start_pos = shooting_point.global_position
	var pos       = start_pos
	var dir       = weapon_pivot.global_transform.x.normalized()

	var travelled = 0.0
	var vel       = Vector2.ZERO

	for i in range(max_points):
		line_2d.add_point(line_2d.to_local(pos))

		if travelled < RANGE:
			# PHASE 1: straight flight
			pos += dir * SPEED * delta_time
			travelled += SPEED * delta_time

			if travelled >= RANGE:
				# Preserve only horizontal speed
				vel = Vector2(dir.x * SPEED, 0)
		else:
			# PHASE 2: falling under gravity
			vel.y += GRAVITY * delta_time
			pos += vel * delta_time

		# stop if below ground
		if pos.y > get_viewport().get_visible_rect().size.y:
			break


# Rotate the weapon with the mouse cursor
func _process(delta):
	var mouse_pos = get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)

	# Update trajectory when aiming
	if aiming:
		line_2d.show()
		update_trajectory(delta)
	else:
		line_2d.hide()

# The shooting function is triggered by user input, not just by clicking
func _unhandled_input(event: InputEvent) -> void:
	# Shoot when left mouse button is pressed and kunai has not been thrown
	if event.is_action_pressed("shoot") and not kunai_thrown:
		shoot()

	# Handle teleportation with right mouse button
	if event.is_action_pressed("teleport"):
		aiming = true
		print("gun.gd: teleport triggered")

	elif event.is_action_released("teleport"):
		aiming = false
		line_2d.hide()  # Hide trajectory when right-click is released


# Shooting logic
func shoot():
	# Always update and show the trajectory in real-time
	line_2d.show()
	if kunai_thrown:
		print("Kunai is not ready to be thrown")
		return

	const BULLET = preload("res://scenes/bullet.tscn")
	var new_bullet = BULLET.instantiate()

	# Get the direction of the gun and shoot the kunai in that direction
	var direction = weapon_pivot.global_transform.x.normalized()  # Direction of the weapon
	var velocity = direction * muzzle_velocity

	# Set the initial position and rotation of the kunai
	new_bullet.global_position = shooting_point.global_position
	new_bullet.global_rotation = weapon_pivot.global_rotation
	# Pass the velocity as a custom signal or direct property
	new_bullet.set_velocity(velocity)  # Make sure 'velocity' is a valid property of the bullet

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

	print("gun.gd: Teleport signal received with pos: ", pos)
	TeleportManager.teleport_target_position = pos
	TeleportManager.can_teleport = true
		# Once teleportation is triggered, you can stop aiming
