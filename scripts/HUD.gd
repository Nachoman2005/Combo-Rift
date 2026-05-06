extends CanvasLayer
class_name HUD

@onready var score_value: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var combo_value: Label = $MarginContainer/VBoxContainer/ComboLabel
@onready var danger_bar: ProgressBar = $MarginContainer/VBoxContainer/DangerBar

func set_score(value: int) -> void:
	score_value.text = "Score: %d" % value

func set_combo(value: int) -> void:
	combo_value.text = "Combo: x%d" % value

func set_danger(value: float) -> void:
	danger_bar.value = value * 100.0
