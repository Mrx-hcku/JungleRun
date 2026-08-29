extends Node
## Autoload singleton: res://Scripts/GameManager.gd -> "GameManager"
## Tracks run state, score/distance, forward speed, and win/lose transitions.

signal game_over
signal victory
signal score_changed(new_score: int)

enum State { MENU, RUNNING, DEAD, WON }

var state: State = State.MENU
var distance_travelled: float = 0.0
var forward_speed: float = 8.0
var base_speed: float = 8.0
var max_speed: float = 18.0
var speed_ramp_per_sec: float = 0.15

# Distance (in world units) the player must cover through the jungle
# before the house / victory zone appears.
var jungle_length: float = 900.0

var score: int = 0

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	state = State.MENU
	distance_travelled = 0.0
	forward_speed = base_speed
	score = 0
	score_changed.emit(score)

func start_run() -> void:
	state = State.RUNNING
	distance_travelled = 0.0
	forward_speed = base_speed
	score = 0

func _process(delta: float) -> void:
	if state != State.RUNNING:
		return
	forward_speed = min(forward_speed + speed_ramp_per_sec * delta, max_speed)
	distance_travelled += forward_speed * delta
	score = int(distance_travelled)
	score_changed.emit(score)

	if distance_travelled >= jungle_length:
		trigger_victory()

func trigger_death() -> void:
	if state != State.RUNNING:
		return
	state = State.DEAD
	game_over.emit()

func trigger_victory() -> void:
	if state != State.RUNNING:
		return
	state = State.WON
	victory.emit()
