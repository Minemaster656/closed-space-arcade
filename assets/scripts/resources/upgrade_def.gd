extends Resource
class_name UpgradeDef

## Описание одного мета-апгрейда: иконка, тексты и лимит уровней.
## Цена очков общая для всего магазина и живёт в GameState.

@export_group("Identity")
@export var id: StringName = &"upgrade"
@export var title_key: String = ""
@export_multiline var description_key: String = ""
@export var icon: Texture2D

@export_group("Levels")
## 0 — уровень не ограничен.
@export var max_level: int = 0

@export_group("Unlock")
## Если задано, первое вложение очка разблокирует эту карточку в обычном пуле забега.
@export var unlock_card: CardDef


func is_maxed(level: int) -> bool:
	return max_level > 0 and level >= max_level
