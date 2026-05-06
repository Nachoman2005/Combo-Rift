extends Node
class_name ProgressionManager

const SAVE_PATH := "user://save_data.json"
const POWERUP_COSTS := {
	"bomb": 120,
	"freeze": 90,
	"clear_column": 110
}

var coins: int = 0
var powerups := {
	"bomb": 0,
	"freeze": 0,
	"clear_column": 0
}
var daily := {
	"date": "",
	"matches": 0,
	"combo5": false,
	"enemies": 0,
	"claimed": {
		"matches": false,
		"combo5": false,
		"enemies": false
	}
}

func _ready() -> void:
	load_data()

func load_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			coins = int(parsed.get("coins", 0))
			powerups.merge(parsed.get("powerups", {}), true)
			daily.merge(parsed.get("daily", {}), true)
	_reset_daily_if_needed()
	save_data()

func save_data() -> void:
	var payload := {
		"coins": coins,
		"powerups": powerups,
		"daily": daily
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

func add_score_rewards(score: int) -> int:
	var gained := max(1, score / 20)
	coins += gained
	save_data()
	return gained

func add_matches(amount: int) -> void:
	daily.matches = int(daily.matches) + amount
	_claim_if_ready("matches", int(daily.matches) >= 20, 80)

func register_combo(combo: int) -> void:
	if combo >= 5:
		daily.combo5 = true
		_claim_if_ready("combo5", true, 100)

func add_enemies_defeated(amount: int) -> void:
	daily.enemies = int(daily.enemies) + amount
	_claim_if_ready("enemies", int(daily.enemies) >= 10, 90)

func buy_powerup(powerup_id: String) -> bool:
	if not POWERUP_COSTS.has(powerup_id):
		return false
	var cost: int = POWERUP_COSTS[powerup_id]
	if coins < cost:
		return false
	coins -= cost
	powerups[powerup_id] = int(powerups.get(powerup_id, 0)) + 1
	save_data()
	return true

func consume_powerup(powerup_id: String) -> bool:
	var current := int(powerups.get(powerup_id, 0))
	if current <= 0:
		return false
	powerups[powerup_id] = current - 1
	save_data()
	return true

func mission_summary() -> String:
	return "Diarias: Matches %d/20 | Combo x5 %s | Enemigos %d/10" % [int(daily.matches), "OK" if daily.combo5 else "--", int(daily.enemies)]

func _claim_if_ready(key: String, condition: bool, reward: int) -> void:
	if not condition:
		save_data()
		return
	var claimed := daily.claimed as Dictionary
	if claimed.get(key, false):
		return
	claimed[key] = true
	coins += reward
	daily.claimed = claimed
	save_data()

func _reset_daily_if_needed() -> void:
	var today := Time.get_date_string_from_system()
	if daily.get("date", "") == today:
		return
	daily = {
		"date": today,
		"matches": 0,
		"combo5": false,
		"enemies": 0,
		"claimed": {
			"matches": false,
			"combo5": false,
			"enemies": false
		}
	}
