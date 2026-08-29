extends Area3D
## Simple collectible: adds bonus score and plays a coin sfx, then frees itself.

@export var bonus_score: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.score += bonus_score
		GameManager.score_changed.emit(GameManager.score)
		AudioManager.play_sfx("coin")
		queue_free()

func _process(delta: float) -> void:
	rotate_y(2.0 * delta)
