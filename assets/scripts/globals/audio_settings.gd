extends Node

## Единая точка управления громкостью музыки и игровых звуков.
##
## Музыка и SFX живут на отдельных аудиошинах, поэтому их можно глушить
## независимо. Состояние кнопок сохраняется вместе с прогрессом в GameState.
## Платформенное событие audio_state_changed (Яндекс/Playgama) является
## внешним запретом: пока платформа просит тишину, обе шины остаются mute.

signal changed

const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

var _music_muted: bool = false
var _sfx_muted: bool = false
var _platform_audio_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)

	if GameState.is_loaded():
		_load_from_game_state()
	else:
		GameState.loaded.connect(_load_from_game_state, CONNECT_ONE_SHOT)


func is_music_muted() -> bool:
	return _music_muted or not _platform_audio_enabled


func is_sfx_muted() -> bool:
	return _sfx_muted or not _platform_audio_enabled


func set_music_muted(value: bool) -> void:
	if _music_muted == value:
		return
	_music_muted = value
	GameState.set_music_muted(value)
	_apply_buses()
	changed.emit()


func set_sfx_muted(value: bool) -> void:
	if _sfx_muted == value:
		return
	_sfx_muted = value
	GameState.set_sfx_muted(value)
	_apply_buses()
	changed.emit()


func toggle_music() -> void:
	set_music_muted(not is_music_muted())


func toggle_sfx() -> void:
	set_sfx_muted(not is_sfx_muted())


## Вызывается PlatformIntegration по событию платформы.
## Возврат true не включает звук принудительно: локальные настройки игрока
## остаются в силе, платформа лишь снимает свой внешний запрет.
func set_platform_audio_enabled(value: bool) -> void:
	if _platform_audio_enabled == value:
		return
	_platform_audio_enabled = value
	_apply_buses()
	changed.emit()


func _load_from_game_state() -> void:
	_music_muted = GameState.music_muted
	_sfx_muted = GameState.sfx_muted
	_apply_buses()
	changed.emit()


func _apply_buses() -> void:
	_set_bus_mute(MUSIC_BUS, is_music_muted())
	_set_bus_mute(SFX_BUS, is_sfx_muted())


func _set_bus_mute(bus_name: StringName, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, muted)


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")
