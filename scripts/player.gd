extends CharacterBody2D #player.gd

const SPEED = 130.0
const JUMP_VELOCITY = -250.0

var input_enabled: bool = true
var teleport_target_position: Vector2 = Vector2.ZERO
var can_teleport = false
var teleport_cooldown: float = 0  # Cooldown after teleportation
var teleport_timer: float = 0.0
var smoke_timer: float = 0.0  # Timer to control the smoke animation duration
var smoke_duration: float = 0.1  # How dadlong smoke animation should play
var is_hit = false
var knockback_timer := 0.3
var just_teleported = false
var hearts_list : Array[TextureRect] = []
var health = 1
var is_dead = false
var _suffocating := false
var started_fall = false
var fall_distance = 0
var splat_timer = 0.0

@onready var gun: Area2D = $gun
#@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $normal_animated_sprites


@onready var player_collision: CollisionShape2D = $CollisionShape2D
@onready var smoke_effect: AudioStreamPlayer2D = $smoke_effect
@onready var hit_sound: AudioStreamPlayer2D = $hit_sound
@onready var stats_section: Label = $healthbar/stats_section
@onready var normal_animated_sprites: AnimatedSprite2D = $normal_animated_sprites
@onready var pro_animated_sprites: AnimatedSprite2D = $pro_animated_sprites


func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var h = total_seconds / 3600
	var m = (total_seconds % 3600) / 60
	var s = total_seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]


func _update_sprite_mode():
	if Save.goal_count != 1:
		normal_animated_sprites.visible = true
		pro_animated_sprites.visible = false
		animated_sprite = normal_animated_sprites
	else:
		normal_animated_sprites.visible = false
		pro_animated_sprites.visible = true
		animated_sprite = pro_animated_sprites


func _ready():
	_update_sprite_mode()

	Save.is_playing = true
	floor_max_angle = deg_to_rad(42)
	var hearts_parent = $healthbar/HBoxContainer
	hearts_list = []  # Ensure it's empty before filling
	for child in hearts_parent.get_children():
		if child is TextureRect:
			hearts_list.append(child)
	print("Hearts loaded:", hearts_list.size())
	update_heart_display()
	#print(hearts_list)
	print("gun is ready")
	if gun:
		print("Gun found, connecting teleport_ready signal.")
		# Fix: Use the correct Callable connection
		gun.connect("teleport_ready", Callable(self, "_on_teleport_ready"))
	else:
		print("Gun not found! Check the node path.")

	gun.set("player_ref", self)


func _on_teleport_ready(pos: Vector2):
	if not TeleportManager.can_teleport:
		print("Teleport signal received with pos: ", pos)
		TeleportManager.teleport_target_position = pos
		TeleportManager.can_teleport = true
		print("Can teleport is now: ", TeleportManager.can_teleport)
	else:
		print("Teleport already allowed, ignoring additional signal.")

func _physics_process(delta: float) -> void:
	_update_sprite_mode()

	var formatted_time = format_time(Save.play_timer)
	var height_meters = "%.2f" % abs(Save.highest_y_position)


	var player_position = global_position

	# Get mouse position relative to the screen
	var mouse_position = get_global_mouse_position() - player_position

		# Flip sprite based on mouse positinn
	if mouse_position.x < 0:  # Mouse on the left side
		animated_sprite.flip_h = true
	elif mouse_position.x > 0:  # Mouse on the right side
		animated_sprite.flip_h = false


	if not input_enabled:
		return

	if is_dead:
		return

	if _suffocating:
		velocity.y = 0  # stop vertical movement
		velocity.x = 0  # optional: stop horizontal movement if you want
		move_and_slide()
		return  # skip rest of movement and gravity when suffocating

	if is_hit:
		move_and_slide()
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			is_hit = false
		return

	# Add gravity if in air
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_wall_only() and velocity.y > 0:
		print("rolling")

		var rotation_offset := Vector2(3, 3)
		if get_real_velocity().x < 0:
			rotation_offset = Vector2(3, 3)
		else:
			rotation_offset = Vector2(-3, 3)

		animated_sprite.flip_h = get_real_velocity().x < 0
		#animated_sprite.offset = rotation_offset

	if teleport_timer > 0.0:
		teleport_timer -= delta
		print("Teleport cooling down:", teleport_timer)
		if teleport_timer <= 0.0:
			teleport_timer = 0.0
			TeleportManager.can_teleport = true

	if Input.is_action_just_pressed("teleport") and TeleportManager.can_teleport and teleport_timer == 0.0 :
		global_position = TeleportManager.teleport_target_position
		print("player gd: teleport triggered")
		print("player gd: Teleporting to position:", global_position)
		TeleportManager.can_teleport = false
		teleport_timer = teleport_cooldown
		smoke_timer = smoke_duration
		just_teleported = true
		smoke_effect.play()
		gun.visible = false  # hide while in smoke
		Save.teleport_count += 1
		for kunai in get_tree().get_nodes_in_group("stuck_bullets"):
			kunai.try_retrieve_on_teleport(self)
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		print("Jumped.")

	# Movement input
	var direction := Input.get_axis("move_left", "move_right")


	# Override with input direction (if applicable)
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Track fall distance only when in the air and falling down
	if not is_on_floor() and velocity.y > 0:
		fall_distance += velocity.y * delta
	else:
		# Reset when on the floor or going upward
		fall_distance = 0


	# Handle animation
	if just_teleported:
		animated_sprite.play("smoke")
		smoke_timer -= delta
		if smoke_timer <= 0:
			animated_sprite.stop()
			just_teleported = false
		if gun:
			gun.visible = false
	else:
		# Make the gun visible again after the smoke animation ends
		if gun:
			gun.visible = true

		if splat_timer > 0:
			splat_timer -= delta
			return

		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		else:
			animated_sprite.play("jump")

	# Horizontal movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Horizontal movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

		# Update the highest posddadition (lowest y value)
	if global_position.y < Save.highest_y_position:
		Save.highest_y_position = global_position.y
		var vertical_distance_up = Save.starting_y_position - Save.highest_y_position
		print("Player height climbed: ", round(vertical_distance_up), " pixels")

	# Skip fall logic if just teleported
	if just_teleported:
		started_fall = false
		Save.fall_start_y = 0.0
	else:
		# Start tracking fall if falling down and not on the floor
		if velocity.y > 0 and !is_on_floor() and !started_fall:
			started_fall = true
			Save.fall_start_y = global_position.y

	if is_on_floor() and started_fall:
		var fall_distance = global_position.y - Save.fall_start_y
		if fall_distance > 150:
			Save.fall_start_y = 0.0
			Save.fall_count += 1

			animated_sprite.play("splat")
			splat_timer = 0.3

			hit_sound.play()


			print("Fall animation finished! Total falls:", Save.fall_count)
			started_fall = false

		else:
			started_fall = false
			Save.fall_start_y = 0.0

	move_and_slide()

func _on_organs_body_entered(body: Node2D) -> void:
	if _suffocating:
		return
	_suffocating = true
	set_process_input(false)         # stops _input() from being called :contentReference[oaicite:0]{index=0}
	while _suffocating:
		hit(Vector2.ZERO)
		update_heart_display()
		print("player.gd: player is suffocating")
		await get_tree().create_timer(0.5).timeout
		if health <= 0:
			_suffocating = false
			# Death and reload handled elsewhere
			disable_input()

func hit(knockback: Vector2) -> void:
	if is_dead:
		return

	health -=1
	update_heart_display()
		# player is dead

	if health <= 0:
		is_dead = true
		# Play death animation once, start your 2s timer
		animated_sprite.play("death")
		#gun.visible = false
		$DeathTimer.start()
		return

	is_hit = true
	# disable further input/physics
	velocity = knockback
	hit_sound.play()
	# play die animation
	animated_sprite.play("hit")
	knockback_timer = 0.3

func heal() -> void:
	print("player.gd: healing")
	health += 1
	update_heart_display()

func update_heart_display():
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < health

	if health == 1:
		hearts_list[0].get_child(0).play("beating")
	elif health > 1:
		hearts_list[0].get_child(0).play("idle")

func _on_death_timer_timeout() -> void:
	get_tree().reload_current_scene()

func disable_input():
	input_enabled = false

func enable_input():
	input_enabled = true
