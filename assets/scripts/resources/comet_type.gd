extends Resource
class_name CometType

## Тип объекта спавна «комета». Отдельный тип нужен, чтобы спавнер волн
## отличал комету от обычных PackedScene-структур и маршрутизировал её
## через CometSpawner (сигналы, подсказка, единственная активная комета).

@export_group("Identity")
@export var id: StringName = &"comet"
@export var display_name: String = "Comet"

@export_group("Scene")
## Сцена кометы. Если не задана — CometSpawner использует свою comet_scene.
@export var scene: PackedScene