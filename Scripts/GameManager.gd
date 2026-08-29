extends Node
## Autoload singleton: res://Scripts/GameManager.gd -> "GameManager"
## Tracks overall run state (menu / running / dead / won).

signal game_over
signal victory

enum State { MENU, RUNNING, DEAD, WON }

var state: State = State.MENU

func reset_run() -> void:
	state = State.MENU

func start_run() -> void:
	state = State.RUNNING

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
