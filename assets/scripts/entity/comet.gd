extends Area2D
class_name Comet

## Коллекционная комета. Сама летает по экрану и отдаёт сигнал при подборе.
## Упругую подсказку показывает только первый комет забега.

signal collected(comet: Comet)

@export var speed: float = 78.0
@export var patrol_margin: float = 44.0
@export var sprite_spin_speed: float = 0.6

@onready var _sprite: Sprite2D = $Sprite2D

var _velocity: Vector2 = Vector2.ZERO
var _bounds: Rect2 = Rect2()
var _taken: bool = false
var _hint: Label
var _hint_tween: Tween


func _ready() -> void:
	_bounds = Utils.get_visible_world_rect().grow(-patrol_margin)
	if _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		_bounds = Rect2(Vector2(-300, -500), Vector2(600, 1000))

	var start := _bounds.get_center() + Vector2(
		randf_range(-_bounds.size.x * 0.22, _bounds.size.x * 0.22),
		randf_range(-_bounds.size.y * 0.18, _bounds.size.y * 0.18)
	)
	global_position = start
	_velocity = Vector2.from_angle(randf() * TAU) * speed


func _process(delta: float) -> void:
	if _taken:
		return

	global_position += _velocity * delta
	_bounce()
	if _sprite != null:
		_sprite.rotation += sprite_spin_speed * delta


func collect() -> void:
	if _taken:
		return
	_taken = true
	_kill_hint_tween()
	collected.emit(self)
	queue_free()


## Упругая, слегка случайно наклонённая подсказка рядом с кометой.
func show_hint(text_key: String = "ui_comet_hint") -> void:
	if _hint != null or _taken:
		return

	_hint = Label.new()
	_hint.text = tr(text_key)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.size = Vector2(300.0, 52.0)
	_hint.position = Vector2(-150.0, -78.0)
	_hint.rotation = deg_to_rad(randf_range(-10.0, 10.0))
	_hint.pivot_offset = _hint.size * 0.5
	_hint.add_theme_font_size_override("font_size", 27)
	_hint.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	_hint.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.09))
	_hint.add_theme_constant_override("outline_size", 9)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	_hint.scale = Vector2(0.08, 0.08)
	_hint.modulate.a = 0.0
	_hint_tween = create_tween().set_parallel(true)
	_hint_tween.tween_property(_hint, "scale", Vector2.ONE, 0.8) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_hint_tween.tween_property(_hint, "modulate:a", 1.0, 0.22)
	_hint_tween.tween_property(_hint, "rotation", _hint.rotation, 0.8) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _bounce() -> void:
	var pos := global_position
	if pos.x < _bounds.position.x:
		pos.x = _bounds.position.x
		_velocity.x = absf(_velocity.x)
	elif pos.x > _bounds.end.x:
		pos.x = _bounds.end.x
		_velocity.x = -absf(_velocity.x)

	if pos.y < _bounds.position.y:
		pos.y = _bounds.position.y
		_velocity.y = absf(_velocity.y)
	elif pos.y > _bounds.end.y:
		pos.y = _bounds.end.y
		_velocity.y = -absf(_velocity.y)

	global_position = pos


func _kill_hint_tween() -> void:
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = null


func _exit_tree() -> void:
	_kill_hint_tween()
