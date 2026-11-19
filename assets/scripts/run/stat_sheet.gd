extends RefCounted
class_name StatSheet

## Считает итоговые характеристики забега из базовых значений и модификаторов.
## Модификаторы применяются в порядке добавления: add, mul, set.

var _base: Dictionary = {}
var _modifiers: Array[StatModifier] = []
var _values: Dictionary = {}


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	_values[stat] = value


func add_modifier(modifier: StatModifier) -> void:
	if modifier == null:
		return
	_modifiers.append(modifier)
	recalculate()


func clear_modifiers() -> void:
	_modifiers.clear()
	recalculate()


func recalculate() -> void:
	_values = _base.duplicate()
	for modifier in _modifiers:
		if modifier == null:
			continue
		var current := float(_values.get(modifier.stat, 0.0))
		match modifier.operation:
			"add":
				current += modifier.value
			"mul":
				current *= modifier.value
			"set":
				current = modifier.value
		_values[modifier.stat] = current


func get_value(stat: StringName, fallback: float = 0.0) -> float:
	return float(_values.get(stat, fallback))
