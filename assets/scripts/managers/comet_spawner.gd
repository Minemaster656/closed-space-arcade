extends Node
class_name CometSpawner

## Управляет единственной активной кометой: спавнит её по запросу волны
## (финальный пул), держит только одну на экране, показывает подсказку у
## первой кометы забега и раздаёт сигналы.
##
## Спавн по фиксированной дистанции убран: кометы приходят из системы волн.

signal comet_spawned(comet: Comet)
signal comet_collected(comet: Comet)

@export var comet_scene: PackedScene
@export var enabled: bool = false

var run_context: RunContext

var _active: Comet


func stop() -> void:
	enabled = false


## Спавнит комету, если она включена и на экране нет активной.
## Возвращает заспавненную комету или null.
func spawn_comet() -> Comet:
	if not enabled or _active != null or comet_scene == null:
		return null

	var comet := comet_scene.instantiate() as Comet
	if comet == null:
		return null

	_active = comet
	add_child(comet)
	comet.collected.connect(_on_comet_collected)
	comet.tree_exited.connect(_on_comet_tree_exited)
	comet_spawned.emit(comet)

	if run_context != null and not run_context.hint_shown:
		run_context.hint_shown = true
		comet.show_hint()

	return comet


func _on_comet_collected(comet: Comet) -> void:
	if comet == _active:
		_active = null
	comet_collected.emit(comet)


func _on_comet_tree_exited() -> void:
	# Если комету убрали не через collect(), всё равно разрешаем следующую.
	_active = null