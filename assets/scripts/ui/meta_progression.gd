extends Control

## Экран метапрогрессии: главная страница и магазин апгрейдов.
## Страницы перелистываются твином по вертикали, поэтому экран
## остаётся адаптивным при любом разрешении/аспекте.

const GAME_SCENE: String = "res://assets/scenes/game.tscn"
const ROW_SCENE: PackedScene = preload("res://assets/prefabs/upgrade_row.tscn")
const PAGE_DURATION: float = 0.45
const ROW_STAGGER: float = 0.05
const ROW_TWEEN_DURATION: float = 0.32

@onready var _pages: Control = $Pages
@onready var _main_page: Control = $Pages/MainPage
@onready var _shop_page: Control = $Pages/ShopPage
@onready var _main_content: VBoxContainer = $Pages/MainPage/Center/VBox
@onready var _title: Label = $Pages/MainPage/Center/VBox/Title
@onready var _record: Label = $Pages/MainPage/Center/VBox/Record
@onready var _shop_button: Button = $Pages/MainPage/Center/VBox/ShopButton
@onready var _play_button: Button = $Pages/MainPage/Center/VBox/PlayButton
@onready var _back_button: Button = $Pages/ShopPage/Margin/VBox/TopBar/BackButton
@onready var _shop_title: Label = $Pages/ShopPage/Margin/VBox/TopBar/Title
@onready var _rows: VBoxContainer = $Pages/ShopPage/Margin/VBox/Scroll/Rows

var _page_tween: Tween
var _row_tweens: Array[Tween] = []
var _on_shop: bool = false
var _page_height: float = 0.0


func _ready() -> void:
	Music.play("progression")
	_title.text = tr("meta_title")
	_shop_title.text = tr("meta_shop_title")
	_shop_button.text = tr("meta_shop_button")
	_play_button.text = tr("meta_play")
	_back_button.text = tr("meta_back")
	_update_record()

	_play_button.pressed.connect(_on_play_pressed)
	_shop_button.pressed.connect(_open_shop)
	_back_button.pressed.connect(_close_shop)
	GameState.upgrades_changed.connect(_refresh_rows)
	GameState.metal_changed.connect(_on_metal_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)

	_build_rows()
	_layout_pages()
	_play_entrance()


func _build_rows() -> void:
	for id in GameState.UPGRADE_ORDER:
		var def := GameState.get_upgrade_def(id)
		if def == null:
			continue
		var row := ROW_SCENE.instantiate() as UpgradeRow
		_rows.add_child(row)
		row.setup(def)


func _refresh_rows() -> void:
	for child in _rows.get_children():
		var row := child as UpgradeRow
		if row != null:
			row.refresh()


func _on_metal_changed(_total: int) -> void:
	_refresh_rows()


func _update_record() -> void:
	_record.text = tr("meta_max_distance") % [int(GameState.record_distance), tr("ui_meter")]


func _open_shop() -> void:
	if _on_shop:
		return
	_layout_pages()
	_on_shop = true
	_animate_page(-_page_height, true)


func _close_shop() -> void:
	if not _on_shop:
		return
	_on_shop = false
	_animate_page(0.0, false)


func _animate_page(target_y: float, show_rows: bool) -> void:
	_kill_page_tween()
	if show_rows:
		_stagger_rows()

	_page_tween = create_tween()
	_page_tween.tween_property(_pages, "position:y", target_y, PAGE_DURATION) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)


func _stagger_rows() -> void:
	_kill_row_tweens()
	for i in _rows.get_child_count():
		var row := _rows.get_child(i) as Control
		if row == null:
			continue
		row.pivot_offset = row.size * 0.5
		row.modulate.a = 0.0
		row.scale = Vector2(0.92, 0.92)

		var tween := create_tween().set_parallel(true)
		tween.tween_property(row, "modulate:a", 1.0, 0.24).set_delay(i * ROW_STAGGER)
		tween.tween_property(row, "scale", Vector2.ONE, ROW_TWEEN_DURATION) \
			.set_delay(i * ROW_STAGGER) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_row_tweens.append(tween)


func _play_entrance() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_main_content.pivot_offset = _main_content.size * 0.5
	_main_content.modulate.a = 0.0
	_main_content.scale = Vector2(0.94, 0.94)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_main_content, "modulate:a", 1.0, 0.3)
	tween.tween_property(_main_content, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _layout_pages() -> void:
	var viewport_size := get_viewport_rect().size
	_page_height = viewport_size.y
	_main_page.position = Vector2.ZERO
	_shop_page.position = Vector2(0.0, _page_height)
	_pages.position = Vector2(0.0, -_page_height if _on_shop else 0.0)


func _on_viewport_resized() -> void:
	_kill_page_tween()
	_kill_row_tweens()
	_layout_pages()


func _kill_page_tween() -> void:
	if _page_tween != null and _page_tween.is_valid():
		_page_tween.kill()
	_page_tween = null


func _kill_row_tweens() -> void:
	for tween in _row_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_row_tweens.clear()

	for child in _rows.get_children():
		var row := child as Control
		if row != null:
			row.scale = Vector2.ONE
			row.modulate.a = 1.0


func _on_play_pressed() -> void:
	Transition.goto(GAME_SCENE, Transition.FADE_DURATION, Transition.FADE_DURATION, "fly")
