extends CanvasLayer
class_name HUD

signal pause_pressed
signal resume_pressed
signal retry_pressed
signal back_to_menu_pressed
signal start_pressed
signal shop_pressed
signal credits_pressed
signal close_credits_pressed
signal continue_ad_pressed
signal close_shop_pressed
signal buy_powerup_pressed(powerup_id: String)
signal use_powerup_pressed(powerup_id: String)

@onready var score_value: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var combo_value: Label = $MarginContainer/VBoxContainer/ComboLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/CoinsLabel
@onready var missions_label: Label = $MarginContainer/VBoxContainer/MissionsLabel
@onready var danger_bar: ProgressBar = $MarginContainer/VBoxContainer/DangerBar
@onready var pause_button: Button = $MarginContainer/VBoxContainer/PauseButton
@onready var bomb_button: Button = $MarginContainer/VBoxContainer/PowerupRow/BombUseButton
@onready var freeze_button: Button = $MarginContainer/VBoxContainer/PowerupRow/FreezeUseButton
@onready var column_button: Button = $MarginContainer/VBoxContainer/PowerupRow/ColumnUseButton
@onready var menu_panel: PanelContainer = $MenuPanel
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var continue_ad_button: Button = $GameOverPanel/VBoxContainer/ContinueAdButton

func _ready() -> void:
	pause_button.pressed.connect(_on_pause_button_pressed)
	$MenuPanel/VBoxContainer/StartButton.pressed.connect(func() -> void: start_pressed.emit())
	$MenuPanel/VBoxContainer/ShopButton.pressed.connect(func() -> void: shop_pressed.emit())
	$MenuPanel/VBoxContainer/CreditsButton.pressed.connect(func() -> void: credits_pressed.emit())
	$PausePanel/VBoxContainer/ResumeButton.pressed.connect(func() -> void: resume_pressed.emit())
	$GameOverPanel/VBoxContainer/ContinueAdButton.pressed.connect(func() -> void: continue_ad_pressed.emit())
	$GameOverPanel/VBoxContainer/RetryButton.pressed.connect(func() -> void: retry_pressed.emit())
	$GameOverPanel/VBoxContainer/MenuButton.pressed.connect(func() -> void: back_to_menu_pressed.emit())
	$CreditsPanel/VBoxContainer/CloseCreditsButton.pressed.connect(func() -> void: close_credits_pressed.emit())
	$ShopPanel/VBoxContainer/CloseShopButton.pressed.connect(func() -> void: close_shop_pressed.emit())
	$ShopPanel/VBoxContainer/BuyBombButton.pressed.connect(func() -> void: buy_powerup_pressed.emit("bomb"))
	$ShopPanel/VBoxContainer/BuyFreezeButton.pressed.connect(func() -> void: buy_powerup_pressed.emit("freeze"))
	$ShopPanel/VBoxContainer/BuyColumnButton.pressed.connect(func() -> void: buy_powerup_pressed.emit("clear_column"))
	bomb_button.pressed.connect(func() -> void: use_powerup_pressed.emit("bomb"))
	freeze_button.pressed.connect(func() -> void: use_powerup_pressed.emit("freeze"))
	column_button.pressed.connect(func() -> void: use_powerup_pressed.emit("clear_column"))

func set_score(value: int) -> void:
	score_value.text = "Score: %d" % value

func set_combo(value: int) -> void:
	combo_value.text = "Combo: x%d" % value

func set_coins(value: int) -> void:
	coins_label.text = "Rift Coins: %d" % value

func set_missions(text_value: String) -> void:
	missions_label.text = text_value

func set_powerup_counts(inv: Dictionary) -> void:
	bomb_button.text = "Bomba (%d)" % int(inv.get("bomb", 0))
	freeze_button.text = "Congelar (%d)" % int(inv.get("freeze", 0))
	column_button.text = "Limpiar Columna (%d)" % int(inv.get("clear_column", 0))

func set_danger(value: float) -> void:
	danger_bar.value = value * 100.0

func show_menu() -> void:
	menu_panel.visible = true
	shop_panel.visible = false
	pause_panel.visible = false
	game_over_panel.visible = false
	credits_panel.visible = false
	pause_button.visible = false

func show_shop() -> void:
	menu_panel.visible = false
	shop_panel.visible = true
	pause_panel.visible = false
	game_over_panel.visible = false
	credits_panel.visible = false
	pause_button.visible = false

func show_playing() -> void:
	menu_panel.visible = false
	shop_panel.visible = false
	pause_panel.visible = false
	game_over_panel.visible = false
	credits_panel.visible = false
	pause_button.visible = true

func show_paused() -> void:
	pause_panel.visible = true
	menu_panel.visible = false
	shop_panel.visible = false
	game_over_panel.visible = false
	credits_panel.visible = false
	pause_button.visible = false

func show_credits() -> void:
	credits_panel.visible = true
	menu_panel.visible = false
	shop_panel.visible = false
	pause_panel.visible = false
	game_over_panel.visible = false
	pause_button.visible = false

func show_game_over(final_score: int, can_continue: bool) -> void:
	final_score_label.text = "Score final: %d" % final_score
	continue_ad_button.visible = can_continue
	game_over_panel.visible = true
	pause_panel.visible = false
	shop_panel.visible = false
	menu_panel.visible = false
	credits_panel.visible = false
	pause_button.visible = false

func _on_pause_button_pressed() -> void:
	pause_pressed.emit()
