extends Node3D
## Attach to the House scene root. Triggers victory when the player enters
## the VictoryArea child.

func _ready() -> void:
	$VictoryArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.trigger_victory()
