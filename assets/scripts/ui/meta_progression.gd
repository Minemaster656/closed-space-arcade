extends Control

## Экран метапрогрессии: главная страница и магазин апгрейдов.
## Страницы перелистываются твином по вертикали, поэтому экран
## остаётся адаптивным при любом разрешении/аспекте.

const GAME_SCENE: String = "res://assets/scenes/game.tscn"
const PAGE_DURATION: float = 0.45

## Префаб одной строки магазина. Можно заменить прямо в инспекторе.
@export var upgrade_row_scene: PackedScene = preload("res://assets/prefabs/upgrade_row.tscn")
const ROW_STAGGER: float = 0.05
const ROW_TWEEN_DURATION: float = 0.32

const BAR_READY_COLOR: Color = Color(0.08, 0.22, 0.13, 0.95)
const BAR_READY_BORDER: Color = Color(0.3, 0.78, 0.45, 1.0)
const BAR_BROKE_COLOR: Color = Color(0.26, 0.08, 0.1, 0.95)
const BAR_BROKE_BORDER: Color = Color(0.92, 0.3, 0.34, 1.0)
const BAR_MAXED_COLOR: Color = Color(0.11, 0.12, 0.16, 0.9)
const BAR_MAXED_BORDER: Color = Color(0.3, 0.32, 0.38, 1.0)

const FLYING_POINT_SCRIPT: Script = preload("res://assets/scripts/ui/flying_point.gd")
const FLIGHT_DURATION: float = 0.52

@onready var _pages: Control = $Pages
@onready var _main_page: Control = $Pages/MainPage
@onready var _shop_page: Control = $Pages/ShopPage
@onready var _main_content: VBoxContainer = $Pages/MainPage/Center/VBox
@onready var _title: Label = $Pages/MainPage/Center/VBox/Title
@onready var _record: Label = $Pages/MainPage/Center/VBox/Record
@onready var _shop_button: Button = $Pages/MainPage/Center/VBox/ShopButton
@onready var _play_button: Button = $Pages/MainPage/Center/VBox/PlayButton
@onready var _reset_button: Button = $Pages/MainPage/Center/VBox/ResetButton
@onready var _reset_confirm: ConfirmationDialog = $ResetConfirm
@onready var _back_button: Button = $Pages/ShopPage/Margin/VBox/TopBar/BackButton
@onready var _shop_title: Label = $Pages/ShopPage/Margin/VBox/TopBar/Title
@onready var _purchase_bar: PanelContainer = $Pages/ShopPage/Margin/VBox/PurchaseBar
@onready var _next_point_label: Label = $Pages/ShopPage/Margin/VBox/PurchaseBar/Margin/HBox/NextPoint
@onready var _buy_button: JuicyButton = $Pages/ShopPage/Margin/VBox/PurchaseBar/Margin/HBox/BuyPointButton
@onready var _free_points_label: Label = $Pages/ShopPage/Margin/VBox/FreePoints/Label
@onready var _free_points_dot: Control = $Pages/ShopPage/Margin/VBox/FreePoints/Dot
@onready var _rows: VBoxContainer = $Pages/ShopPage/Margin/VBox/Scroll/Rows
@onready var _fx_layer: Control = $FxLayer

var _page_tween: Tween
var _row_tweens: Array[Tween] = []
var _bar_tween: Tween
var _bar_style: StyleBoxFlat
var _bar_state: int = -1
var _buy_icon: Texture2D
var _on_shop: bool = false
var _page_height: float = 0.0


func _ready() -> void:
    Music.play("progression")
    _title.text = tr("meta_title")
    _shop_title.text = tr("meta_shop_title")
    _shop_button.text = tr("meta_shop_button")
    _play_button.text = tr("meta_play")
    _reset_button.text = tr("meta_reset")
    _back_button.text = tr("meta_back")
    _reset_confirm.title = tr("meta_reset_title")
    _reset_confirm.dialog_text = tr("meta_reset_confirm")
    _reset_confirm.ok_button_text = tr("meta_reset_ok")
    _reset_confirm.cancel_button_text = tr("meta_reset_cancel")
    _update_record()

    # Стиль плашки копируем, чтобы плавно менять цвет именно у этого экземпляра.
    _bar_style = _purchase_bar.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
    if _bar_style != null:
        _purchase_bar.add_theme_stylebox_override("panel", _bar_style)
    _buy_icon = _buy_button.icon

    _play_button.pressed.connect(_on_play_pressed)
    _shop_button.pressed.connect(_open_shop)
    _reset_button.pressed.connect(_on_reset_pressed)
    _reset_confirm.confirmed.connect(_on_reset_confirmed)
    _back_button.pressed.connect(_close_shop)
    _buy_button.pressed.connect(_on_buy_point_pressed)
    GameState.upgrades_changed.connect(_refresh_rows)
    GameState.upgrades_changed.connect(_refresh_purchase_bar)
    GameState.metal_changed.connect(_on_metal_changed)
    GameState.free_points_changed.connect(_on_free_points_changed)
    GameState.upgrade_point_allocated.connect(_on_point_allocated)
    GameState.upgrade_point_deallocated.connect(_on_point_deallocated)
    GameState.record_distance_changed.connect(_on_record_distance_changed)
    get_viewport().size_changed.connect(_on_viewport_resized)

    _build_rows()
    _refresh_purchase_bar(false)
    _refresh_free_points(false)
    _layout_pages()
    _play_entrance()


func _build_rows() -> void:
    if upgrade_row_scene == null:
        return
    for id in GameState.UPGRADE_ORDER:
        var def := GameState.get_upgrade_def(id)
        if def == null:
            continue
        var row := upgrade_row_scene.instantiate() as UpgradeRow
        _rows.add_child(row)
        row.allocate_requested.connect(_on_row_allocate_requested)
        row.deallocate_requested.connect(_on_row_deallocate_requested)
        row.setup(def)


func _on_row_allocate_requested(id: StringName) -> void:
    var row := _find_row(id)
    var success := GameState.allocate_upgrade_point(id)
    if row != null:
        row.notify_allocation_result(success, true)


func _on_row_deallocate_requested(id: StringName) -> void:
    var row := _find_row(id)
    var success := GameState.deallocate_upgrade_point(id)
    if row != null:
        row.notify_allocation_result(success, false)


func _find_row(id: StringName) -> UpgradeRow:
    for child in _rows.get_children():
        var row := child as UpgradeRow
        if row != null and row.get_upgrade_id() == id:
            return row
    return null


func _refresh_rows() -> void:
    for child in _rows.get_children():
        var row := child as UpgradeRow
        if row != null:
            row.refresh()


func _refresh_purchase_bar(animate: bool = true) -> void:
    var capacity := GameState.has_upgrade_capacity()
    var price := GameState.get_next_point_price()
    var state := 2

    if capacity:
        var affordable := GameState.metal >= price
        state = 0 if affordable else 1
        _next_point_label.text = tr("meta_next_point")
        _buy_button.text = str(price)
        _buy_button.icon = _buy_icon
        _buy_button.disabled = false
        _set_bar_colors(
            BAR_READY_COLOR if affordable else BAR_BROKE_COLOR,
            BAR_READY_BORDER if affordable else BAR_BROKE_BORDER,
            animate
        )
    else:
        _next_point_label.text = tr("meta_all_maxed")
        _buy_button.text = tr("upgrade_max")
        _buy_button.icon = null
        _buy_button.disabled = true
        _set_bar_colors(BAR_MAXED_COLOR, BAR_MAXED_BORDER, animate)

    if animate and state != _bar_state and state == 0:
        _punch_control(_purchase_bar, 1.02)
    _bar_state = state


func _set_bar_colors(bg: Color, border: Color, animate: bool) -> void:
    if _bar_style == null:
        return
    if _bar_tween != null and _bar_tween.is_valid():
        _bar_tween.kill()
    if not animate:
        _bar_style.bg_color = bg
        _bar_style.border_color = border
        return
    _bar_tween = create_tween().set_parallel(true)
    _bar_tween.tween_property(_bar_style, "bg_color", bg, 0.28)
    _bar_tween.tween_property(_bar_style, "border_color", border, 0.28)


func _on_buy_point_pressed() -> void:
    if not GameState.has_upgrade_capacity():
        _buy_button.shake()
        return

    if GameState.buy_upgrade_point():
        _buy_button.punch(1.14)
        _punch_control(_purchase_bar, 1.015)
        var from := _buy_button.get_global_rect().get_center()
        _spawn_flying_point(from, _free_points_anchor(), _punch_free_points)
    else:
        _buy_button.shake()
        _shake_control(_purchase_bar)


func _on_metal_changed(_total: int) -> void:
    _refresh_purchase_bar()


func _on_free_points_changed(_value: int) -> void:
    _refresh_free_points()


func _refresh_free_points(animate: bool = true) -> void:
    var value := GameState.upgrade_points
    _free_points_label.text = tr("meta_free_points") % value
    _free_points_label.modulate = Color(1.0, 0.9, 0.55, 1.0) if value > 0 else Color(0.7, 0.72, 0.8, 1.0)
    _free_points_dot.modulate = Color.WHITE if value > 0 else Color(1.0, 1.0, 1.0, 0.35)
    if animate:
        _punch_free_points()


func _punch_free_points() -> void:
    _punch_control(_free_points_label, 1.22)
    _punch_control(_free_points_dot, 1.35)


func _punch_control(control: Control, target_scale: float, duration: float = 0.3) -> void:
    if control == null:
        return
    control.pivot_offset = control.size * 0.5
    control.scale = Vector2.ONE * target_scale
    var tween := create_tween()
    tween.tween_property(control, "scale", Vector2.ONE, duration) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake_control(control: Control) -> void:
    if control == null:
        return
    control.pivot_offset = control.size * 0.5
    var strength := deg_to_rad(1.1)
    control.rotation = -strength
    var tween := create_tween()
    tween.tween_property(control, "rotation", strength, 0.05)
    tween.tween_property(control, "rotation", -strength * 0.6, 0.08)
    tween.tween_property(control, "rotation", 0.0, 0.06)


func _on_point_allocated(id: StringName) -> void:
    var row := _find_row(id)
    if row == null:
        return
    var from := _free_points_anchor()
    var to := row.get_action_anchor(true)
    _spawn_flying_point(from, to, func() -> void:
        row.bump_level()
        _punch_free_points()
    )


func _on_point_deallocated(id: StringName) -> void:
    var row := _find_row(id)
    if row == null:
        return
    var from := row.get_action_anchor(false)
    _spawn_flying_point(from, _free_points_anchor(), _punch_free_points)


func _free_points_anchor() -> Vector2:
    return _free_points_dot.get_global_rect().get_center()


func _spawn_flying_point(from: Vector2, to: Vector2, on_arrived: Callable = Callable()) -> void:
    var orb := FLYING_POINT_SCRIPT.new() as FlyingPoint
    if orb == null:
        return
    _fx_layer.add_child(orb)
    if on_arrived.is_valid():
        orb.arrived.connect(on_arrived)
    orb.play(from, to, FLIGHT_DURATION)


func _kill_flying_points() -> void:
    for child in _fx_layer.get_children():
        if child is FlyingPoint:
            child.queue_free()


func _on_record_distance_changed(_value: float) -> void:
    _update_record()


func _on_reset_pressed() -> void:
    _reset_confirm.popup_centered()


func _on_reset_confirmed() -> void:
    GameState.reset_save()
    _update_record()


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
    _kill_flying_points()
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
    _kill_flying_points()
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
