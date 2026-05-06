extends Node2D

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	CREDITS
}

@onready var board: Board = $Board
@onready var hud: HUD = $HUD

var ads_manager: AdsManager
var state: GameState = GameState.MENU
var finished_runs: int = 0
var used_rewarded_continue: bool = false

func _ready() -> void:
	ads_manager = AdsManager.new()
	add_child(ads_manager)

	board.position = Vector2(60, 360)
	board.score_changed.connect(hud.set_score)
	board.combo_changed.connect(hud.set_combo)
	board.danger_changed.connect(hud.set_danger)
	board.game_over.connect(_on_board_game_over)

	hud.start_pressed.connect(_on_start_pressed)
	hud.shop_pressed.connect(_on_shop_pressed)
	hud.credits_pressed.connect(_on_credits_pressed)
	hud.close_credits_pressed.connect(_on_close_credits_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)
	hud.resume_pressed.connect(_on_resume_pressed)
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.back_to_menu_pressed.connect(_on_back_to_menu_pressed)
	hud.continue_ad_pressed.connect(_on_continue_ad_pressed)

	_set_state(GameState.MENU)

func _set_state(new_state: GameState) -> void:
	state = new_state
	match state:
		GameState.MENU:
			board.start_new_run()
			used_rewarded_continue = false
			board.set_playing(false)
			hud.show_menu()
			ads_manager.show_banner()
		GameState.PLAYING:
			board.set_playing(true)
			hud.show_playing()
			ads_manager.hide_banner()
		GameState.PAUSED:
			board.set_playing(false)
			hud.show_paused()
		GameState.GAME_OVER:
			board.set_playing(false)
		GameState.CREDITS:
			board.set_playing(false)
			hud.show_credits()

func _on_start_pressed() -> void:
	_set_state(GameState.PLAYING)

func _on_shop_pressed() -> void:
	print("[UI] Tienda próximamente")

func _on_credits_pressed() -> void:
	_set_state(GameState.CREDITS)

func _on_close_credits_pressed() -> void:
	_set_state(GameState.MENU)

func _on_pause_pressed() -> void:
	if state == GameState.PLAYING:
		_set_state(GameState.PAUSED)

func _on_resume_pressed() -> void:
	if state == GameState.PAUSED:
		_set_state(GameState.PLAYING)

func _on_retry_pressed() -> void:
	board.start_new_run()
	used_rewarded_continue = false
	_set_state(GameState.PLAYING)

func _on_back_to_menu_pressed() -> void:
	_set_state(GameState.MENU)

func _on_continue_ad_pressed() -> void:
	if used_rewarded_continue:
		return
	if ads_manager.show_rewarded_continue() and board.revive_player_once():
		used_rewarded_continue = true
		_set_state(GameState.PLAYING)

func _on_board_game_over(final_score: int) -> void:
	finished_runs += 1
	if finished_runs % 3 == 0:
		ads_manager.show_interstitial()
	_set_state(GameState.GAME_OVER)
	hud.show_game_over(final_score, not used_rewarded_continue)
