extends Node

## Persistent background music. Lives in autoload so playback survives scene changes.
## Two players are crossfaded: the outgoing track fades out while the incoming one fades in.

const FADE_DURATION: float = 0.5
const SILENT_DB: float = -80.0
const DEFAULT_VOLUME_DB: float = 0.0

const TRACKS: Dictionary = {
	"fly": "res://assets/music/fly.ogg",
	"progression": "res://assets/music/progression.ogg",
}

var _players: Array[AudioStreamPlayer] = []
var _active_index: int = 0
var _current_track: String = ""
var _tween: Tween
var _focus_suspended: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)


func _notification(what: int) -> void:
	# Музыка живёт в автолоаде с PROCESS_MODE_ALWAYS, поэтому пауза дерева
	# её не останавливает. Глушим плееры отдельно при потере фокуса.
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_set_focus_suspended(true)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_set_focus_suspended(false)


func _set_focus_suspended(suspended: bool) -> void:
	_focus_suspended = suspended
	for player in _players:
		player.stream_paused = suspended


func play(track: String, fade: float = FADE_DURATION) -> void:
	if not TRACKS.has(track):
		push_warning("Music: unknown track '%s'" % track)
		return

	var active_player := _players[_active_index]
	if track == _current_track and active_player.playing:
		return

	var stream: AudioStream = load(TRACKS[track])
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true

	var old_index := _active_index
	_active_index = 1 - _active_index
	var old_player := _players[old_index]
	var new_player := _players[_active_index]

	_kill_tween()

	new_player.stream = stream
	new_player.volume_db = SILENT_DB
	new_player.stream_paused = _focus_suspended
	new_player.play()
	_current_track = track

	if fade <= 0.0:
		old_player.stop()
		old_player.volume_db = SILENT_DB
		new_player.volume_db = DEFAULT_VOLUME_DB
		return

	_tween = create_tween()
	_tween.set_parallel(true)
	if old_player.playing:
		_tween.tween_property(old_player, "volume_db", SILENT_DB, fade) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(new_player, "volume_db", DEFAULT_VOLUME_DB, fade) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.chain().tween_callback(old_player.stop)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()