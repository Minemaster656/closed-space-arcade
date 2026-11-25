extends Resource
class_name BuffDef

## Описание временного баффа/дебаффа.
## Модификаторы влияют на StatSheet, а сцены-обработчики получают
## жизненный цикл start / tick / refresh / end для эффектов и шейдеров.

@export_group("Identity")
@export var id: StringName = &"buff"
@export var display_name: String = "Buff"
@export var icon: Texture2D
@export var is_debuff: bool = false
@export var accent_color: Color = Color(0.55, 0.85, 1.0)

@export_group("Duration")
## Длительность в секундах. 0 — бессрочный эффект.
@export var duration: float = 10.0
## refresh — повторный вызов сбрасывает таймер.
## stack — повторный вызов добавляет стак (до max_stacks) и сбрасывает таймер.
@export_enum("refresh", "stack") var reapply_mode: String = "refresh"
@export_range(1, 99) var max_stacks: int = 1

@export_group("Effects")
@export var modifiers: Array[StatModifier] = []
@export var handlers: Array[PackedScene] = []
