extends Resource
class_name LocationDef

## Локация — набор волн. Игра не знает о конкретных астероидах/врагах:
## она лишь прокатывает пулы активной волны и спавнит выбранные definition
## через SpawnUtil (или CometSpawner для комет).
##
## Волны идут по дистанции: каждые length_meters волна инкрементится, пока
## не дойдёт до последней. У каждой волны есть стартовый и финальный пул,
## а также постоянные веса спавна на всё время волны.

@export_group("Identity")
@export var id: StringName = &"location"
@export var display_name: String = "Location"

@export_group("Waves")
@export var waves: Array[WaveDef] = []