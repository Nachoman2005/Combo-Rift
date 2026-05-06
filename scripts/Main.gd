extends Node2D

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

@onready var board: Board = $Board
@onready var hud: HUD = $HUD

var state: GameState = GameState.MENU

func _ready() -> void:
	board.position = Vector2(60, 360)
	board.score_changed.connect(hud.set_score)
	board.combo_changed.connect(hud.set_combo)
	board.danger_changed.connect(hud.set_danger)
	board.game_over.connect(_on_board_game_over)

	hud.start_pressed.connect(_on_start_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)
	hud.resume_pressed.connect(_on_resume_pressed)
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.back_to_menu_pressed.connect(_on_back_to_menu_pressed)

	_set_state(GameState.MENU)

func _set_state(new_state: GameState) -> void:
	state = new_state
	match state:
		GameState.MENU:
			board.start_new_run()
			board.set_playing(false)
			hud.show_menu()
		GameState.PLAYING:
			board.set_playing(true)
			hud.show_playing()
		GameState.PAUSED:
			board.set_playing(false)
			hud.show_paused()
		GameState.GAME_OVER:
			board.set_playing(false)

func _on_start_pressed() -> void:
	_set_state(GameState.PLAYING)

func _on_pause_pressed() -> void:
	if state == GameState.PLAYING:
		_set_state(GameState.PAUSED)

func _on_resume_pressed() -> void:
	if state == GameState.PAUSED:
		_set_state(GameState.PLAYING)

func _on_retry_pressed() -> void:
	board.start_new_run()
	_set_state(GameState.PLAYING)

func _on_back_to_menu_pressed() -> void:
	_set_state(GameState.MENU)

func _on_board_game_over(final_score: int) -> void:
	_set_state(GameState.GAME_OVER)
	hud.show_game_over(final_score)
