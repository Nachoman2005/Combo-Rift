extends Node2D

@onready var board: Board = $Board
@onready var hud: HUD = $HUD

func _ready() -> void:
	board.position = Vector2(60, 360)
	board.score_changed.connect(hud.set_score)
	board.combo_changed.connect(hud.set_combo)
	board.danger_changed.connect(hud.set_danger)
