extends Resource
class_name SpawnEntry

## Сопоставление объекта спавна и его веса внутри локации.
##
## spawn — один из:
##   * AsteroidType — обычный астероид;
##   * EnemyType — враг;
##   * PackedScene — структура спавна (сцена с SpawnStructure в корне),
##     например «враг, прячущийся за цепочкой астероидов».
## В дальнейшем список типов spawn расширяется новыми сущностями.

@export var spawn: Resource

@export_range(0.0, 10.0, 0.01) var weight: float = 1.0
## Независимый шанс (0..1), проверяется до взвешенного выбора.
## Удобно для редких типов (например, ледяного астероида).
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.0
## Множители веса по тирам сложности (индексы 0..3). Если пусто —
## используется обычный weight. Позволяет убрать хардкод тиров из спавнера.
@export var tier_weights: PackedFloat32Array = PackedFloat32Array()