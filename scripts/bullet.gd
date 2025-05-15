extends Area2D #bullet.gd

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

#signal kunai_destroyed
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


const FLOOR_STICK_DEPTH = 1
const WALL_STICK_DEPTH = 1


func _stick_to(body: Node2D) -> void:
	is_stuck = true
	is_falling = false

	# Capture the incoming direction before zeroing velocity
	var impact_dir = Vector2.ZERO
	if velocity.length() > 0:
		impact_dir = velocity.normalized()

	velocity = Vector2.ZERO

	print("Kunai stuck to: ", body.name)
	_disable_previous_stuck()
	add_to_group("stuck_bullets")

	# Save transform
	var hit_pos = global_position
	var hit_rot = rotation

	# Reparent under the hit body
	get_parent().remove_child(self)
	body.add_child(self)
	global_position = hit_pos
	rotation = hit_rot

	# Determine if we hit a floor-ish or wall-ish surface by checking our rotation
	var angle_deg = fposmod(rad_to_deg(rotation), 360.0)
	if angle_deg > 180:
		angle_deg -= 360  # map into -180..180

	# If rotated ~90 degrees, it's floor/ceiling; else it's a wall
	var is_wall = abs(angle_deg) < 45.0 or abs(angle_deg) > 135.0
	var offset_dist = WALL_STICK_DEPTH if is_wall else FLOOR_STICK_DEPTH

	if is_wall:
		print("Sticking to wall logic")
	else:
		print("Sticking to floor logic")


	# Nudge *into* the surface along the reverse impact direction
	if impact_dir != Vector2.ZERO:
		global_position = hit_pos - impact_dir * offset_dist
	else:
		# Fallback: if no velocity (e.g. teleported), just pull back along X-axis
		global_position = hit_pos - Vector2.RIGHT.rotated(rotation) * offset_dist

	# Disable collision now that we're stuck
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
	#emit_signal("kunai_destroyed")
	# Put it back into the “gun” or respawn logic
	queue_free()  # or you could hide & reset position/flags
