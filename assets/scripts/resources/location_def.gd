extends Resource
class_name LocationDef

## Локация — набор взвешенных объектов спавна. Игра не знает о конкретных
## астероидах/врагах: она лишь выбирает запись из активной локации по весам
## и просит SpawnUtil заспавнить её spawn-объект.

@export_group("Identity")
@export var id: StringName = &"location"
@export var display_name: String = "Location"

@export_group("Spawns")
@export var entries: Array[SpawnEntry] = []