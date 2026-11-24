extends Control
class_name FlyingPoint

## Золотое очко улучшения, которое летит по дуге от счётчика к строке
## (или обратно). Скрипт сам рисует свечение и финальный ring-burst,
## чтобы не плодить отдельные сцены и текстуры.

signal arrived

const ORB_SIZE: float = 44.0
const CORE_RADIUS: float = 9.0
const GLOW_RADIUS: float = 19.0
const RING_DURATION: float = 0.24

var _from: Vector2
var _to: Vector2
var _control: Vector2
var _duration: float = 0.55
var _ring_progress: float = 0.0
var _show_ring: bool = false

var _move_tween: Tween
var _scale_tween: Tween
var _ring_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(ORB_SIZE, ORB_SIZE)
	size = Vector2(ORB_SIZE, ORB_SIZE)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100


func play(from: Vector2, to: Vector2, duration: float = 0.55) -> void:
	_from = from
	_to = to
	_duration = maxf(duration, 0.1)

	var delta := _to - _from
	var distance := delta.length()
	var side := 1.0 if randf() < 0.5 else -1.0
	var arc := clampf(distance * 0.18, 28.0, 96.0) * side
	_control = (_from + _to) * 0.5 + delta.normalized().orthogonal() * arc
	_control.y -= clampf(distance * 0.08, 16.0, 42.0)

	_set_progress(0.0)
	scale = Vector2.ONE * 0.45
	rotation = randf_range(-0.4, 0.4)
	modulate.a = 1.0

	_move_tween = create_tween()
	_move_tween.tween_method(_set_progress, 0.0, 1.0, _duration) \
		.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	_move_tween.finished.connect(_on_move_finished)

	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", Vector2.ONE * 1.18, _duration * 0.38) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", Vector2.ONE * 0.92, _duration * 0.62) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_scale_tween.tween_property(self, "scale", Vector2.ONE * 0.15, 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	var spin := create_tween()
	spin.tween_property(self, "rotation", rotation + TAU * 0.65, _duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_progress(t: float) -> void:
	var inv := 1.0 - t
	var point := _from * (inv * inv) + _control * (2.0 * inv * t) + _to * (t * t)
	global_position = point - size * 0.5


func _on_move_finished() -> void:
	arrived.emit()
	_show_ring = true
	_ring_tween = create_tween()
	_ring_tween.tween_method(_set_ring_progress, 0.0, 1.0, RING_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_ring_tween.finished.connect(queue_free)


func _set_ring_progress(value: float) -> void:
	_ring_progress = value
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5

	if _show_ring:
		var radius := CORE_RADIUS + 2.0 + 26.0 * _ring_progress
		var alpha := 1.0 - _ring_progress
		draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.88, 0.4, alpha), 3.0, true)
		return

	draw_circle(center, GLOW_RADIUS, Color(1.0, 0.78, 0.22, 0.18))
	draw_circle(center, CORE_RADIUS + 3.0, Color(1.0, 0.82, 0.3, 0.35))
	draw_circle(center, CORE_RADIUS, Color(1.0, 0.9, 0.48, 1.0))
	draw_circle(
		center + Vector2(-CORE_RADIUS * 0.28, -CORE_RADIUS * 0.3),
		CORE_RADIUS * 0.32,
		Color(1.0, 1.0, 0.9, 0.95)
	)


func _exit_tree() -> void:
	for tween in [_move_tween, _scale_tween, _ring_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
