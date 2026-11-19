extends Node
class_name CometSpawner

## Спавнит комету каждые N метров. Держит только одну активную комету:
## если игрок её не собрал, следующая не появляется, пока экран не освободится.

signal comet_spawned(comet: Comet)
signal comet_collected(comet: Comet)

@export var comet_scene: PackedScene
@export var interval_meters: float = 50.0
@export var enabled: bool = false

var run_context: RunContext
var distance: float = 0.0

var _active: Comet
var _next_threshold: float = 50.0


func _ready() -> void:
	_next_threshold = interval_meters


func _process(_delta: float) -> void:
	if not enabled or _active != null or comet_scene == null:
		return
	if distance < _next_threshold:
		return
	_spawn_comet()


func stop() -> void:
	enabled = false


func reset_distance(value: float = 0.0) -> void:
	distance = value
	_next_threshold = (floorf(value / interval_meters) + 1.0) * interval_meters


func _spawn_comet() -> void:
	var comet := comet_scene.instantiate() as Comet
	if comet == null:
		return

	_active = comet
	add_child(comet)
	comet.collected.connect(_on_comet_collected)
	comet.tree_exited.connect(_on_comet_tree_exited)
	comet_spawned.emit(comet)

	if run_context != null and not run_context.hint_shown:
		run_context.hint_shown = true
		comet.show_hint()

	_next_threshold = (floorf(distance / interval_meters) + 1.0) * interval_meters


func _on_comet_collected(comet: Comet) -> void:
	if comet == _active:
		_active = null
		_next_threshold = (floorf(distance / interval_meters) + 1.0) * interval_meters
	comet_collected.emit(comet)


func _on_comet_tree_exited() -> void:
	# Если комету убрали не через collect(), всё равно разрешаем следующую.
	_active = null
