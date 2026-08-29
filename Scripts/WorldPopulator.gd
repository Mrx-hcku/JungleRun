extends Node3D
## Attach to a "World" node in Scenes/Main.tscn.
## Scatters static obstacles, coins, and chase predators randomly across a
## circular jungle area, places the house goal somewhere on its edge, and
## fills the rest with dense vegetation - except along a handful of
## organic winding "trails" (one of which always leads toward the house),
## which stay relatively clear so there's always a way to run.
## Player is assumed to start at the world origin (0, 0, 0).

@export var log_obstacle_scene: PackedScene = preload("res://Scenes/Obstacles/LogObstacle.tscn")
@export var rock_obstacle_scene: PackedScene = preload("res://Scenes/Obstacles/RockObstacle.tscn")
@export var wolf_scene: PackedScene = preload("res://Scenes/Obstacles/Wolf.tscn")
@export var tiger_scene: PackedScene = preload("res://Scenes/Obstacles/Tiger.tscn")
@export var coin_scene: PackedScene = preload("res://Scenes/Obstacles/Coin.tscn")
@export var house_scene: PackedScene = preload("res://Scenes/Obstacles/House.tscn")

@export var world_radius: float = 60.0
@export var obstacle_count: int = 30
@export var coin_count: int = 18
@export var wolf_count: int = 2
@export var tiger_count: int = 1
@export var safe_radius_from_start: float = 10.0

## Higher counts = denser/scarier jungle, but more nodes to render - if it
## runs slow on your phone, lower these first (no code changes needed).
@export var tree_count: int = 110
@export var bush_count: int = 140
@export var grass_count: int = 260
@export var decor_rock_count: int = 45

## Trail generation - the winding "clear paths" through the dense jungle.
@export var trail_count: int = 6          # 1 always aims at the house, rest are decoys
@export var trail_steps: int = 9
@export var trail_step_length: float = 9.0
@export var trail_wander: float = 0.6     # radians of random wobble per step
@export var trail_clear_radius: float = 4.0  # how wide each trail's clearing is

const TREE_PATHS: Array[String] = [
	"res://Assets/Models/Forest/Assets/gltf/Tree_1_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_1_B_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_1_C_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_2_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_2_C_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_2_E_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_3_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_3_C_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_4_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_4_C_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_Bare_1_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Tree_Bare_2_A_Color1.gltf",
]
const BUSH_PATHS: Array[String] = [
	"res://Assets/Models/Forest/Assets/gltf/Bush_1_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Bush_1_D_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Bush_2_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Bush_3_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Bush_4_A_Color1.gltf",
]
const GRASS_PATHS: Array[String] = [
	"res://Assets/Models/Forest/Assets/gltf/Grass_1_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Grass_1_C_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Grass_2_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Grass_2_C_Color1.gltf",
]
const DECOR_ROCK_PATHS: Array[String] = [
	"res://Assets/Models/Forest/Assets/gltf/Rock_1_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Rock_1_D_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Rock_2_A_Color1.gltf",
	"res://Assets/Models/Forest/Assets/gltf/Rock_3_A_Color1.gltf",
]

func _ready() -> void:
	randomize()
	_spawn_obstacles()
	_spawn_coins()
	_spawn_predators(wolf_scene, wolf_count)
	_spawn_predators(tiger_scene, tiger_count)
	var house_pos: Vector3 = _spawn_house()
	var trails: Array = _generate_trails(house_pos)
	_spawn_vegetation(trails)

func _random_point() -> Vector3:
	var angle := randf() * TAU
	var dist := sqrt(randf()) * world_radius
	return Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

func _random_point_away_from_start() -> Vector3:
	var point := _random_point()
	while point.length() < safe_radius_from_start:
		point = _random_point()
	return point

func _spawn_obstacles() -> void:
	for i in obstacle_count:
		var scene: PackedScene = log_obstacle_scene if randf() < 0.5 else rock_obstacle_scene
		if scene == null:
			continue
		var inst := scene.instantiate()
		add_child(inst)
		inst.position = _random_point_away_from_start()
		inst.rotation.y = randf() * TAU

func _spawn_coins() -> void:
	if coin_scene == null:
		return
	for i in coin_count:
		var coin := coin_scene.instantiate()
		add_child(coin)
		var p := _random_point_away_from_start()
		p.y = 1.0
		coin.position = p

func _spawn_predators(scene: PackedScene, count: int) -> void:
	if scene == null:
		return
	for i in count:
		var inst := scene.instantiate()
		add_child(inst)
		inst.position = _random_point_away_from_start()

func _spawn_house() -> Vector3:
	if house_scene == null:
		return Vector3(world_radius * 0.9, 0.0, 0.0)
	var house := house_scene.instantiate()
	add_child(house)
	var angle := randf() * TAU
	var pos := Vector3(cos(angle) * world_radius * 0.9, 0.0, sin(angle) * world_radius * 0.9)
	house.position = pos
	return pos

## ---- Trails (winding clear paths through the dense jungle) ----

func _build_trail(target: Vector3) -> PackedVector3Array:
	var points := PackedVector3Array()
	var pos := Vector3.ZERO
	points.append(pos)
	var heading := atan2(target.x, target.z)
	for i in trail_steps:
		var to_target_heading := atan2(target.x - pos.x, target.z - pos.z)
		heading = lerp_angle(heading, to_target_heading, 0.35)
		heading += randf_range(-trail_wander, trail_wander)
		pos += Vector3(sin(heading), 0.0, cos(heading)) * trail_step_length
		points.append(pos)
	return points

func _generate_trails(house_pos: Vector3) -> Array:
	var trails: Array = []
	trails.append(_build_trail(house_pos))  # guaranteed route toward the goal
	for i in trail_count - 1:
		var decoy_angle := randf() * TAU
		var decoy_target := Vector3(cos(decoy_angle), 0.0, sin(decoy_angle)) * world_radius * randf_range(0.6, 0.95)
		trails.append(_build_trail(decoy_target))
	return trails

func _distance_to_segment_xz(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ab_len_sq := ab.length_squared()
	var t: float = 0.0
	if ab_len_sq > 0.0001:
		t = clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = Vector2(a.x, a.z) + ab * t
	return Vector2(p.x, p.z).distance_to(closest)

func _is_near_any_trail(p: Vector3, trails: Array, radius: float) -> bool:
	for trail in trails:
		var pts: PackedVector3Array = trail
		for i in pts.size() - 1:
			if _distance_to_segment_xz(p, pts[i], pts[i + 1]) < radius:
				return true
	return false

## ---- Vegetation (dense everywhere except near trails) ----

func _spawn_vegetation(trails: Array) -> void:
	_scatter_from_paths(TREE_PATHS, tree_count, 3.0, 0.9, 1.3, trails, trail_clear_radius)
	_scatter_from_paths(BUSH_PATHS, bush_count, 1.5, 0.8, 1.4, trails, trail_clear_radius * 0.8)
	_scatter_from_paths(GRASS_PATHS, grass_count, 0.0, 0.7, 1.5, trails, trail_clear_radius * 0.3)
	_scatter_from_paths(DECOR_ROCK_PATHS, decor_rock_count, 2.0, 0.7, 1.3, trails, trail_clear_radius * 0.6)

func _scatter_from_paths(paths: Array[String], count: int, min_gap_from_start: float, min_scale: float, max_scale: float, trails: Array, clear_radius: float) -> void:
	for i in count:
		var path: String = paths[randi() % paths.size()]
		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = load(path)
		if scene == null:
			continue

		var placed_point: Vector3 = Vector3.ZERO
		var found := false
		for attempt in 8:
			var candidate := _random_point()
			if candidate.length() < min_gap_from_start:
				continue
			if clear_radius > 0.0 and _is_near_any_trail(candidate, trails, clear_radius):
				continue
			placed_point = candidate
			found = true
			break
		if not found:
			continue

		var inst := scene.instantiate()
		add_child(inst)
		inst.position = placed_point
		inst.rotation.y = randf() * TAU
		inst.scale = Vector3.ONE * randf_range(min_scale, max_scale)
