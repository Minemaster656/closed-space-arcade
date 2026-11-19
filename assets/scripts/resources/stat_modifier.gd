extends Resource
class_name StatModifier

## Одно изменение характеристики. Карточка может содержать несколько таких
## модификаторов; они применяются в порядке добавления карточек.

@export var stat: StringName = &"damage"
@export_enum("add", "mul", "set") var operation: String = "add"
@export var value: float = 0.0
