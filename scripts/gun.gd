extends Area2D #gun.gd

var kunai_thrown = false
var teleport_target_position: Vector2 = Vector2.ZERO  # Declare teleport_target_position
@export var player_ref: CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $WeaponPivot/AnimatedSprite2D
@onready var shooting_point: Marker2D = %ShootingPoint
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var line_2d: Line2D = $Line2D
@onready var wind_effect: AnimatedSprite2D = $WeaponPivot/AnimatedSprite2D/wind_effect


var muzzle_velocity := 200.0   # Gun's muzzle velocity
var custom_gravity := 500      # Gravity for the arc (for gun trajectory)
var gravity_increase_rate := 100  # Increase gravity over time for a sharper fall
@onready var actual_player_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var player_node: CharacterBody2D = $".."

var was_aiming = false
var max_points := 200    # cap on how many points we'll draw
var delta_time := 1/60.0 # assume 60fps for simulation step
var aiming = false       # To track if the player is holding the right mouse button
var charge_time := -1.0


func _ready():
	line_2d.hide()


func update_trajectory(delta):
	if Save.goal_count != 1:
		line_2d.clear_points()

		var start_pos = shooting_point.global_position
		var pos = start_pos
		var dir = weapon_pivot.global_transform.x.normalized()

		var velocity = dir * WeaponSettings.SPEED
		velocity.y += WeaponSettings.LAUNCH_Y_VELOCITY

		var space_state = get_world_2d().direct_space_state
		var travelled = 0.0

		for i in range(max_points):
			velocity.y += WeaponSettings.GRAVITY * delta_time
			var next_pos = pos + velocity * delta_time

			var query = PhysicsRayQueryParameters2D.create(pos, next_pos)
			query.exclude = [self]
			query.collision_mask = 1

			var result = space_state.intersect_ray(query)
			if result:
				line_2d.add_point(line_2d.to_local(result.position))
				break
			else:
				line_2d.add_point(line_2d.to_local(next_pos))
				pos = next_pos
				travelled += (next_pos - pos).length()

			if pos.y > get_viewport().get_visible_rect().size.y:
				break

# Rotate the weapon with the mouse cursor
func _process(delta):
	if player_ref == null or player_ref.is_dead:
		## player is dead → keep the sprite visible, but do nothing
		return

		# Rotate gun
	var mouse_pos = get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)

		# Allow shooting even while aiming
	if Input.is_action_just_pressed("shoot") and not kunai_thrown:
		shoot()

	# Aiming and charging logic
	if Input.is_action_pressed("teleport") and player_node.is_on_floor_only():
		aiming = true
		animated_sprite_2d.rotation += WeaponSettings.SPEED * delta

		player_node.disable_input()
		if not was_aiming:

			wind_effect.show()
			wind_effect.play()
			#$AudioStreamPlayer2D.play()
		animated_sprite_2d.play("shuriken")
		# Prevent overriding teleport animation
		if not actual_player_sprite.animation == "smoke":
			actual_player_sprite.play("charge")

		line_2d.show()

		# Increase charge time up to max
		charge_time = clamp(charge_time + delta, 0.0, WeaponSettings.CHARGE_TIME)
		var t = charge_time / WeaponSettings.CHARGE_TIME

		# Scale speed and range linearly based on charge
		WeaponSettings.SPEED = lerp(WeaponSettings.MIN_SPEED, WeaponSettings.MAX_SPEED, t)
		WeaponSettings.RANGE = lerp(100.0, WeaponSettings.MAX_RANGE, t)

		update_trajectory(delta)

	else:
		wind_effect.hide()
		wind_effect.stop()
		#$AudioStreamPlayer2D.stop()

		animated_sprite_2d.play("shuriken")

		player_node.enable_input()
		aiming = false
		line_2d.hide()

		# Reset when done aiming
		charge_time = 0.0
		WeaponSettings.SPEED = WeaponSettings.MIN_SPEED
		WeaponSettings.RANGE = 100.0

	was_aiming = aiming



# Shooting logic
func shoot():
	# Always update and show the trajectory in real-time
	line_2d.show()
	if kunai_thrown:
		print("Kunai is not ready to be thrown")
		return

	const BULLET = preload("res://scenes/bullet.tscn")
	var new_bullet = BULLET.instantiate()

	var direction = weapon_pivot.global_transform.x.normalized()
	var velocity = direction * WeaponSettings.SPEED
	velocity.y += WeaponSettings.LAUNCH_Y_VELOCITY

	# Set the initial position and rotation of the kunai
	new_bullet.global_position = shooting_point.global_position
	new_bullet.global_rotation = weapon_pivot.global_rotation
	# Pass the velocity as a custom signal or direct property
	new_bullet.set_velocity(velocity)  # Make sure 'velocity' is a valid property of the bullet

	# Connect to kunai_hit_player instead of kunai_stuck
	new_bullet.connect("kunai_hit_player", Callable(self, "_on_kunai_hit_player"))

	new_bullet.connect("teleport_ready", Callable(self, "_on_teleport_ready"))

	#new_bullet.connect("kunai_destroyed", Callable(self, "_on_kunai_destroyed"))

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
