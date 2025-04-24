extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
var teleport_target_position: Vector2 = Vector2.ZERO
var can_teleport = false
var teleport_cooldown: float = 0.5  # 0.5 seconds cooldown after teleportation
var teleport_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	print("gun is ready")
	var gun = $gun  # Make sure this path is correct
	if gun:
		print("Gun found, connecting teleport_ready signal.")
		# Fix: Use the correct Callable connection
		gun.connect("teleport_ready", Callable(self, "_on_teleport_ready"))
	else:
		print("Gun not found! Check the node path.")

func _on_teleport_ready(pos: Vector2):
	print("Teleport signal received with pos: ", pos)
	teleport_target_position = pos
	can_teleport = true  # Ensure this is correctly set
	print("Can teleport is now: ", can_teleport)  # Debug line to check the flag's state

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("teleport") and TeleportManager.can_teleport:
		# Perform teleportation
		global_position = TeleportManager.teleport_target_position
		print("Teleporting to position: ", global_position)

		# Disable further teleportation immediately
		TeleportManager.can_teleport = false
		teleport_timer = teleport_cooldown  # Start cooldown timer

		# Optionally, you can play a teleport animation here
		# animated_sprite.play("teleport")

func _physics_process(delta: float) -> void:
	if teleport_timer > 0:
		teleport_timer -= delta  # Reduce cooldown timer

	# Add gravity if in air
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		print("Jumped.")

	# Movement input
	var direction := Input.get_axis("move_left", "move_right")

	# Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Handle animation
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
