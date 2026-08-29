extends Area3D
## Attach to obstacle/animal scene roots (Wolf, Tiger, log, rock, etc).
## Root must be an Area3D with a CollisionShape3D child covering the model.

@export var is_animal: bool = false  # true for Wolf/Tiger -> plays growl before death sfx

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if is_animal:
			AudioManager.play_sfx("growl")
		if body.has_method("die"):
			body.die()
