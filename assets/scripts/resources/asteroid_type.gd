extends Resource
class_name AsteroidType

@export_group("Identity")
@export var id: StringName = &"rock"
@export var display_name: String = "Rock"
## Необязательная сцена. Если не задана — пул использует сцену по умолчанию.
@export var scene: PackedScene

@export_group("Spawn")
@export_range(0.0, 10.0, 0.01) var weight: float = 1.0
@export var min_speed: float = 50.0
@export var max_speed: float = 120.0

@export_group("Combat")
@export var max_hp: float = 3.0
@export var damage: float = 1.0
@export var damageable: bool = true
@export var harmful: bool = true

@export_group("Visuals")
## Набор текстур типа. Вариант выбирается случайно при спавне.
@export var textures: Array[Texture2D] = []
@export var scale_multiplier: float = 1.0
@export var collision_radius: float = 22.0
@export var tint: Color = Color.WHITE

@export_group("Split")
@export var child_type: AsteroidType
@export_range(0, 8) var child_min: int = 0
@export_range(0, 8) var child_max: int = 0

@export_group("Metal")
@export var collectible: bool = false
@export var metal_value: int = 1

@export_group("Experience")
## Сколько XP получает игрок за уничтожение этого типа.
@export var xp_value: int = 1
