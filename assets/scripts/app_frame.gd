extends Control

## Корневая оболочка игры.
##
## Держит игровые сцены в SubViewport дизайн-размера 720x1280 и масштабирует
## его с сохранением вертикального соотношения сторон. Свободное место окна
## заполняется размытым зумом того же кадра, поэтому игра никогда не
## растягивается под ширину браузера/экрана.

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const DESIGN_ASPECT := 720.0 / 1280.0
const GAME_SCENE := "res://assets/scenes/game.tscn"
const GAME_VIEWPORT_GROUP := &"game_viewport"
const GAME_ROOT_GROUP := &"game_root"

@onready var _backdrop: TextureRect = $Backdrop
@onready var _game_container: SubViewportContainer = $GameContainer
@onready var _game_viewport: SubViewport = $GameContainer/GameViewport
@onready var _blur_viewport: SubViewport = $BlurViewport
@onready var _blur_rect: TextureRect = $BlurViewport/BlurRect


func _ready() -> void:
	add_to_group(&"app_frame")
	_game_viewport.add_to_group(GAME_VIEWPORT_GROUP)
	# 2D-раскладка остаётся в дизайн-размере 720x1280, а рендер идёт в
	# физическом разрешении окна. Без этого игра рисовалась в 720x1280 и
	# растягивалась, из-за чего текст и иконки становились мыльными.
	_game_viewport.size_2d_override = Vector2i(DESIGN_SIZE)
	_game_viewport.size_2d_override_stretch = true
	# SubViewport не наследует project setting фильтрации текстур: по
	# умолчанию у него LINEAR, из-за чего все текстуры внутри игры мылятся.
	# Ставим тот же режим, что и в настройках проекта (Nearest Mipmap).
	_game_viewport.canvas_item_default_texture_filter = \
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	_force_portrait_on_mobile()
	_bind_viewport_textures()
	get_viewport().size_changed.connect(_layout)
	change_scene(GAME_SCENE)
	_layout()


## Заменяет текущую игровую сцену. Вызывается из Transition вместо
## SceneTree.change_scene_to_file(), чтобы не убить оболочку.
func change_scene(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("AppFrame: не удалось загрузить сцену %s" % path)
		return

	for child in _game_viewport.get_children():
		child.remove_from_group(GAME_ROOT_GROUP)
		_game_viewport.remove_child(child)
		child.queue_free()

	var instance := packed.instantiate()
	instance.add_to_group(GAME_ROOT_GROUP)
	_game_viewport.add_child(instance)


func _bind_viewport_textures() -> void:
	# Источник размытия — живой кадр игры.
	_blur_rect.texture = _game_viewport.get_texture()
	# Фон окна — уже размытый и уменьшенный кадр.
	_backdrop.texture = _blur_viewport.get_texture()


func _layout() -> void:
	var window := get_viewport_rect().size
	if window.x <= 0.0 or window.y <= 0.0:
		return

	var scale_factor := minf(window.x / DESIGN_SIZE.x, window.y / DESIGN_SIZE.y)
	var target_size := (DESIGN_SIZE * scale_factor).round()
	target_size.x = maxf(target_size.x, 2.0)
	target_size.y = maxf(target_size.y, 2.0)

	# Контейнер занимает физический размер игрового прямоугольника. Сам
	# SubViewport растягивает 2D-контент из 720x1280 в этот размер, поэтому
	# рендер идёт в нативном разрешении, а не апскейлится из 720x1280.
	_game_container.scale = Vector2.ONE
	_game_container.size = target_size
	_game_container.position = ((window - target_size) * 0.5).round()

	var bg_material := _backdrop.material as ShaderMaterial
	if bg_material != null:
		bg_material.set_shader_parameter(&"window_size", window)
		bg_material.set_shader_parameter(&"game_aspect", DESIGN_ASPECT)


func _force_portrait_on_mobile() -> void:
	# На нативном мобильном проектная настройка уже портретная, но фиксируем
	# ориентацию ещё и в рантайме. На вебе этим занимается JS в HTML-оболочке.
	if OS.has_feature(&"mobile") and not OS.has_feature(&"web"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
