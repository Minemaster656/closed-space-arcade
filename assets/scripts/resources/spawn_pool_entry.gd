extends Resource
class_name SpawnPoolEntry

## Независимое вхождение пула спавна.
##
## chance — шанс в процентах (1.0 = 100%). Поддерживает значения больше 1:
## целая часть даёт гарантированное число спавнов, дробная — вероятность
## ещё одного. Например 4.23 => 4 гарантированных + 23% на пятый.
##
## group — обычная взвешенная группа: каждый спавн выбирает definition
## (AsteroidType / EnemyType / CometType / PackedScene-структура) по весам.

@export_range(0.0, 100.0, 0.01) var chance: float = 0.0
@export var group: Array[SpawnVariant] = []