extends CanvasLayer
class_name HUD

signal pause_pressed
signal resume_pressed
signal retry_pressed
signal back_to_menu_pressed
signal start_pressed

@onready var score_value: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var combo_value: Label = $MarginContainer/VBoxContainer/ComboLabel
@onready var danger_bar: ProgressBar = $MarginContainer/VBoxContainer/DangerBar
@onready var pause_button: Button = $MarginContainer/VBoxContainer/PauseButton
@onready var menu_panel: PanelContainer = $MenuPanel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel

func _ready() -> void:
	pause_button.pressed.connect(_on_pause_button_pressed)
	$MenuPanel/VBoxContainer/StartButton.pressed.connect(func() -> void: start_pressed.emit())
	$PausePanel/VBoxContainer/ResumeButton.pressed.connect(func() -> void: resume_pressed.emit())
	$GameOverPanel/VBoxContainer/RetryButton.pressed.connect(func() -> void: retry_pressed.emit())
	$GameOverPanel/VBoxContainer/MenuButton.pressed.connect(func() -> void: back_to_menu_pressed.emit())

func set_score(value: int) -> void:
	score_value.text = "Score: %d" % value

func set_combo(value: int) -> void:
	combo_value.text = "Combo: x%d" % value

func set_danger(value: float) -> void:
	danger_bar.value = value * 100.0

func show_menu() -> void:
	menu_panel.visible = true
	pause_panel.visible = false
	game_over_panel.visible = false
	pause_button.visible = false

func show_playing() -> void:
	menu_panel.visible = false
	pause_panel.visible = false
	game_over_panel.visible = false
	pause_button.visible = true

func show_paused() -> void:
	pause_panel.visible = true
	menu_panel.visible = false
	game_over_panel.visible = false
	pause_button.visible = false

func show_game_over(final_score: int) -> void:
	final_score_label.text = "Score final: %d" % final_score
	game_over_panel.visible = true
	pause_panel.visible = false
	menu_panel.visible = false
	pause_button.visible = false

func _on_pause_button_pressed() -> void:
	pause_pressed.emit()
