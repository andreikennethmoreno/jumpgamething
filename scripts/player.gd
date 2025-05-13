extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
var teleport_target_position: Vector2 = Vector2.ZERO
var can_teleport = false
var teleport_cooldown: float = 0  # Cooldown after teleportation
var teleport_timer: float = 0.0
var smoke_timer: float = 0.0  # Timer to control the smoke animation duration
var smoke_duration: float = 0.35  # How adlong smoke animation should play
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var just_teleported = false
@onready var gun: Area2D = $gun

@onready var smoke_effect: AudioStreamPlayer2D = $smoke_effect

func _ready():
	print("gun is ready")
	if gun:
		print("Gun found, connecting teleport_ready signal.")
		# Fix: Use the correct Callable connection
		gun.connect("teleport_ready", Callable(self, "_on_teleport_ready"))
	else:
		print("Gun not found! Check the node path.")


func _on_teleport_ready(pos: Vector2):
	if not TeleportManager.can_teleport:
		print("Teleport signal received with pos: ", pos)
		TeleportManager.teleport_target_position = pos
		TeleportManager.can_teleport = true
		print("Can teleport is now: ", TeleportManager.can_teleport)
	else:
		print("Teleport already allowed, ignoring additional signal.")

func _physics_process(delta: float) -> void:
	# Add gravity if in air
	if not is_on_floor():
		velocity += get_gravity() * delta

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

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		print("Jumped.")

# Movement input
	var direction := Input.get_axis("move_left", "move_right")

	var player_position = global_position

	# Get mouse position relative to the screen
	var mouse_position = get_global_mouse_position() - player_position

	# Flip sprite based on mouse position
	if mouse_position.x < 0:  # Mouse on the left side
		animated_sprite.flip_h = true
	elif mouse_position.x > 0:  # Mouse on the right side
		animated_sprite.flip_h = false

	# Override with input direction (if applicable)
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true


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

	move_and_slide()
