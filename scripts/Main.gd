extends Node2D

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	CREDITS,
	SHOP
}

const BOARD_TOP_MARGIN := 360.0

@onready var board: Board = $Board
@onready var hud: HUD = $HUD

var ads_manager: AdsManager
var progression: ProgressionManager
var state: GameState = GameState.MENU
var finished_runs: int = 0
var used_rewarded_continue: bool = false

func _ready() -> void:
	ads_manager = AdsManager.new()
	add_child(ads_manager)
	progression = ProgressionManager.new()
	add_child(progression)

	_update_board_layout()
	get_viewport().size_changed.connect(_update_board_layout)
	board.score_changed.connect(hud.set_score)
	board.combo_changed.connect(hud.set_combo)
	board.danger_changed.connect(hud.set_danger)
	board.game_over.connect(_on_board_game_over)
	board.matches_cleared.connect(_on_matches_cleared)
	board.combo_reached.connect(_on_combo_reached)
	board.enemies_defeated.connect(_on_enemy_defeated)

	hud.start_pressed.connect(_on_start_pressed)
	hud.shop_pressed.connect(_on_shop_pressed)
	hud.close_shop_pressed.connect(_on_close_shop_pressed)
	hud.buy_powerup_pressed.connect(_on_buy_powerup_pressed)
	hud.use_powerup_pressed.connect(_on_use_powerup_pressed)
	hud.credits_pressed.connect(_on_credits_pressed)
	hud.close_credits_pressed.connect(_on_close_credits_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)
	hud.resume_pressed.connect(_on_resume_pressed)
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.back_to_menu_pressed.connect(_on_back_to_menu_pressed)
	hud.continue_ad_pressed.connect(_on_continue_ad_pressed)

	_refresh_meta_ui()
	_set_state(GameState.MENU)

func _update_board_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var board_width := float(Board.WIDTH * Board.CELL_SIZE.x)
	var x := max(0.0, (viewport_size.x - board_width) * 0.5)
	board.position = Vector2(x, BOARD_TOP_MARGIN)

func _refresh_meta_ui() -> void:
	hud.set_coins(progression.coins)
	hud.set_missions(progression.mission_summary())
	hud.set_powerup_counts(progression.powerups)

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
		GameState.SHOP:
			board.set_playing(false)
			hud.show_shop()

func _on_start_pressed() -> void:
	_set_state(GameState.PLAYING)

func _on_shop_pressed() -> void:
	_set_state(GameState.SHOP)

func _on_close_shop_pressed() -> void:
	_set_state(GameState.MENU)

func _on_buy_powerup_pressed(powerup_id: String) -> void:
	progression.buy_powerup(powerup_id)
	_refresh_meta_ui()

func _on_use_powerup_pressed(powerup_id: String) -> void:
	if state != GameState.PLAYING:
		return
	if not progression.consume_powerup(powerup_id):
		return
	match powerup_id:
		"bomb":
			board.activate_bomb()
		"freeze":
			board.activate_freeze()
		"clear_column":
			board.activate_clear_column()
	_refresh_meta_ui()

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
	progression.add_score_rewards(final_score)
	_refresh_meta_ui()
	if finished_runs % 3 == 0:
		ads_manager.show_interstitial()
	_set_state(GameState.GAME_OVER)
	hud.show_game_over(final_score, not used_rewarded_continue)

func _on_matches_cleared(amount: int) -> void:
	progression.add_matches(amount)
	_refresh_meta_ui()

func _on_combo_reached(value: int) -> void:
	progression.register_combo(value)
	_refresh_meta_ui()

func _on_enemy_defeated(amount: int) -> void:
	progression.add_enemies_defeated(amount)
	_refresh_meta_ui()
