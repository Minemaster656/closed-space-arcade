extends RefCounted
class_name BuffInstance

## Один активный экземпляр баффа: таймер, стаки и привязанные обработчики.

var def: BuffDef
var remaining: float = 0.0
var stacks: int = 1
var source_event: Dictionary = {}
var handlers: Array[BuffHandler] = []
var context: RunContext

var _modifiers: Array[StatModifier] = []


func setup(run_context: RunContext, buff_def: BuffDef, event: Dictionary = {}) -> void:
	context = run_context
	def = buff_def
	remaining = buff_def.duration
	source_event = event


func begin(host: Node) -> void:
	_add_modifiers(stacks)
	_spawn_handlers(host)
	for handler in handlers:
		if is_instance_valid(handler):
			handler.start()
	context.apply_stats()


func tick(delta: float) -> void:
	for handler in handlers:
		if is_instance_valid(handler):
			handler.tick(delta)


func refresh() -> void:
	remaining = def.duration
	for handler in handlers:
		if is_instance_valid(handler):
			handler.refresh()


func add_stack() -> bool:
	if stacks >= maxi(1, def.max_stacks):
		return false
	stacks += 1
	_add_modifiers(1)
	context.apply_stats()
	for handler in handlers:
		if is_instance_valid(handler):
			handler.stacks_changed()
	return true


func end() -> void:
	for handler in handlers:
		if is_instance_valid(handler):
			handler.end()
			handler.queue_free()
	handlers.clear()
	_remove_modifiers()
	context.apply_stats()


func _add_modifiers(count: int) -> void:
	for modifier in def.modifiers:
		if modifier == null:
			continue
		for i in count:
			var copy: StatModifier = modifier.duplicate() as StatModifier
			if copy == null:
				continue
			_modifiers.append(copy)
			context.stats.add_modifier(copy)


func _remove_modifiers() -> void:
	for modifier in _modifiers:
		context.stats.remove_modifier(modifier)
	_modifiers.clear()


func _spawn_handlers(host: Node) -> void:
	for scene in def.handlers:
		if scene == null:
			continue
		var node := scene.instantiate()
		if node is BuffHandler:
			var handler := node as BuffHandler
			handler.setup(self, context)
			host.add_child(handler)
			handlers.append(handler)
		else:
			push_warning("BuffDef '%s': сцена обработчика не является BuffHandler" % def.id)
			node.free()
