extends Node

## Единственный владелец паузы и Engine.time_scale.
## Живёт автолоадом, поэтому переживает смену игровых сцен.
## Все твины, которые должны работать во время паузы или замедления,
## создаются через modal_tween().

signal paused_changed(paused: bool)

const PAUSE_TIME_SCALE: float = 0.05
const RESUME_DURATION: float = 1.0

var _paused: bool = false
var _can_pause: bool = true
var _resume_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE or key.keycode == KEY_P or key.physical_keycode == KEY_P:
		if _paused:
			resume()
		elif _can_pause:
			pause()
		get_viewport().set_input_as_handled()


func is_paused() -> bool:
	return _paused


func can_pause() -> bool:
	return _can_pause


func pause() -> void:
	if _paused or not _can_pause:
		return
	_kill_resume()
	_paused = true
	# Небольшое замедление перед паузой даёт заметный разгон после Resume.
	Engine.time_scale = PAUSE_TIME_SCALE
	get_tree().paused = true
	paused_changed.emit(true)


func resume() -> void:
	if not _paused:
		return
	_paused = false
	get_tree().paused = false
	paused_changed.emit(false)

	_kill_resume()
	_resume_tween = modal_tween()
	_resume_tween.tween_method(
		_set_time_scale,
		Engine.time_scale,
		1.0,
		RESUME_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Аварийно снимает паузу и запрещает её до следующего reset().
## Используется при смерти ракеты и принудительном выходе из забега.
func abort() -> void:
	var was_paused := _paused
	_kill_resume()
	_paused = false
	_can_pause = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	if was_paused:
		paused_changed.emit(false)


## Сбрасывает состояние для новой игровой сцены.
func reset() -> void:
	var was_paused := _paused
	_kill_resume()
	_paused = false
	_can_pause = true
	Engine.time_scale = 1.0
	get_tree().paused = false
	if was_paused:
		paused_changed.emit(false)


func set_can_pause(value: bool) -> void:
	_can_pause = value


## Твин, который продолжает идти во время паузы и не зависит от time_scale.
func modal_tween() -> Tween:
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween


func _set_time_scale(value: float) -> void:
	Engine.time_scale = value


func _kill_resume() -> void:
	if _resume_tween != null and _resume_tween.is_valid():
		_resume_tween.kill()
	_resume_tween = null
