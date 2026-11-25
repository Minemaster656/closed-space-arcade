extends Node
class_name BuffHandler

## Базовый обработчик баффа. Один BuffDef может содержать несколько сцен.
## Наследники переопределяют _on_* хуки, а не public-методы.

var buff: BuffInstance
var context: RunContext


func setup(instance: BuffInstance, run_context: RunContext) -> void:
	buff = instance
	context = run_context


func start() -> void:
	_on_start()


func tick(delta: float) -> void:
	_on_tick(delta)


func refresh() -> void:
	_on_refresh()


func stacks_changed() -> void:
	_on_stacks_changed()


func end() -> void:
	_on_end()


func get_rocket() -> Rocket:
	return context.rocket if context != null else null


func _on_start() -> void:
	pass


func _on_tick(_delta: float) -> void:
	pass


func _on_refresh() -> void:
	pass


func _on_stacks_changed() -> void:
	pass


func _on_end() -> void:
	pass
