extends CharacterBody3D
## Attach to the root of Scenes/Player.tscn.
## Expects child nodes:
##   - AnimationPlayer (named "AnimationPlayer") with clips: "Run", "Jump", "Slide", "Death"
##     (import these from the Remy Mixamo FBX - see Assets/Characters/README.txt)
##   - CollisionShape3D (named "CollisionShape") - capsule, gets flattened during slide
##   - Node3D "Model" holding the visual mesh (swap placeholder for Remy here)

const LANE_X := [-2.0, 0.0, 2.0]  # left, center, right
const LANE_CHANGE_SPEED := 12.0
const JUMP_VELOCITY := 11.0
const GRAVITY := 30.0
const SLIDE_DURATION := 0.6
const SWIPE_MIN_DISTANCE := 60.0  # pixels
const SWIPE_MAX_TIME := 0.5       # seconds

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape

func _play_anim(clip_name: String) -> void:
	# Safe wrapper: animations only exist once _load_and_attach_animations()
	# has successfully retargeted them (see below). Until then, this is a
	# silent no-op so the model still runs/jumps/slides/dies correctly,
	# just without motion.
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

var current_lane: int = 1  # index into LANE_X, start center
var target_x: float = 0.0
var is_sliding: bool = false
var is_jumping: bool = false
var is_dead: bool = false

var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time: float = 0.0
var _touch_active: bool = false

func _ready() -> void:
	target_x = LANE_X[current_lane]
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	_load_and_attach_animations()
	_play_anim("Run")
	AudioManager.play_music("jungle")

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.state != GameManager.State.RUNNING:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_start_time = Time.get_ticks_msec() / 1000.0
			_touch_active = true
		else:
			if _touch_active:
				_evaluate_swipe(event.position)
			_touch_active = false

	elif event is InputEventScreenDrag:
		# Optional: could evaluate mid-drag for more responsive feel.
		pass

func _evaluate_swipe(end_pos: Vector2) -> void:
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _touch_start_time
	if elapsed > SWIPE_MAX_TIME:
		return
	var delta := end_pos - _touch_start_pos
	if delta.length() < SWIPE_MIN_DISTANCE:
		return

	if abs(delta.x) > abs(delta.y):
		if delta.x > 0:
			_change_lane(1)
		else:
			_change_lane(-1)
	else:
		if delta.y < 0:
			_jump()
		else:
			_slide()

func _change_lane(direction: int) -> void:
	var new_lane: int = clamp(current_lane + direction, 0, LANE_X.size() - 1)
	if new_lane == current_lane:
		return
	current_lane = new_lane
	target_x = LANE_X[current_lane]

func _jump() -> void:
	if is_jumping or is_sliding or not is_on_floor():
		return
	is_jumping = true
	velocity.y = JUMP_VELOCITY
	_play_anim("Jump")
	AudioManager.play_sfx("jump")

func _slide() -> void:
	if is_sliding or is_jumping:
		return
	is_sliding = true
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.scale.y = 0.5
		collision_shape.position.y = 0.4
	_play_anim("Slide")
	AudioManager.play_sfx("slide")
	await get_tree().create_timer(SLIDE_DURATION).timeout
	is_sliding = false
	if collision_shape:
		collision_shape.scale.y = 1.0
		collision_shape.position.y = 0.9
	if not is_dead and GameManager.state == GameManager.State.RUNNING:
		_play_anim("Run")

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.RUNNING or is_dead:
		return

	# Forward auto-run.
	velocity.z = -GameManager.forward_speed

	# Smooth lane change.
	position.x = move_toward(position.x, target_x, LANE_CHANGE_SPEED * delta)

	# Gravity / jump.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		if is_jumping:
			is_jumping = false
			if not is_sliding:
				_play_anim("Run")
		velocity.y = max(velocity.y, 0.0) if is_on_floor() else velocity.y

	move_and_slide()

	# Simple footstep cadence while grounded and not sliding/jumping.
	if is_on_floor() and not is_sliding and not is_jumping:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			AudioManager.play_sfx("footstep")
			_footstep_timer = _footstep_interval

var _footstep_timer: float = 0.0
var _footstep_interval: float = 0.35

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
	_play_anim("Run")  # keep running into the house/victory zone
	AudioManager.stop_music()
	AudioManager.play_sfx("victory")

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
