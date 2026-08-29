extends Area3D
## Attach to STATIC hazard scene roots (log, rock, etc - not Wolf/Tiger,
## which chase via PredatorAI.gd instead). Root must be an Area3D with a
## CollisionShape3D child covering the model. Player dies on touch.

@export var is_animal: bool = false  # unused now, kept for backward compat

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if is_animal:
			AudioManager.play_sfx("growl")
		if body.has_method("die"):
			body.die()
