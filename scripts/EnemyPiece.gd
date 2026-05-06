extends Piece
class_name EnemyPiece

enum EnemyType {
	SLIME,
	BAT,
	GOLEM
}

@export var enemy_type: EnemyType = EnemyType.SLIME

var hp: int = 1
var move_interval_turns: int = 1
var turn_counter: int = 0

func _ready() -> void:
	super._ready()
	input_pickable = false
	configure(enemy_type)

func configure(new_type: EnemyType) -> void:
	enemy_type = new_type
	match enemy_type:
		EnemyType.SLIME:
			hp = 1
			move_interval_turns = 3
			set_color_id(2)
		EnemyType.BAT:
			hp = 1
			move_interval_turns = 1
			set_color_id(3)
		EnemyType.GOLEM:
			hp = 2
			move_interval_turns = 2
			set_color_id(1)
	_update_visual_by_type()

func should_move_this_turn() -> bool:
	turn_counter += 1
	return turn_counter >= move_interval_turns

func consume_turn() -> void:
	turn_counter = 0

func take_damage(amount: int = 1) -> bool:
	hp -= amount
	_play_damage_feedback()
	return hp <= 0

func _play_damage_feedback() -> void:
	if not is_instance_valid(color_rect):
		return
	var original_color := color_rect.color
	color_rect.color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(color_rect, "color", original_color, 0.14)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 1.12, 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)

func _update_visual_by_type() -> void:
	if not is_instance_valid(color_rect):
		return
	match enemy_type:
		EnemyType.SLIME:
			color_rect.color = Color("#4CAF50")
		EnemyType.BAT:
			color_rect.color = Color("#7E57C2")
		EnemyType.GOLEM:
			color_rect.color = Color("#8D6E63")
