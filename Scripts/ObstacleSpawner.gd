extends Node3D
## Attach to Scenes/Main.tscn under a "Track" node.
## Generates the whole jungle stretch once at start (finite length, not a
## true infinite runner), then places the house/victory trigger at the end.
##
## Assign the obstacle/animal/coin/house scenes in the Inspector, or they
## fall back to placeholder box scenes if left empty (see notes below).

const LANE_X := [-2.0, 0.0, 2.0]

@export var log_obstacle_scene: PackedScene = preload("res://Scenes/Obstacles/LogObstacle.tscn")
@export var rock_obstacle_scene: PackedScene = preload("res://Scenes/Obstacles/RockObstacle.tscn")
@export var wolf_scene: PackedScene = preload("res://Scenes/Obstacles/Wolf.tscn")
@export var tiger_scene: PackedScene = preload("res://Scenes/Obstacles/Tiger.tscn")
@export var coin_scene: PackedScene = preload("res://Scenes/Obstacles/Coin.tscn")
@export var house_scene: PackedScene = preload("res://Scenes/Obstacles/House.tscn")

@export var segment_length: float = 18.0   # avg spacing between spawn rows
@export var segment_length_jitter: float = 6.0
@export var animal_chance: float = 0.25    # of the obstacle rows, how many are animals
@export var coin_chance: float = 0.5       # chance an open lane also gets a coin row

func _ready() -> void:
	randomize()
	_generate_track()

func _generate_track() -> void:
	var z := -20.0  # first obstacle a bit ahead of the start so the player can react
	var jungle_length: float = GameManager.jungle_length

	while z > -jungle_length:
		_spawn_row(z)
		z -= segment_length + randf_range(-segment_length_jitter, segment_length_jitter)

	_spawn_house(-jungle_length - 10.0)

func _spawn_row(z: float) -> void:
	# Block 1 or 2 of the 3 lanes, always leave at least one lane clear.
	var lanes := [0, 1, 2]
	lanes.shuffle()
	var blocked_count: int = 1 if randf() < 0.6 else 2
	var blocked_lanes: Array = lanes.slice(0, blocked_count)
	var open_lanes: Array = lanes.slice(blocked_count)

	for lane in blocked_lanes:
		var scene: PackedScene = _pick_obstacle_scene()
		if scene == null:
			continue
		var inst := scene.instantiate()
		add_child(inst)
		inst.position = Vector3(LANE_X[lane], 0.0, z)

	if not open_lanes.is_empty() and coin_scene and randf() < coin_chance:
		var lane: int = open_lanes[randi() % open_lanes.size()]
		var coin := coin_scene.instantiate()
		add_child(coin)
		coin.position = Vector3(LANE_X[lane], 1.2, z)

func _pick_obstacle_scene() -> PackedScene:
	if randf() < animal_chance:
		if wolf_scene and tiger_scene:
			return wolf_scene if randf() < 0.5 else tiger_scene
		return wolf_scene if wolf_scene else tiger_scene
	if log_obstacle_scene and rock_obstacle_scene:
		return log_obstacle_scene if randf() < 0.5 else rock_obstacle_scene
	return log_obstacle_scene if log_obstacle_scene else rock_obstacle_scene

func _spawn_house(z: float) -> void:
	if house_scene == null:
		return
	var house := house_scene.instantiate()
	add_child(house)
	house.position = Vector3(0.0, 0.0, z)
