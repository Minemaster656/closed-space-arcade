extends Node2D
class_name HPBar

@export_group("Colors")
@export var bg_color: Color = Color(0.12, 0.12, 0.16, 1)
@export var white_color: Color = Color.WHITE
@export var fill_color: Color = Color(0.25, 0.9, 0.35, 1)
@export var flash_color: Color = Color(1, 0.25, 0.25, 1)

@export_group("Geometry")
@export var size: Vector2 = Vector2(96, 8)
@export var white_inset: float = 1.0

@export_group("Tween")
@export var flash_duration: float = 0.06
@export var fill_duration: float = 0.22

@onready var _bg: ColorRect = $BG
@onready var _white: ColorRect = $White
@onready var _fill: ColorRect = $Fill

var _max_hp: float = 1.0
var _hp: float = 1.0
var _fill_tween: Tween
var _color_tween: Tween

func _ready() -> void:
	_build()

func setup(max_hp: float, hp: float) -> void:
	_max_hp = max_hp
	_hp = hp
	_build()
	_update_fill()


func set_health(value: float) -> void:
	_hp = clampf(value, 0.0, _max_hp)

	if _color_tween != null and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = create_tween()
	_color_tween.tween_property(_fill, "modulate", flash_color, flash_duration)
	_color_tween.chain().tween_property(_fill, "modulate", fill_color, flash_duration)

	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()
	var target_pct := _hp / _max_hp
	_fill_tween = create_tween()
	_fill_tween.tween_property(_fill, "size", Vector2(size.x * target_pct, size.y), fill_duration) \
		.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)


func _build() -> void:
	_bg.size = size
	_bg.modulate = bg_color
	_white.size = size - Vector2(white_inset * 2.0, white_inset * 2.0)
	_white.position = Vector2(white_inset, white_inset)
	_white.modulate = white_color
	_fill.size = size
	_fill.modulate = fill_color


func _update_fill() -> void:
	var pct := clampf(_hp / _max_hp, 0.0, 1.0)
	_fill.size = Vector2(size.x * pct, size.y)
