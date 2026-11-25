extends JuicyButton
class_name CardView

## Одна карточка в предложении. Отображает данные CardDef и сообщает о выборе.
## Сама карточка не применяет эффект — это делает RunContext через RunFlow.

signal card_chosen(card: CardDef)

var card: CardDef

@onready var _icon: TextureRect = $Margin/VBox/Icon
@onready var _title: Label = $Margin/VBox/Title
@onready var _description: Label = $Margin/VBox/Description


func _ready() -> void:
	super._ready()
	pressed.connect(_on_pressed)


func setup(def: CardDef) -> void:
	card = def
	if def == null:
		return

	_title.text = tr(def.title_key) if not def.title_key.is_empty() else ""
	_description.text = tr(def.description_key) if not def.description_key.is_empty() else ""
	_icon.texture = def.icon
	_icon.visible = def.icon != null


func _on_pressed() -> void:
	if card != null:
		card_chosen.emit(card)
