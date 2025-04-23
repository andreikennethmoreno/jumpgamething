extends Area2D

var travelled_distance = 0
const SPEED = 200
const RANGE = 1200
var is_stuck = false

@onready var anim = $AnimatedSprite2D
signal kunai_stuck

func _ready():
	anim.play("spinning")  # Default to spinning

func _physics_process(delta: float) -> void:
	if is_stuck:
		return  # Stop moving if stuck

	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_stuck:
		return  # Already stuck

	# Remove existing stuck bullet
	for child in body.get_children():
		if child.is_in_group("stuck_bullets"):
			body.remove_child(child)
			child.queue_free()
			break

	# Stick this one
	is_stuck = true
	add_to_group("stuck_bullets")

	var hit_position = global_position
	print("Bullet hit at: ", hit_position)
	emit_signal("kunai_stuck")

	get_parent().remove_child(self)
	body.add_child(self)
	global_position = hit_position

	$CollisionShape2D.disabled = true
	anim.play("static")  # Switch to static animation
