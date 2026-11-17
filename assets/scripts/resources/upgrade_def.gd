extends Resource
class_name UpgradeDef

## Описание одного мета-апгрейда: иконка, тексты, лимит уровней и формула цены.

@export_group("Identity")
@export var id: StringName = &"upgrade"
@export var title_key: String = ""
@export_multiline var description_key: String = ""
@export var icon: Texture2D

@export_group("Levels")
## 0 — уровень не ограничен.
@export var max_level: int = 0

@export_group("Price")
## price(level) = ceil(a * level^p + b * level + c)
## level — количество уже купленных уровней.
@export var price_a: float = 0.0
@export var price_p: float = 1.0
@export var price_b: float = 0.0
@export var price_c: float = 10.0


func price_for_level(level: int) -> int:
	var l := maxi(level, 0)
	var price := price_a * pow(float(l), price_p) + price_b * float(l) + price_c
	return int(ceil(price))


func is_maxed(level: int) -> bool:
	return max_level > 0 and level >= max_level
