extends CanvasLayer

@onready var joystick: Control = $Joystick
@onready var start_panel: Control = $StartPanel
@onready var game_over_panel: Control = $GameOverPanel
@onready var victory_panel: Control = $VictoryPanel
@onready var start_button: Button = $StartPanel/StartButton
@onready var retry_button: Button = $GameOverPanel/RetryButton
@onready var play_again_button: Button = $VictoryPanel/PlayAgainButton

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)

	start_button.pressed.connect(_on_start_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	play_again_button.pressed.connect(_on_retry_pressed)

	joystick.visible = false
	start_panel.visible = true
	game_over_panel.visible = false
	victory_panel.visible = false

func _on_start_pressed() -> void:
	start_panel.visible = false
	joystick.visible = true
	GameManager.start_run()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_game_over() -> void:
	joystick.visible = false
	game_over_panel.visible = true

func _on_victory() -> void:
	joystick.visible = false
	victory_panel.visible = true
