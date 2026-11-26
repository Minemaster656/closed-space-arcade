extends Node
class_name AudioManager

## Сценический аудиоменеджер: пул переиспользуемых плееров, без создания
## AudioStreamPlayer на каждый выстрел/попадание. Звуки берутся из AudioLibrary
## по ключу; в библиотеке лежат AudioStreamRandomizer'ы для вариаций.

static var instance: AudioManager

@export var library: AudioLibrary
@export var pool_2d_size: int = 16
@export var pool_ui_size: int = 4
@export var max_2d_distance: float = 2600.0

var _players_2d: Array[AudioStreamPlayer2D] = []
var _players_ui: Array[AudioStreamPlayer] = []
var _next_2d: int = 0
var _next_ui: int = 0


func _ready() -> void:
    instance = self
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_pools()


func _exit_tree() -> void:
    if instance == self:
        instance = null


func _build_pools() -> void:
    for i in pool_2d_size:
        var player := AudioStreamPlayer2D.new()
        player.bus = AudioSettings.SFX_BUS
        player.max_distance = max_2d_distance
        player.attenuation = 1.0
        add_child(player)
        _players_2d.append(player)

    for i in pool_ui_size:
        var player := AudioStreamPlayer.new()
        player.bus = AudioSettings.SFX_BUS
        add_child(player)
        _players_ui.append(player)


## Проигрывает звук по ключу в мировых координатах.
static func play_2d(
    key: StringName,
    position: Vector2,
    volume_db: float = 0.0,
    pitch: float = 1.0
) -> void:
    if instance == null:
        return
    instance._play_2d(key, position, volume_db, pitch)


## Проигрывает готовый поток (например, кастомный AudioStream из инспектора).
static func play_2d_stream(
    stream: AudioStream,
    position: Vector2,
    volume_db: float = 0.0,
    pitch: float = 1.0
) -> void:
    if instance == null:
        return
    instance._play_2d_stream(stream, position, volume_db, pitch)


## UI-звук без позиционирования. Работает и на паузе.
static func play_ui(key: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    if instance == null:
        return
    instance._play_ui(key, volume_db, pitch)


static func play_ui_stream(
    stream: AudioStream,
    volume_db: float = 0.0,
    pitch: float = 1.0
) -> void:
    if instance == null:
        return
    instance._play_ui_stream(stream, volume_db, pitch)


func _play_2d(key: StringName, position: Vector2, volume_db: float, pitch: float) -> void:
    if library == null:
        return
    _play_2d_stream(library.get_stream(key), position, volume_db, pitch)


func _play_2d_stream(
    stream: AudioStream,
    position: Vector2,
    volume_db: float,
    pitch: float
) -> void:
    if stream == null:
        return
    var player := _get_player_2d()
    if player == null:
        return
    player.stop()
    player.stream = stream
    player.global_position = position
    player.volume_db = volume_db
    player.pitch_scale = pitch
    player.play()


func _play_ui(key: StringName, volume_db: float, pitch: float) -> void:
    if library == null:
        return
    _play_ui_stream(library.get_stream(key), volume_db, pitch)


func _play_ui_stream(stream: AudioStream, volume_db: float, pitch: float) -> void:
    if stream == null:
        return
    var player := _get_player_ui()
    if player == null:
        return
    player.stop()
    player.stream = stream
    player.volume_db = volume_db
    player.pitch_scale = pitch
    player.play()


func _get_player_2d() -> AudioStreamPlayer2D:
    if _players_2d.is_empty():
        return null
    for i in _players_2d.size():
        var index := (_next_2d + i) % _players_2d.size()
        if not _players_2d[index].playing:
            _next_2d = (index + 1) % _players_2d.size()
            return _players_2d[index]
    var player := _players_2d[_next_2d]
    _next_2d = (_next_2d + 1) % _players_2d.size()
    return player


func _get_player_ui() -> AudioStreamPlayer:
    if _players_ui.is_empty():
        return null
    for i in _players_ui.size():
        var index := (_next_ui + i) % _players_ui.size()
        if not _players_ui[index].playing:
            _next_ui = (index + 1) % _players_ui.size()
            return _players_ui[index]
    var player := _players_ui[_next_ui]
    _next_ui = (_next_ui + 1) % _players_ui.size()
    return player
