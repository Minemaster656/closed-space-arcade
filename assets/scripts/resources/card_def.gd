extends Resource
class_name CardDef

## Описание карточки забега. Карточка ничего не знает о конкретных механиках:
## она лишь хранит модификаторы характеристик и сцены поведений.
##
## Чтобы добавить новую механику, достаточно:
## 1. создать CardDef-ресурс;
## 2. при необходимости добавить StatModifier;
## 3. при необходимости указать сцену с CardBehavior.
## Никаких новых if-ов в ракете/игре для этого не нужно.

@export_group("Identity")
@export var id: StringName = &"card"
@export var title_key: String = ""
@export_multiline var description_key: String = ""
@export var icon: Texture2D

@export_group("Offers")
@export var rarity: StringName = &"common"
@export var weight: float = 1.0
## Во сколько раз падает вес карточки за каждый уже взятый стак.
@export_range(0.05, 1.0, 0.05) var repeat_falloff: float = 0.65
## 0 — количество не ограничено.
@export var max_stacks: int = 0
@export var tags: Array[StringName] = []

@export_group("Unlock")
## false — карточка попадает в пул только после разблокировки в мета-магазине.
@export var unlocked_by_default: bool = true

@export_group("Effects")
@export var modifiers: Array[StatModifier] = []
@export var behaviors: Array[PackedScene] = []
