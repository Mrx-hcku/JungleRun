extends CharacterBody3D
## Attach to Wolf/Tiger root (CharacterBody3D so it can physically chase).
## Expects child nodes:
##   - CollisionShape3D - this predator's own physical body
##   - DetectionArea (Area3D, with its own larger CollisionShape3D) - the
##     "player detection" radius. Set its collision_mask to only detect
##     the player's physics layer.

@export var move_speed: float = 4.5
@export var catch_distance: float = 1.3
@export var growl_on_spot: bool = true
const GRAVITY := 20.0

enum State { IDLE, CHASE }
var state: State = State.IDLE
var target: Node3D = null

@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and state == State.IDLE:
		target = body
		state = State.CHASE
		if growl_on_spot:
			AudioManager.play_sfx("growl")

func _on_body_exited(body: Node3D) -> void:
	if body == target:
		target = null
		state = State.IDLE

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.RUNNING:
		velocity.x = 0.0
		velocity.z = 0.0
	elif state == State.CHASE and is_instance_valid(target):
		var to_target: Vector3 = target.global_position - global_position
		to_target.y = 0.0
		var dist: float = to_target.length()

		if dist < catch_distance:
			if target.has_method("die"):
				target.die()
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			var dir: Vector3 = to_target.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()
