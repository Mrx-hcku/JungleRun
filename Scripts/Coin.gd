extends Area3D
## Simple collectible: plays a coin sfx and disappears. Purely cosmetic for
## now (no scoring system in the open-world version).

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		AudioManager.play_sfx("coin")
		queue_free()

func _process(delta: float) -> void:
	rotate_y(2.0 * delta)
