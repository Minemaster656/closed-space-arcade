extends Resource
class_name EnemyType

## Описание типа врага. В отличие от старого хардкода, все характеристики
## хранятся в .tres-ресурсе, поэтому нового врага можно зарегистрировать,
## просто создав ещё один EnemyType и добавив его в локацию.
##
## Спавнится через SpawnUtil/EnemyPool: тип может либо указать собственную
## сцену, либо опираться на default_scene пула.

@export_group("Identity")
@export var id: StringName = &"enemy"
@export var display_name: String = "Enemy"
## Необязательная сцена. Если не задана — пул использует сцену по умолчанию.
@export var scene: PackedScene

@export_group("Movement")
## Базовая скорость сноса вниз. Умножается на speed_multiplier пула астероидов.
@export var base_drift: float = 90.0

@export_group("Combat")
@export var max_hp: float = 5.0
@export var shoot_interval: float = 2.0
@export var bullet_offset: float = 18.0

@export_group("Drop")
## Тип осколков, которые выпадают при смерти врага.
@export var shard_type: AsteroidType
@export_range(0, 4) var shard_min: int = 1
@export_range(0, 4) var shard_max: int = 2

@export_group("Experience")
## Сколько XP получает игрок за уничтожение этого типа.
@export var xp_value: int = 0