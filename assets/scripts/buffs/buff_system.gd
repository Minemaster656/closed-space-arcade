extends Node
class_name BuffSystem

## Хранит активные баффы, тикает их таймеры и управляет наложением/снятием.

signal buff_started(instance: BuffInstance)
signal buff_refreshed(instance: BuffInstance)
signal buff_ended(instance: BuffInstance)

var context: RunContext

var _active: Dictionary = {}
var _order: Array[BuffInstance] = []


func setup(run_context: RunContext) -> void:
	context = run_context
	if not GameState.buff_requested.is_connected(_on_buff_requested):
		GameState.buff_requested.connect(_on_buff_requested)


func _process(delta: float) -> void:
	if _order.is_empty():
		return

	for instance in _order.duplicate():
		if instance == null or instance.def == null:
			continue
		if instance.def.duration > 0.0:
			instance.remaining -= delta
		instance.tick(delta)
		if instance.def.duration > 0.0 and instance.remaining <= 0.0:
			_end(instance)


## Накладывает бафф. Повторный вызов обновляет/стакает существующий.
func apply(def: BuffDef, event: Dictionary = {}) -> BuffInstance:
	if def == null or def.id == &"":
		return null

	var instance: BuffInstance = _active.get(def.id)
	if instance != null:
		if def.reapply_mode == "stack":
			instance.add_stack()
		instance.source_event = event
		instance.refresh()
		buff_refreshed.emit(instance)
		return instance

	instance = BuffInstance.new()
	instance.setup(context, def, event)
	_active[def.id] = instance
	_order.append(instance)
	instance.begin(self)
	buff_started.emit(instance)
	return instance


func remove(id: StringName) -> void:
	var instance: BuffInstance = _active.get(id)
	if instance != null:
		_end(instance)


func clear() -> void:
	for instance in _order.duplicate():
		_end(instance)


func has(id: StringName) -> bool:
	return _active.has(id)


func get_remaining(id: StringName) -> float:
	var instance: BuffInstance = _active.get(id)
	return instance.remaining if instance != null else 0.0


func get_active() -> Array[BuffInstance]:
	return _order.duplicate()


func _end(instance: BuffInstance) -> void:
	if instance == null or instance.def == null:
		return
	if not _active.has(instance.def.id):
		return
	_active.erase(instance.def.id)
	_order.erase(instance)
	instance.end()
	buff_ended.emit(instance)


func _on_buff_requested(buff: BuffDef, event: Dictionary) -> void:
	apply(buff, event)
