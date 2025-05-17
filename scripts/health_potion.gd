extends Area2D



@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	print("potion.gd: adding +1 heart")
	animation_player.play("pickup")
	body.heal()
