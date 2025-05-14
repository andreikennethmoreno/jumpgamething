extends Area2D

@onready var timer: Timer = $Timer
const KNOCKBACK_FORCE := 1000.0


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("hit"):  # or use group check
		print("you got hit")
		var dir = (body.global_position - global_position).normalized()
		body.hit(dir * KNOCKBACK_FORCE)
		#timer.start()
