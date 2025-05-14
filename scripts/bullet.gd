extends Area2D

var travelled_distance = 0
const SPEED = 200
const RANGE = 100
const GRAVITY = 500.0

var velocity = Vector2.ZERO
var is_stuck = false
var is_falling = false
var is_ready_to_shoot = true
var has_emitted_teleport = false

# Track bodies currently overlapping this kunai
var bodies_inside: Array = []

@onready var anim = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal kunai_hit_player
signal teleport_ready(global_position)

func _ready():
	anim.play("spinning")
	print("Kunai is ready.")

func set_velocity(new_velocity: Vector2):
	velocity = new_velocity

func _physics_process(delta):
	if is_stuck or not is_ready_to_shoot:
		return

	if is_falling:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		return

	# Fly forward
	var dir = Vector2.RIGHT.rotated(rotation)
	position += dir * SPEED * delta
	travelled_distance += SPEED * delta

	if travelled_distance > RANGE:
		is_falling = true
		velocity = dir * SPEED
		velocity.y = 0
		anim.play("spinning")
		print("Kunai missed. Falling started.")

# --- ENTRY/EXIT TRACKING ---
func _on_body_entered(body: Node2D) -> void:

	if not bodies_inside.has(body):
		bodies_inside.append(body)
		print(body.name, "entered kunai area.")

	# If we hit the player directly on shoot
	if body.name == "Player":
		print("Kunai hit the player!")
		emit_signal("kunai_hit_player")
		queue_free()
		return

	# First time we hit anything → teleport target set
	if not has_emitted_teleport:
		emit_signal("teleport_ready", global_position)
		has_emitted_teleport = true
		print("teleport_ready emitted at ", global_position)
	# Else: we’ve stuck into a wall/body
	_stick_to(body)


func _on_body_exited(body: Node2D) -> void:
	if bodies_inside.has(body):
		bodies_inside.erase(body)
		print(body.name, "exited kunai area.")


func _stick_to(body: Node2D) -> void:
	is_stuck = true
	is_falling = false
	velocity = Vector2.ZERO

	print("Kunai stuck to: ", body.name)
	_disable_previous_stuck()
	add_to_group("stuck_bullets")

	# Save current transform
	var hit_pos = global_position
	var hit_rotation = rotation

	# Reparent to the body it hit
	get_parent().remove_child(self)
	body.add_child(self)

	# Restore position and rotation after reparenting
	global_position = hit_pos
	rotation = hit_rotation

	# Calculate a nudge offset in the opposite direction of flight
	var nudge_dir = Vector2.RIGHT.rotated(rotation).normalized()
	var edge_escape = Vector2(1, -1).rotated(rotation).normalized()
	var total_nudge = nudge_dir * -3.5 + edge_escape * 2.0

	global_position += total_nudge

	# Disable collision to avoid retriggers
	$CollisionShape2D.disabled = true
	anim.play("static")

	_ready_for_new_shot()

func _disable_previous_stuck():
	# Remove other stuck bullets on this body
	for child in get_parent().get_children():
		if child != self and child.is_in_group("stuck_bullets"):
			get_parent().remove_child(child)
			child.queue_free()
			break

func _ready_for_new_shot():
	is_ready_to_shoot = true
	print("Kunai ready for next shot.")


# --- CALLED WHEN PLAYER TELEPORTS ---
func try_retrieve_on_teleport(player: Node2D) -> void:
	# If the player overlaps the stuck kunai, pick it up
	if is_stuck and bodies_inside.has(player):
		print("✅ Kunai retrieved by Player on teleport!")
		_reset_kunai_for_next_shot()

func _reset_kunai_for_next_shot():
	# Put it back into the “gun” or respawn logic
	queue_free()  # or you could hide & reset position/flags
