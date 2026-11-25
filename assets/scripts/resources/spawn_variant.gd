extends Resource
class_name SpawnVariant

## Один из вариантов спавна с собственным весом. Используется внутри
## SpawnNode, когда структура спавна должна выбирать между несколькими
## definition (например, обычный/элитный враг) по весам.
##
## definition — AsteroidType или EnemyType (в дальнейшем — другие сущности).

@export var definition: Resource
@export_range(0.0, 10.0, 0.01) var weight: float = 1.0