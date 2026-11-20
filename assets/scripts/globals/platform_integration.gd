extends Node

## Мост между игрой и платформой (Яндекс Игры через Playgama Bridge).
##
## На десктопе и в редакторе все методы — безопасные no-op, поэтому один и тот
## же код игры работает и в локальной сборке, и на платформе. На вебе модуль
## сообщает платформе о готовности и геймплее, принимает внешнюю паузу и
## запрет звука, а также показывает межстраничную рекламу в естественных
## паузах (смерть забега / выход в магазин).

var _game_ready_sent: bool = false
var _gameplay_active: bool = false
var _gameplay_running: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	# Bridge стоит первым автолоадом и уже готов к этому моменту.
	_init_web()


func _init_web() -> void:
	if Bridge == null or Bridge.platform == null:
		return

	Bridge.platform.audio_state_changed.connect(_on_audio_state_changed)
	Bridge.platform.pause_state_changed.connect(_on_platform_pause_changed)
	PauseManager.paused_changed.connect(_on_game_pause_changed)

	AudioSettings.set_platform_audio_enabled(bool(Bridge.platform.is_audio_enabled))
	_apply_platform_language(String(Bridge.platform.language))


## Первый кадр, в котором игрок уже может управлять игрой.
## Прячем загрузочный экран платформы только после этого.
func mark_game_ready() -> void:
	if not OS.has_feature("web") or _game_ready_sent:
		return
	_game_ready_sent = true
	Bridge.platform.send_message(Bridge.PlatformMessage.GAME_READY)


func gameplay_started() -> void:
	if not OS.has_feature("web"):
		return
	_gameplay_active = true
	if PauseManager.is_paused() or PauseManager.is_modal_frozen():
		return
	if _gameplay_running:
		return
	_gameplay_running = true
	Bridge.platform.send_message(Bridge.PlatformMessage.GAMEPLAY_STARTED)


func gameplay_stopped() -> void:
	if not OS.has_feature("web"):
		return
	_gameplay_active = false
	if not _gameplay_running:
		return
	_gameplay_running = false
	Bridge.platform.send_message(Bridge.PlatformMessage.GAMEPLAY_STOPPED)


## Межстраничная реклама допустима только в естественной паузе.
## Платформа сама решает, показывать ли её сейчас (частота, лимиты).
func show_interstitial(placement: String = "") -> void:
	if not OS.has_feature("web"):
		return
	if Bridge == null or Bridge.advertisement == null:
		return
	if not Bridge.advertisement.is_interstitial_supported:
		return
	if placement.is_empty():
		Bridge.advertisement.show_interstitial()
	else:
		Bridge.advertisement.show_interstitial(placement)


func _on_game_pause_changed(paused: bool) -> void:
	if not OS.has_feature("web") or not _gameplay_active:
		return
	if paused:
		gameplay_stopped()
	else:
		gameplay_started()


func _on_audio_state_changed(enabled: bool) -> void:
	AudioSettings.set_platform_audio_enabled(enabled)


func _on_platform_pause_changed(paused: bool) -> void:
	if not OS.has_feature("web"):
		return
	if paused:
		# Платформа требует паузу (например, игрок открыл меню Яндекса).
		# Возврат фокуса не возобновляет игру автоматически — решает игрок.
		PauseManager.pause_for_platform()


func _apply_platform_language(code: String) -> void:
	var normalized := code.to_lower()
	if normalized.begins_with("ru"):
		TranslationServer.set_locale("ru")
	elif not normalized.is_empty():
		TranslationServer.set_locale("en")
