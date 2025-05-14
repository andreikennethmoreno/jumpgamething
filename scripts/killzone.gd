extends Area2D

@onready var timer: Timer = $Timer
const KNOCKBACK_FORCE := 1000.0
const UPWARD_BIAS := 0.4  # how much of the force always goes up
#const DOWNWARD_BIAS := -0.4  # how much of the force always goes up
@onready var animated_sprite_trap: AnimatedSprite2D = $AnimatedSprite2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("hit"):
		print("killzone.gd: you got hit")

		# Determine left/right purely by x-offset sign
		var horiz = sign(body.global_position.x - global_position.x)
		# Build a guaranteed non-zero vector with an upward bias
		var dir = Vector2(horiz, -UPWARD_BIAS).normalized()

		body.hit(dir * KNOCKBACK_FORCE)
		animated_sprite_trap.play("active")
		await get_tree().create_timer(1.0).timeout
		animated_sprite_trap.play("passive")
