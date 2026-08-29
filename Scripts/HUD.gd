extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var start_panel: Control = $StartPanel
@onready var game_over_panel: Control = $GameOverPanel
@onready var victory_panel: Control = $VictoryPanel
@onready var start_button: Button = $StartPanel/StartButton
@onready var retry_button: Button = $GameOverPanel/RetryButton
@onready var play_again_button: Button = $VictoryPanel/PlayAgainButton

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)

	start_button.pressed.connect(_on_start_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	play_again_button.pressed.connect(_on_retry_pressed)

	score_label.visible = false
	start_panel.visible = true
	game_over_panel.visible = false
	victory_panel.visible = false

func _on_start_pressed() -> void:
	start_panel.visible = false
	score_label.visible = true
	GameManager.start_run()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Distance: %d m" % new_score

func _on_game_over() -> void:
	score_label.visible = false
	game_over_panel.visible = true

func _on_victory() -> void:
	score_label.visible = false
	victory_panel.visible = true
