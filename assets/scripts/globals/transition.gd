extends CanvasLayer

## Персистентный оверлей для fade-переходов между сценами.
## Цвет оверлея — background clear color проекта, поэтому экран "темнеет" до фона
## и новая сцена проявляется fade'ом из этого же цвета.
## Узел живёт в автолоаде, поэтому переживает смену сцен.

const FADE_DURATION: float = 0.5

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 128
	_rect = ColorRect.new()
	_rect.color = _clear_color()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.modulate.a = 0.0
	_rect.visible = false
	add_child(_rect)
	get_viewport().size_changed.connect(_resize)


func _clear_color() -> Color:
	return ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color") as Color


func _resize() -> void:
	if _rect != null:
		_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func fade_out(duration: float = FADE_DURATION) -> void:
	_kill()
	_rect.visible = true
	_rect.modulate.a = 0.0
	if duration <= 0.0:
		_rect.modulate.a = 1.0
		return
	_tween = create_tween()
	_tween.tween_property(_rect, "modulate:a", 1.0, duration)
	await _tween.finished


func fade_in(duration: float = FADE_DURATION) -> void:
	_kill()
	_rect.visible = true
	_rect.modulate.a = 1.0
	if duration <= 0.0:
		_rect.visible = false
		return
	_tween = create_tween()
	_tween.tween_property(_rect, "modulate:a", 0.0, duration)
	await _tween.finished
	_rect.visible = false


## Затемняет экран, меняет сцену и проявляет новую сцену fade'ом из clear color.
func goto(path: String, out_duration: float = FADE_DURATION, in_duration: float = FADE_DURATION) -> void:
	await fade_out(out_duration)
	get_tree().change_scene_to_file(path)
	await fade_in(in_duration)


func _kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()