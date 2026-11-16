extends Control

## Экран метапрогрессии. Пока содержит только кнопку "поехали!".
## Возвращает в игру через fade-переход.

const GAME_SCENE: String = "res://assets/scenes/game.tscn"

@onready var _title: Label = $CenterContainer/VBox/Title
@onready var _play_button: Button = $CenterContainer/VBox/PlayButton


func _ready() -> void:
	_title.text = tr("meta_title")
	_play_button.text = tr("meta_play")
	_play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	Transition.goto(GAME_SCENE)