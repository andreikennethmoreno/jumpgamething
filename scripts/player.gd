extends CharacterBody2D

const SPEED = 130.0
const MIN_JUMP_VELOCITY = -200.0  # small jump
const MAX_JUMP_VELOCITY = -400.0  # full charge jump
const MAX_CHARGE_TIME = 1.0  # max time you can charge


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


var is_charging = false
var charge_timer = 0.0


func _physics_process(delta: float) -> void:
	# Add gravity if not on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# Set rotation to 0 when character lands (upright position)
		rotation = 0

	# Start charging
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_charging = true
		charge_timer = 0.0
		animated_sprite.play("jump")  # 👈 Play jump animation when charging starts
		print("Start charging")

	# Keep charging
	if is_charging and Input.is_action_pressed("jump") and is_on_floor():
		charge_timer += delta
		charge_timer = clamp(charge_timer, 0.0, MAX_CHARGE_TIME)
		# This ensures animation doesn't get stuck if you want to re-trigger
		if not animated_sprite.is_playing() or animated_sprite.animation != "jump":
			animated_sprite.play("jump")
		print("Charging: ", charge_timer)

	# Release to jump
	if is_charging and Input.is_action_just_released("jump") and is_on_floor():
		is_charging = false
		var t = charge_timer / MAX_CHARGE_TIME  # 0 to 1
		var jump_strength = lerp(MIN_JUMP_VELOCITY, MAX_JUMP_VELOCITY, t)
		velocity.y = jump_strength
		print("JUMPED with velocity: ", jump_strength)

	# Reset charge if landed
	if is_on_floor() and not is_charging:
		charge_timer = 0.0

	# Handle movement and sprite flipping based on input
	var direction := Input.get_axis("move_left", "move_right")

	# Flip sprites based on direction
	if direction > 0:
		animated_sprite.flip_h = false
	if direction < 0:
		animated_sprite.flip_h = true

	# Handle animations
	if is_charging:
		animated_sprite.play("charge")  # Play charging animation
	elif not is_on_floor():
		animated_sprite.play("jump")  # In air (jumping or falling)
	else:
		# On floor and not charging
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")

	# Handle horizontal movement
	if not is_charging:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)  # Smoothly stop if charging
	
	move_and_slide()
