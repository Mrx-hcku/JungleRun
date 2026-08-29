extends CharacterBody3D
## Free-roam open-world controller.
## - Movement: InputState.move_vector (from the on-screen Joystick) drives
##   motion relative to the camera's current facing.
## - Camera: touch-drag anywhere outside the joystick zone orbits the
##   camera (SpringArm3D handles wall/terrain collision automatically).
## Expects child nodes:
##   - Model (Node3D) containing the imported Remy.fbx, gets rotated to
##     face the movement direction
##   - AnimationPlayer (top-level) - clips get attached automatically at
##     runtime, see _load_and_attach_animations() below
##   - CameraPivot/SpringArm3D/Camera3D

const SPEED := 5.5
const ACCEL := 14.0
const GRAVITY := 20.0
const TURN_SPEED := 8.0
const CAMERA_SENSITIVITY := 0.006
const MIN_PITCH := -0.17   # ~ -10 degrees, radians
const MAX_PITCH := 1.22    # ~ 70 degrees, radians
const START_PITCH := 0.44  # ~ 25 degrees, radians

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
	_play_anim("Run")
	AudioManager.play_music("jungle")

func _unhandled_input(event: InputEvent) -> void:
	# Only fires for drags the on-screen joystick didn't already consume
	# (its Control has mouse_filter = STOP over its own touch zone).
	if event is InputEventScreenDrag:
		camera_yaw -= event.relative.x * CAMERA_SENSITIVITY
		camera_pitch = clamp(camera_pitch - event.relative.y * CAMERA_SENSITIVITY, MIN_PITCH, MAX_PITCH)

func _physics_process(delta: float) -> void:
	camera_pivot.global_position = global_position + Vector3(0.0, 1.4, 0.0)
	camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0.0)

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

	# Screen-space joystick: pushing "up" gives negative y -> that's forward.
	var move_dir: Vector3 = (cam_forward * -input_dir.y) + (cam_right * input_dir.x)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	var target_velocity: Vector3 = move_dir * SPEED
	velocity.x = move_toward(velocity.x, target_velocity.x, ACCEL * delta * SPEED)
	velocity.z = move_toward(velocity.z, target_velocity.z, ACCEL * delta * SPEED)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	var is_moving: bool = move_dir.length() > 0.15
	if is_moving:
		var target_angle: float = atan2(move_dir.x, move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, TURN_SPEED * delta)
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
	# Safe wrapper: animations only exist once _load_and_attach_animations()
	# has successfully retargeted them. Until then, this is a silent no-op
	# so the model still moves correctly, just without motion.
	if anim and anim.has_animation(clip_name):
		anim.play(clip_name)

const ANIMATION_SOURCES := {
	"Run": "res://Assets/Models/Animations/Run/Running.fbx",
	"Jump": "res://Assets/Models/Animations/Jump/Jump.fbx",
	"Slide": "res://Assets/Models/Animations/Slide/Running Slide.fbx",
	"Death": "res://Assets/Models/Animations/Death/Standing React Death Backward.fbx",
}

## Loads each Mixamo animation-only FBX at runtime, re-points its bone
## tracks from ITS OWN skeleton onto Remy's skeleton (found under this
## Player node), and attaches the result to this node's AnimationPlayer.
## Works entirely at runtime - no Godot Editor import step required, as
## long as all the FBX files share the same Mixamo bone names (which they
## do, since they were all exported from the same Mixamo rig).
func _load_and_attach_animations() -> void:
	if anim == null:
		return
	var target_skeleton := _find_skeleton(self)
	if target_skeleton == null:
		push_warning("Jungle Escape Runner: no Skeleton3D found under Player - is Remy.fbx imported correctly?")
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
			failed.append("%s (no animation found in file)" % clip_name)
			instance.free()
			continue

		var source_anim: Animation = source_player.get_animation(source_anim_name)
		var retargeted: Animation = source_anim.duplicate(true)

		# Keep only bone tracks (they carry a subname, e.g. "Skeleton3D:mixamorig_Hips"),
		# and re-point each one at Remy's own skeleton path. Drop anything else
		# (root-motion / non-bone tracks) since it can't be safely retargeted.
		var kept_any_bone_track := false
		var i := retargeted.get_track_count() - 1
		while i >= 0:
			var track_path := retargeted.track_get_path(i)
			if track_path.get_subname_count() > 0:
				var bone_name := track_path.get_concatenated_subnames()
				retargeted.track_set_path(i, NodePath(target_skeleton_path + ":" + bone_name))
				kept_any_bone_track = true
			else:
				retargeted.remove_track(i)
			i -= 1

		instance.free()

		if kept_any_bone_track:
			library.add_animation(clip_name, retargeted)
			attached.append(clip_name)
		else:
			failed.append("%s (bone names didn't match Remy's skeleton)" % clip_name)

	if not attached.is_empty():
		anim.add_animation_library("", library)
	if not failed.is_empty():
		push_warning("Jungle Escape Runner: animations not attached: %s" % ", ".join(failed))

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
