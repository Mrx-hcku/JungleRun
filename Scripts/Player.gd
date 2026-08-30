extends CharacterBody3D

const SPEED := 5.5
const ACCEL := 14.0
const GRAVITY := 20.0
const JUMP_VELOCITY := 8.0
const TURN_SPEED := 8.0
const CAMERA_SENSITIVITY := 0.006
const MIN_PITCH := -0.17   # ~ -10 degrees, radians
const MAX_PITCH := 1.0     # ~ 57 degrees, radians
const START_PITCH := 0.28  # ~ 16 degrees, radians
const ANIM_BLEND := 0.15   # crossfade time between clips, seconds
const CAMERA_FOLLOW_SPEED := 25.0 # Camera smoothing ke liye

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var model: Node3D = $Model
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var camera_yaw: float = 0.0
var camera_pitch: float = START_PITCH
var is_dead: bool = false

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	camera.current = true
	_load_and_attach_animations()
	anim.animation_finished.connect(_on_animation_finished)
	_play_anim("Run")  
	AudioManager.play_music("jungle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		camera_yaw -= event.relative.x * CAMERA_SENSITIVITY
		camera_pitch = clamp(camera_pitch - event.relative.y * CAMERA_SENSITIVITY, MIN_PITCH, MAX_PITCH)

func _physics_process(delta: float) -> void:
	# Camera ko hard-snap karne ki bajaye lerp se smooth follow karwaya hai taaki jitter na aaye
	var target_cam_pos = global_position + Vector3(0.0, 1.6, 0.0)
	camera_pivot.global_position = camera_pivot.global_position.lerp(target_cam_pos, CAMERA_FOLLOW_SPEED * delta)
	
	camera_pivot.rotation = Vector3(0.0, camera_yaw, 0.0)  
	camera.rotation.x = camera_pitch                        

	if is_dead or GameManager.state != GameManager.State.RUNNING:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	var input_dir: Vector2 = InputState.move_vector

	var cam_forward: Vector3 = -camera_pivot.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()
	var cam_right: Vector3 = camera_pivot.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var move_dir: Vector3 = (cam_forward * -input_dir.y) + (cam_right * input_dir.x)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	var target_velocity: Vector3 = move_dir * SPEED
	velocity.x = move_toward(velocity.x, target_velocity.x, ACCEL * delta * SPEED)
	velocity.z = move_toward(velocity.z, target_velocity.z, ACCEL * delta * SPEED)

	var jump_requested: bool = InputState.jump_requested
	InputState.jump_requested = false

	if is_on_floor():
		velocity.y = 0.0
		if jump_requested:
			velocity.y = JUMP_VELOCITY
			_play_anim("Jump")
			AudioManager.play_sfx("jump")
	else:
		velocity.y -= GRAVITY * delta

	move_and_slide()

	if move_dir.length() > 0.15:
		var target_angle: float = atan2(move_dir.x, move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, TURN_SPEED * delta)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Jump" and not is_dead:
		_play_anim("Run")

func die() -> void:
	if is_dead:
		return
	is_dead = true
	GameManager.trigger_death()
	_play_anim("Death")
	AudioManager.stop_music()
	AudioManager.play_sfx("death")

func _on_game_over() -> void:
	die()

func _on_victory() -> void:
	AudioManager.stop_music()
	AudioManager.play_sfx("victory")

func _play_anim(clip_name: String) -> void:
	if anim and anim.has_animation(clip_name):
		anim.play(clip_name, ANIM_BLEND)

const ANIMATION_SOURCES := {
	"Run": "res://Assets/Models/Animations/Run/Running.fbx",
	"Jump": "res://Assets/Models/Animations/Jump/Jump.fbx",
	"Slide": "res://Assets/Models/Animations/Slide/Running Slide.fbx",
	"Death": "res://Assets/Models/Animations/Death/Standing React Death Backward.fbx",
}

func _load_and_attach_animations() -> void:
	if anim == null:
		return
	var target_skeleton := _find_skeleton(self)
	if target_skeleton == null:
		push_warning("No Skeleton3D found under Player")
		return
	var target_skeleton_path := str(get_path_to(target_skeleton))

	var library := AnimationLibrary.new()
	var attached: Array[String] = []
	var failed: Array[String] = []

	for clip_name in ANIMATION_SOURCES.keys():
		var source_path: String = ANIMATION_SOURCES[clip_name]
		if not ResourceLoader.exists(source_path):
			failed.append("%s (file not found)" % clip_name)
			continue

		var packed: PackedScene = load(source_path)
		if packed == null:
			failed.append("%s (couldn't load)" % clip_name)
			continue

		var instance := packed.instantiate()
		var source_player := _find_animation_player(instance)
		var source_anim_name := _first_non_reset_animation(source_player) if source_player else ""

		if source_player == null or source_anim_name == "":
			failed.append("%s (no animation found)" % clip_name)
			instance.free()
			continue

		var source_anim: Animation = source_player.get_animation(source_anim_name)
		var retargeted: Animation = source_anim.duplicate(true)

		if clip_name == "Run":
			retargeted.loop_mode = Animation.LOOP_LINEAR

		var kept_track_count := 0
		var i := retargeted.get_track_count() - 1
		while i >= 0:
			var track_path := retargeted.track_get_path(i)
			var bone_exists := false
			if track_path.get_subname_count() > 0:
				var bone_name := track_path.get_concatenated_subnames()
				if target_skeleton.find_bone(bone_name) != -1:
					retargeted.track_set_path(i, NodePath(target_skeleton_path + ":" + bone_name))
					kept_track_count += 1
					bone_exists = true
			if not bone_exists:
				retargeted.remove_track(i)
			i -= 1

		instance.free()

		var bone_count: int = max(target_skeleton.get_bone_count(), 1)
		var coverage: float = float(kept_track_count) / float(bone_count)

		if kept_track_count > 0 and coverage >= 0.5:
			library.add_animation(clip_name, retargeted)
			attached.append(clip_name)
		else:
			failed.append("%s (coverage low)" % clip_name)

	if not attached.is_empty():
		anim.add_animation_library("", library)
	if not failed.is_empty():
		push_warning("Animations not attached: %s" % ", ".join(failed))

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result:
			return result
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	return null

func _first_non_reset_animation(player: AnimationPlayer) -> String:
	for anim_name in player.get_animation_list():
		if anim_name != "RESET":
			return anim_name
	return ""
