extends Area2D

var travelled_distance = 0
const SPEED = 200
const RANGE = 100
const GRAVITY = 500.0
var velocity = Vector2.ZERO
var is_stuck = false
var is_falling = false
var is_ready_to_shoot = true
var has_emitted_teleport = false    # Guard flag

@onready var anim = $AnimatedSprite2D

signal kunai_hit_player
signal teleport_ready(global_position)   # Signal to trigger teleportation

func _ready():
	anim.play("spinning")
	print("Kunai is ready.")

# Set the velocity received from the gun
func set_velocity(new_velocity: Vector2):
	velocity = new_velocity

func _physics_process(delta: float) -> void:
	# Emit signal only once when the kunai is ready and stuck
	if is_stuck and !has_emitted_teleport:
		emit_signal("teleport_ready", global_position)  # Emit the teleport position
		has_emitted_teleport = true
		print("bullet.gd: teleport_ready emitted at:", global_position)

	if is_stuck or not is_ready_to_shoot:
		return

	if is_falling:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		return

	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	travelled_distance += SPEED * delta

	if travelled_distance > RANGE:
		is_falling = true
		velocity = direction * SPEED
		velocity.y = 0
		anim.play("spinning")
		print("Kunai missed. Falling started.")

func _on_body_entered(body: Node2D) -> void:
	print("Kunai hit something: ", body.name)

	if body.name == "Player":
		print("Kunai hit the player!")
		emit_signal("kunai_hit_player")
		queue_free()
		return

	is_stuck = true
	is_falling = false
	velocity = Vector2.ZERO

	print("Kunai stuck to: ", body.name)
	# Cleanup
	for child in body.get_children():
		if child.is_in_group("stuck_bullets"):
			body.remove_child(child)
			child.queue_free()
			break

	add_to_group("stuck_bullets")
	var hit_position = global_position
	get_parent().remove_child(self)
	body.add_child(self)
	global_position = hit_position

	$CollisionShape2D.disabled = true
	anim.play("static")

	_ready_for_new_shot()

func _ready_for_new_shot():
	is_ready_to_shoot = true
	print("Kunai ready for next shot.")
