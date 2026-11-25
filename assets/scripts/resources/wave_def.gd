extends Resource
class_name WaveDef

## Волна локации. Длится length_meters метров дистанции.
##
## start_pool — спавнится один раз в начале волны.
## end_pool   — спавнится один раз в конце волны (например, гарантированная комета).
## entries    — постоянные веса спавна, работающие всю волну (как раньше локация).

@export_group("Length")
@export var length_meters: float = 50.0

@export_group("Pools")
@export var start_pool: SpawnPool
@export var end_pool: SpawnPool

@export_group("Ongoing")
## Постоянный взвешенный спавн на протяжении волны.
@export var entries: Array[SpawnEntry] = []