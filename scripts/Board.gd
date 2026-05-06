extends Node2D
class_name Board

signal score_changed(score: int)
signal combo_changed(combo: int)
signal danger_changed(value: float)
signal game_over(final_score: int)

const WIDTH := 8
const HEIGHT := 10
const CELL_SIZE := Vector2i(120, 120)
const PIECE_SCENE := preload("res://scenes/Piece.tscn")
const ENEMY_SCENE := preload("res://scenes/EnemyPiece.tscn")

@export var spawn_colors: int = 5
@export var danger_rise_per_second: float = 0.03
@export var danger_drop_per_clear: float = 0.1
@export var pressure_interval_seconds: float = 7.0
@export var speed_step_interval_seconds: float = 30.0
@export var speed_multiplier_per_step: float = 1.15

@export var enemy_spawn_interval_seconds: float = 8.0
@export var enemy_bottom_damage: float = 0.2

var grid: Array = []
var selected_piece: Piece
var score := 0
var combo := 0
var danger := 0.0
var is_resolving := false
var is_playing := false
var is_game_over := false

var time_without_match := 0.0
var elapsed_play_time := 0.0
var speed_level := 0
var enemy_spawn_timer := 0.0

func _ready() -> void:
	randomize()
	start_new_run()

func _process(delta: float) -> void:
	if not is_playing or is_resolving or is_game_over:
		return

	elapsed_play_time += delta
	var expected_speed_level := int(elapsed_play_time / speed_step_interval_seconds)
	if expected_speed_level != speed_level:
		speed_level = expected_speed_level

	var speed_factor := _speed_factor()
	danger = clamp(danger + danger_rise_per_second * speed_factor * delta, 0.0, 1.0)
	danger_changed.emit(danger)

	time_without_match += delta
	var interval := pressure_interval_seconds / speed_factor
	if time_without_match >= interval:
		time_without_match = 0.0
		_push_pressure_row_from_top()

	enemy_spawn_timer += delta
	if enemy_spawn_timer >= enemy_spawn_interval_seconds:
		enemy_spawn_timer = 0.0
		_spawn_random_enemy_inside_board()

func start_new_run() -> void:
	_clear_board_nodes()
	_initialize_grid()
	score = 0
	combo = 0
	danger = 0.0
	time_without_match = 0.0
	elapsed_play_time = 0.0
	speed_level = 0
	enemy_spawn_timer = 0.0
	is_resolving = false
	is_game_over = false
	is_playing = false
	selected_piece = null
	_spawn_initial_board()
	_emit_ui()
	call_deferred("_resolve_board_loop")

func set_playing(enabled: bool) -> void:
	if is_game_over:
		is_playing = false
		return
	is_playing = enabled

func _initialize_grid() -> void:
	grid.resize(HEIGHT)
	for y in HEIGHT:
		grid[y] = []
		grid[y].resize(WIDTH)
		for x in WIDTH:
			grid[y][x] = null

func _spawn_initial_board() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var piece := _create_piece(x, y, false)
			while _creates_match_at(x, y, piece.color_id):
				piece.set_color_id(randi() % spawn_colors)
			grid[y][x] = piece

func _create_piece(x: int, y: int, animated := true) -> Piece:
	var piece := PIECE_SCENE.instantiate() as Piece
	add_child(piece)
	piece.z_index = 1
	piece.set_color_id(randi() % spawn_colors)
	piece.position = _grid_to_position(x, y)
	if animated:
		piece.position.y -= CELL_SIZE.y * 2
		piece.create_tween().tween_property(piece, "position", _grid_to_position(x, y), 0.2)
	piece.piece_selected.connect(_on_piece_selected)
	return piece

func _create_enemy(x: int, y: int, enemy_type: EnemyPiece.EnemyType, animated := true) -> EnemyPiece:
	var enemy := ENEMY_SCENE.instantiate() as EnemyPiece
	add_child(enemy)
	enemy.z_index = 2
	enemy.configure(enemy_type)
	enemy.position = _grid_to_position(x, y)
	if animated:
		enemy.position.y -= CELL_SIZE.y * 2
		enemy.create_tween().tween_property(enemy, "position", _grid_to_position(x, y), 0.2)
	return enemy

func _grid_to_position(x: int, y: int) -> Vector2:
	return Vector2(x * CELL_SIZE.x + CELL_SIZE.x / 2.0, y * CELL_SIZE.y + CELL_SIZE.y / 2.0)

func _on_piece_selected(piece: Piece) -> void:
	if not is_playing or is_resolving or is_game_over:
		return
	if piece is EnemyPiece:
		return
	var coords := _find_piece(piece)
	if coords == Vector2i(-1, -1):
		return
	if selected_piece == null:
		selected_piece = piece
		piece.scale = Vector2.ONE * 1.08
		return
	if selected_piece == piece:
		piece.scale = Vector2.ONE
		selected_piece = null
		return
	var first_coords := _find_piece(selected_piece)
	if _is_adjacent(first_coords, coords):
		selected_piece.scale = Vector2.ONE
		_swap_and_resolve(first_coords, coords)
		selected_piece = null
	else:
		selected_piece.scale = Vector2.ONE
		selected_piece = piece
		piece.scale = Vector2.ONE * 1.08

func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1

func _find_piece(target: Piece) -> Vector2i:
	for y in HEIGHT:
		for x in WIDTH:
			if grid[y][x] == target:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _swap_and_resolve(a: Vector2i, b: Vector2i) -> void:
	if grid[a.y][a.x] is EnemyPiece or grid[b.y][b.x] is EnemyPiece:
		return
	is_resolving = true
	_swap_cells(a, b)
	_animate_swap(a, b)
	await get_tree().create_timer(0.15).timeout
	var matches := _find_all_matches()
	if matches.is_empty():
		_swap_cells(a, b)
		_animate_swap(a, b)
		await get_tree().create_timer(0.15).timeout
		combo = 0
		combo_changed.emit(combo)
		is_resolving = false
		await _advance_enemy_turn()
		return
	await _resolve_board_loop()
	await _advance_enemy_turn()
	is_resolving = false

func _swap_cells(a: Vector2i, b: Vector2i) -> void:
	var temp: Piece = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = temp

func _animate_swap(a: Vector2i, b: Vector2i) -> void:
	var pa: Piece = grid[a.y][a.x]
	var pb: Piece = grid[b.y][b.x]
	if pa: pa.create_tween().tween_property(pa, "position", _grid_to_position(a.x, a.y), 0.12)
	if pb: pb.create_tween().tween_property(pb, "position", _grid_to_position(b.x, b.y), 0.12)

func _resolve_board_loop() -> void:
	is_resolving = true
	var chain := 0
	while true:
		var matches := _find_all_matches()
		if matches.is_empty():
			break
		chain += 1
		combo = chain
		combo_changed.emit(combo)
		_apply_match_damage_to_enemies(matches)
		_clear_matches(matches)
		score += matches.size() * 10 * chain
		score_changed.emit(score)
		danger = clamp(danger - danger_drop_per_clear, 0.0, 1.0)
		danger_changed.emit(danger)
		time_without_match = 0.0
		await get_tree().create_timer(0.08).timeout
		_apply_gravity()
		await get_tree().create_timer(0.12).timeout
		_spawn_new_pieces()
		await get_tree().create_timer(0.16).timeout
	if chain == 0:
		combo = 0
		combo_changed.emit(combo)
	is_resolving = false

func _find_all_matches() -> Array[Vector2i]:
	var found := {}
	for y in HEIGHT:
		var run_color := -1
		var run_start := 0
		var run_len := 0
		for x in WIDTH:
			var piece: Piece = grid[y][x]
			var is_enemy := piece is EnemyPiece
			var color := piece.color_id if piece and not is_enemy else -1
			if color == run_color and color != -1:
				run_len += 1
			else:
				if run_len >= 3:
					for i in run_len:
						found[Vector2i(run_start + i, y)] = true
				run_color = color
				run_start = x
				run_len = 1
		if run_len >= 3:
			for i in run_len:
				found[Vector2i(run_start + i, y)] = true

	for x in WIDTH:
		var run_color_v := -1
		var run_start_v := 0
		var run_len_v := 0
		for y in HEIGHT:
			var piece: Piece = grid[y][x]
			var is_enemy := piece is EnemyPiece
			var color := piece.color_id if piece and not is_enemy else -1
			if color == run_color_v and color != -1:
				run_len_v += 1
			else:
				if run_len_v >= 3:
					for i in run_len_v:
						found[Vector2i(x, run_start_v + i)] = true
				run_color_v = color
				run_start_v = y
				run_len_v = 1
		if run_len_v >= 3:
			for i in run_len_v:
				found[Vector2i(x, run_start_v + i)] = true

	return found.keys()

func _clear_matches(matches: Array[Vector2i]) -> void:
	for cell in matches:
		var piece: Piece = grid[cell.y][cell.x]
		if piece:
			piece.create_tween().tween_property(piece, "scale", Vector2.ZERO, 0.08)
			await get_tree().create_timer(0.03).timeout
			piece.queue_free()
		grid[cell.y][cell.x] = null

func _apply_match_damage_to_enemies(matches: Array[Vector2i]) -> void:
	var processed := {}
	for cell in matches:
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var adj := cell + dir
			if not _is_inside(adj):
				continue
			var piece := grid[adj.y][adj.x]
			if piece is EnemyPiece and not processed.has(adj):
				processed[adj] = true
				var enemy := piece as EnemyPiece
				if enemy.take_damage(1):
					enemy.queue_free()
					grid[adj.y][adj.x] = null

func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WIDTH and cell.y >= 0 and cell.y < HEIGHT

func _apply_gravity() -> void:
	for x in WIDTH:
		var write_y := HEIGHT - 1
		for y in range(HEIGHT - 1, -1, -1):
			var piece: Piece = grid[y][x]
			if piece:
				if y != write_y:
					grid[write_y][x] = piece
					grid[y][x] = null
					piece.create_tween().tween_property(piece, "position", _grid_to_position(x, write_y), 0.12)
				write_y -= 1
		for fill_y in range(write_y, -1, -1):
			grid[fill_y][x] = null

func _spawn_new_pieces() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			if grid[y][x] == null:
				var piece := _create_piece(x, y, true)
				grid[y][x] = piece

func _creates_match_at(x: int, y: int, color_id: int) -> bool:
	if x >= 2 and grid[y][x - 1] and grid[y][x - 2]:
		if grid[y][x - 1].color_id == color_id and grid[y][x - 2].color_id == color_id:
			return true
	if y >= 2 and grid[y - 1][x] and grid[y - 2][x]:
		if grid[y - 1][x].color_id == color_id and grid[y - 2][x].color_id == color_id:
			return true
	return false

func _push_pressure_row_from_top() -> void:
	for x in WIDTH:
		if grid[HEIGHT - 1][x] != null:
			_trigger_game_over()
			return

	for y in range(HEIGHT - 1, 0, -1):
		for x in WIDTH:
			var moving_piece: Piece = grid[y - 1][x]
			grid[y][x] = moving_piece
			if moving_piece:
				moving_piece.create_tween().tween_property(moving_piece, "position", _grid_to_position(x, y), 0.1)

	for x in WIDTH:
		var piece := _create_piece(x, 0, false)
		grid[0][x] = piece
		piece.position = _grid_to_position(x, 0)

	await get_tree().create_timer(0.12).timeout
	await _resolve_board_loop()

func _spawn_random_enemy_inside_board() -> void:
	if is_resolving or is_game_over:
		return
	var available: Array[Vector2i] = []
	for y in range(1, HEIGHT - 2):
		for x in WIDTH:
			if grid[y][x] == null:
				available.append(Vector2i(x, y))
	if available.is_empty():
		return
	var cell := available[randi() % available.size()]
	var roll := randi() % 100
	var enemy_type := EnemyPiece.EnemyType.SLIME
	if roll < 50:
		enemy_type = EnemyPiece.EnemyType.SLIME
	elif roll < 80:
		enemy_type = EnemyPiece.EnemyType.BAT
	else:
		enemy_type = EnemyPiece.EnemyType.GOLEM
	grid[cell.y][cell.x] = _create_enemy(cell.x, cell.y, enemy_type, true)

func _advance_enemy_turn() -> void:
	var to_move: Array[Vector2i] = []
	for y in range(HEIGHT - 2, -1, -1):
		for x in WIDTH:
			var piece := grid[y][x]
			if piece is EnemyPiece:
				var enemy := piece as EnemyPiece
				if enemy.should_move_this_turn():
					to_move.append(Vector2i(x, y))
	for origin in to_move:
		var enemy_piece := grid[origin.y][origin.x]
		if not (enemy_piece is EnemyPiece):
			continue
		var enemy := enemy_piece as EnemyPiece
		var next := origin + Vector2i.DOWN
		enemy.consume_turn()
		if next.y >= HEIGHT:
			grid[origin.y][origin.x] = null
			enemy.queue_free()
			_apply_enemy_reach_bottom_penalty()
			continue
		if grid[next.y][next.x] == null:
			grid[next.y][next.x] = enemy
			grid[origin.y][origin.x] = null
			enemy.create_tween().tween_property(enemy, "position", _grid_to_position(next.x, next.y), 0.12)

func _apply_enemy_reach_bottom_penalty() -> void:
	danger = clamp(danger + enemy_bottom_damage, 0.0, 1.0)
	danger_changed.emit(danger)
	if danger >= 1.0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	is_playing = false
	game_over.emit(score)

func _clear_board_nodes() -> void:
	for child in get_children():
		if child is Piece:
			child.queue_free()

func _speed_factor() -> float:
	return pow(speed_multiplier_per_step, speed_level)

func _emit_ui() -> void:
	score_changed.emit(score)
	combo_changed.emit(combo)
	danger_changed.emit(danger)
