extends Node2D
class_name SpawnStructure

## Корень сцены-структуры спавна. По вызову spawn(origin) спавнит все дочерние
## SpawnNode относительно точки origin (их локальные позиции задаются в сцене)
## и удаляется — дальше жизнью заспавненных объектов управляют пулы.
##
## Пример: «враг, прячущийся за цепочкой из двух больших астероидов» — три
## SpawnNode с appropriate смещениями по Y.

func spawn(origin: Vector2) -> void:
	global_position = origin
	for child in get_children():
		if child is SpawnNode:
			(child as SpawnNode).spawn()
	queue_free()