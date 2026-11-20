extends Node

## Единственный владелец паузы и Engine.time_scale.
## Живёт автолоадом, поэтому переживает смену игровых сцен.
## Все твины, которые должны работать во время паузы или замедления,
## создаются через modal_tween().

signal paused_changed(paused: bool)
signal modal_frozen_changed(frozen: bool)

const PAUSE_TIME_SCALE: float = 0.05
const RESUME_DURATION: float = 1.0

## Сцены с этим тегом ставятся на паузу при потере фокуса окна.
## Меню/магазин тега не имеют, поэтому их сворачивание окна не ломает.
const FOCUS_PAUSE_GROUP: StringName = &"pause_on_focus_loss"

var _paused: bool = false
var _modal_frozen: bool = false
var _can_pause: bool = true
var _resume_tween: Tween
var _modal_generation: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	# Покрывает десктоп (WM), мобильные и веб (APPLICATION_FOCUS_*),
	# а также сворачивание приложения на Android/iOS (APPLICATION_PAUSED).
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_pause_on_focus_lost()


## Автопауза только для активной игровой сцены. Возврат фокуса не снимает
## паузу: игрок продолжает сам, чтобы не пропустить момент возобновления.
func _pause_on_focus_lost() -> void:
	if _paused or _modal_frozen or not _can_pause:
		return
	if get_tree().get_first_node_in_group(FOCUS_PAUSE_GROUP) == null:
		return
	pause()


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


func is_modal_frozen() -> bool:
	return _modal_frozen


func can_pause() -> bool:
	return _can_pause


## Внешняя пауза от платформы (Яндекс/Playgama). Не ставит на паузу меню,
## где нет игровой сцены, и не возобновляет игру автоматически.
func pause_for_platform() -> void:
	_pause_on_focus_lost()


func pause() -> void:
	if _paused or _modal_frozen or not _can_pause:
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


## Плавно замедляет игру и ставит её на паузу для модального выбора.
## Возвращает true, если пауза действительно наступила.
func slow_to_modal(duration: float = 0.45) -> bool:
	if _paused or _modal_frozen or not _can_pause:
		return false

	_can_pause = false
	_kill_resume()
	_modal_generation += 1
	var generation := _modal_generation

	var tween := modal_tween()
	tween.tween_method(
		_set_time_scale,
		Engine.time_scale,
		PAUSE_TIME_SCALE,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	if generation != _modal_generation:
		return false
	if _paused:
		return false

	_modal_frozen = true
	get_tree().paused = true
	modal_frozen_changed.emit(true)
	return true


## Снимает модальную паузу и плавно возвращает time_scale к 1.0.
func release_modal(duration: float = RESUME_DURATION) -> void:
	_modal_generation += 1
	var was_frozen := _modal_frozen
	_modal_frozen = false
	_can_pause = true
	get_tree().paused = false
	if was_frozen:
		modal_frozen_changed.emit(false)

	_kill_resume()
	_resume_tween = modal_tween()
	_resume_tween.tween_method(
		_set_time_scale,
		Engine.time_scale,
		1.0,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Аварийно снимает паузу и запрещает её до следующего reset().
## Используется при смерти ракеты и принудительном выходе из забега.
func abort() -> void:
	var was_paused := _paused
	var was_modal := _modal_frozen
	_modal_generation += 1
	_kill_resume()
	_paused = false
	_modal_frozen = false
	_can_pause = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	if was_paused:
		paused_changed.emit(false)
	if was_modal:
		modal_frozen_changed.emit(false)


## Сбрасывает состояние для новой игровой сцены.
func reset() -> void:
	var was_paused := _paused
	var was_modal := _modal_frozen
	_modal_generation += 1
	_kill_resume()
	_paused = false
	_modal_frozen = false
	_can_pause = true
	Engine.time_scale = 1.0
	get_tree().paused = false
	if was_paused:
		paused_changed.emit(false)
	if was_modal:
		modal_frozen_changed.emit(false)


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
