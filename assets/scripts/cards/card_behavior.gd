extends Node
class_name CardBehavior

## Базовый класс для исполняемой части карточки.
##
## Поведение — обычная сцена/нода. Она живёт столько же, сколько забег,
## получает RunContext и сама подписывается на нужные сигналы.
## Именно сюда добавляются лазеры, мультивыстрелы, щиты, дроны и т.п.

var context: Node


func equip(ctx: Node) -> void:
	context = ctx
	_on_equip()


## Переопределяется наследниками.
func _on_equip() -> void:
	pass
