extends Resource
class_name SpawnPool

## Пул спавна: набор независимых вхождений (SpawnPoolEntry). Каждое вхождение
## само решает, сколько объектов заспавнить (шанс в процентах, >1 = больше
## одного), и выбирает конкретный объект по весам внутри своей группы.
##
## Используется для стартового и финального пула волны. roll() возвращает
## список definition'ов, которые нужно заспавнить.

@export var entries: Array[SpawnPoolEntry] = []


## Прокатывает пул и возвращает список definition'ов к спавну.
func roll() -> Array[Resource]:
	var result: Array[Resource] = []
	for entry in entries:
		if entry == null or entry.group.is_empty():
			continue
		var count := _roll_count(entry.chance)
		for i in count:
			var definition := _pick_weighted(entry.group)
			if definition != null:
				result.append(definition)
	return result


## Целая часть — гарантированно, дробная — с вероятностью.
func _roll_count(chance: float) -> int:
	if chance <= 0.0:
		return 0
	var count := int(floor(chance))
	if randf() < chance - count:
		count += 1
	return count


func _pick_weighted(group: Array[SpawnVariant]) -> Resource:
	var total := 0.0
	for variant in group:
		if variant != null and variant.definition != null:
			total += maxf(0.0, variant.weight)
	if total <= 0.0:
		return null

	var roll := randf() * total
	for variant in group:
		if variant == null or variant.definition == null:
			continue
		roll -= maxf(0.0, variant.weight)
		if roll <= 0.0:
			return variant.definition
	return null