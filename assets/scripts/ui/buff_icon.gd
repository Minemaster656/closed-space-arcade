extends Control
class_name BuffIconView

## Кружок баффа с радиальным таймером. Появление и исчезновение — твинами.

const RING_WIDTH: float = 3.0
const ICON_INSET: float = 8.0
const BACKGROUND_COLOR := Color(0.03, 0.055, 0.11, 0.82)
const RING_BACKGROUND_COLOR := Color(1.0, 1.0, 1.0, 0.14)

var _buff: BuffInstance
var _tween: Tween
var _ending: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_update_pivot)
	_update_pivot()


func setup(buff: BuffInstance) -> void:
	_buff = buff
	scale = Vector2(0.35, 0.35)
	modulate.a = 0.0
	queue_redraw()
	call_deferred("_play_intro")


func pulse() -> void:
	if _ending:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_outro() -> void:
	if _ending:
		return
	_ending = true
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2(0.25, 0.25), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.16)
	_tween.finished.connect(_on_outro_finished)


func _process(_delta: float) -> void:
	if _buff != null and not _ending:
		queue_redraw()


func _draw() -> void:
	if _buff == null or _buff.def == null:
		return

	var diameter := minf(size.x, size.y)
	if diameter <= 0.0:
		diameter = custom_minimum_size.x
	var center := size * 0.5
	var radius := diameter * 0.5 - RING_WIDTH

	draw_circle(center, radius + 1.0, BACKGROUND_COLOR)

	var def := _buff.def
	if def.icon != null:
		var icon_size := maxf(0.0, (radius - ICON_INSET) * 2.0)
		var icon_rect := Rect2(center - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
		draw_texture_rect(def.icon, icon_rect, false, Color.WHITE)

	var ring_radius := radius - RING_WIDTH * 0.5
	draw_arc(center, ring_radius, 0.0, TAU, 64, RING_BACKGROUND_COLOR, RING_WIDTH, true)

	var ratio := 1.0
	if def.duration > 0.0:
		ratio = clampf(_buff.remaining / def.duration, 0.0, 1.0)
	var start_angle := -PI * 0.5
	draw_arc(center, ring_radius, start_angle, start_angle + TAU * ratio, 64, def.accent_color, RING_WIDTH, true)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _play_intro() -> void:
	_kill_tween()
	scale = Vector2(0.35, 0.35)
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _on_outro_finished() -> void:
	queue_free()
