extends Resource
class_name SpawnEntry

## Сопоставление объекта спавна и его веса внутри волны (постоянный спавн).
##
## spawn — один из:
##   * AsteroidType — обычный астероид;
##   * EnemyType — враг;
##   * CometType — комета;
##   * PackedScene — структура спавна (сцена с SpawnStructure в корне).
## В дальнейшем список типов spawn расширяется новыми сущностями.

@export var spawn: Resource

@export_range(0.0, 10.0, 0.01) var weight: float = 1.0