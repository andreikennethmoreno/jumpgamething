extends CharacterBody2D

signal kunai_hit_player
signal teleport_ready(global_position)

# --- Tunables (replace with your WeaponSettings if you like) ---
const SPEED      := 200.0
const RANGE      := 100.0
const GRAVITY    := 500.0
const FLOOR_DEPTH := 2.0
const WALL_DEPTH  := 2.0

# --- State ---
var travelled_dist   := 0.0
var is_stuck         := false
var has_emitted_tp   := false
var has_emitted_teleport = false

@onready var anim    := $AnimatedSprite2D
@onready var shape   := $CollisionShape2D

func _ready():
	anim.play("spinning")
	print("Kunai ready.")

# NEW – pick a unique name
func launch(dir: Vector2) -> void:
	velocity = dir.normalized() * SPEED

func _physics_process(delta: float) -> void:
	if is_stuck :
		return


	# apply gravity
	velocity.y += GRAVITY * delta

	# handle flight vs. falling by range
	if travelled_dist < RANGE:
		travelled_dist += velocity.length() * delta
	# after max range, just let it fall
	# (same gravity code already handles arc)

	# move and detect collision
	var coll := move_and_collide(velocity * delta)
	if coll:
		_on_collision(coll)
	else:
		# keep spinning while in flight
		anim.rotation += SPEED * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("Kunai hit the player!")
		TeleportManager.can_teleport = false
		TeleportManager.teleport_target_position = Vector2.ZERO
		emit_signal("kunai_hit_player")
		queue_free()
		return

	## Stick only if not already stuck
	#if not is_stuck:
		#_stick_to(body, Vector2.UP) # Optional: store normal if needed


func _on_collision(coll: KinematicCollision2D) -> void:
	var body = coll.get_collider()
	var normal = coll.get_normal()


	# Bounce logic for Metal
	if body.name == "Metal":
		# Reflect the velocity
		velocity = velocity.bounce(normal)

		# Add a small random angle (±15 degrees) to deflect it
		var angle_offset_deg = randf_range(-15, 15)
		velocity = velocity.rotated(deg_to_rad(angle_offset_deg))

		# Dampen it more on bounce
		velocity *= 0.75

		print("Kunai bounced off Metal at angle ", angle_offset_deg, ", new velocity:", velocity)
		return

	if body.name == "Player":
		emit_signal("kunai_hit_player")

		# ✅ RESET teleport position
		TeleportManager.can_teleport = false
		TeleportManager.teleport_target_position = Vector2.ZERO

		queue_free()
		return

	# first impact → teleport
	#if not has_emitted_tp:
		#emit_signal("teleport_ready", global_position)
		#has_emitted_tp = true

	if not is_stuck:
		_stick_to(body, coll.get_normal())

func _stick_to(body: Node, normal: Vector2) -> void:
	is_stuck = true
	velocity = Vector2.ZERO

	# detach rotation/position, then reparent under body
	var hit_pos = global_position
	var hit_rot = rotation
	get_parent().remove_child(self)
	body.add_child(self)
	global_position = hit_pos
	rotation = hit_rot

	# choose depth offset based on surface angle
	var is_wall = abs(normal.dot(Vector2.UP)) < 0.5
	var depth = WALL_DEPTH if is_wall else FLOOR_DEPTH

	# nudge into surface
	global_position -= normal * depth

	# disable physics and shape
	shape.disabled = true
	anim.play("static")

	print("Kunai stuck to ", body.name)


	if not has_emitted_teleport:
		emit_signal("teleport_ready", global_position)
		has_emitted_teleport = true
		print("bullet.gd: teleport_ready emitted at", global_position)


func try_retrieve_on_teleport(player: Node2D) -> void:
	if not is_stuck:
		return

	# simple distance check instead of disabled shape
	if player.global_position.distance_to(global_position) <= 16.0:
		print("✅ Kunai retrieved!")

		# 1) Reset kunai state so it won’t re-emit or stick again
		is_stuck       = false
		has_emitted_tp = false
		travelled_dist = 0.0
		shape.disabled = false
		anim.play("spinning")

		# 2) Clear your TeleportManager so you can't teleport again
		TeleportManager.can_teleport            = false
		TeleportManager.teleport_target_position = Vector2.ZERO

		# 3) Reparent or free-and-recreate
		# Option A: send it back into the gun
		# get_parent().remove_child(self)
		# yourGunNode.add_child(self)
		# global_position = yourGunNode.shooting_point.global_position
		#
		# Option B: just free it and let the gun scene recreate it on next shot
		queue_free()
