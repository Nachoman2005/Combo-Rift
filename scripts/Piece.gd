extends Area2D
class_name Piece

signal piece_selected(piece: Piece)

@export var color_id: int = 0

@onready var color_rect: ColorRect = $ColorRect

const COLORS := [
	Color("#ff4d6d"),
	Color("#ffd166"),
	Color("#06d6a0"),
	Color("#118ab2"),
	Color("#9b5de5")
]

func _ready() -> void:
	input_pickable = true
	set_color_id(color_id)

func set_color_id(new_color_id: int) -> void:
	color_id = wrapi(new_color_id, 0, COLORS.size())
	if is_instance_valid(color_rect):
		color_rect.color = COLORS[color_id]

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		piece_selected.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		piece_selected.emit(self)
