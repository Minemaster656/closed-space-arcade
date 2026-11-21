extends Node2D

const STARFIELD_MARGIN: float = 64.0
const STARFIELD_RESIZE_THRESHOLD: float = 48.0
const META_SCENE: String = "res://assets/scenes/meta_progression.tscn"

@export var shake_strength_min: float = 0.35
@export var shake_strength_max: float = 3.0
@export var asteroid_speed_multiplier_max: float = 2.4
@export var rocket_screen_margin: float = 40.0
@export var ambient_color: Color = Color(0.06, 0.05, 0.11, 1.0)
@export var card_pool: CardPool

@onready var rocket: Rocket = $Rocket
@onready var asteroid_pool: AsteroidPool = $Managers/AsteroidPool
@onready var asteroid_spawner: AsteroidSpawner = $Managers/AsteroidSpawner
@onready var comet_spawner: CometSpawner = $Managers/CometSpawner
@onready var starfield: GPUParticles2D = $Starfield
@onready var ambient: CanvasModulate = $CanvasModulate
@onready var score_label: Label = $UI/ScoreCounter
@onready var xp_bar: RunXpBar = $UI/XPBar
@onready var pause_button: Button = $UI/PauseButton
@onready var start_platform: ColorRect = $StartPlatform
@onready var reward_overlay: RewardOverlay = $RewardOverlay
@onready var pause_overlay: PauseOverlay = $PauseOverlay

var run_context: RunContext
var run_flow: RunFlow

var _starfield_applied_size: Vector2 = Vector2.ZERO
var _distance: float = 0.0
var _launch_tween: Tween
var _play_position: Vector2


func _ready() -> void:
    add_to_group(PauseManager.FOCUS_PAUSE_GROUP)
    PauseManager.reset()
    Music.play("fly")
    pause_button.tooltip_text = tr("ui_pause")
    pause_button.pressed.connect(_on_pause_pressed)
    pause_overlay.shop_requested.connect(_on_exit_to_shop_requested)
    var visible := Utils.get_visible_world_rect()
    var rect := visible.grow(-rocket_screen_margin)
    var follower := rocket.get_node_or_null("FingerFollower") as FollowFinger2D
    if follower != null:
        follower.area = rect
    _apply_starfield(visible)
    rocket.died.connect(_on_rocket_died)
    ambient.color = ambient_color
    _apply_meta_upgrades()
    _setup_run()
    _start_launch()


func _apply_meta_upgrades() -> void:
    rocket.damage += GameState.get_damage_bonus()
    rocket.shoot_cooldown /= GameState.get_shoot_rate_multiplier()
    rocket.bullet_speed *= GameState.get_bullet_speed_multiplier()
    rocket.bullet_pierce += GameState.get_bullet_pierce()


func _setup_run() -> void:
    run_context = RunContext.new()
    run_context.name = "RunContext"
    add_child(run_context)
    run_context.setup(rocket, self, asteroid_spawner, comet_spawner, card_pool)
    xp_bar.setup(run_context.progression)
    comet_spawner.run_context = run_context

    run_flow = RunFlow.new()
    run_flow.name = "RunFlow"
    add_child(run_flow)
    run_flow.setup(run_context, reward_overlay, card_pool)
    comet_spawner.comet_collected.connect(run_flow.on_comet_collected)


func _apply_starfield(rect: Rect2) -> void:
    starfield.position = rect.get_center()
    var mat := starfield.process_material as ParticleProcessMaterial
    if mat != null:
        mat.emission_box_extents = Vector3(rect.size.x * 0.5 + STARFIELD_MARGIN, rect.size.y * 0.5 + STARFIELD_MARGIN, 1.0)
    _starfield_applied_size = rect.size


func _sync_starfield_size() -> void:
    var rect := Utils.get_visible_world_rect()
    var size := rect.size
    var applied := _starfield_applied_size
    if applied == Vector2.ZERO:
        _apply_starfield(rect)
        return
    if absf(size.x - applied.x) <= STARFIELD_RESIZE_THRESHOLD and absf(size.y - applied.y) <= STARFIELD_RESIZE_THRESHOLD:
        return
    _apply_starfield(rect)


func _process(_delta: float) -> void:
    _sync_starfield_size()

    if not is_instance_valid(rocket) or rocket.is_dead():
        return

    var rect := Utils.get_visible_world_rect()
    var danger := clampf(
        inverse_lerp(rect.end.y, rect.position.y, rocket.global_position.y),
        0.0,
        1.0
    )

    var mult := _danger_multiplier(danger)

    rocket.set_danger(mult)
    asteroid_spawner.difficulty = danger
    asteroid_spawner.distance = _distance
    asteroid_pool.speed_multiplier = mult

    _distance += mult * _delta
    comet_spawner.distance = _distance
    var dist := int(_distance)
    var record := int(GameState.record_distance)
    var meter := tr("ui_meter")
    if dist > record:
        score_label.text = tr("ui_distance") % [dist, meter]
    else:
        score_label.text = tr("ui_distance_progress") % [dist, meter, record]


func _danger_multiplier(danger: float) -> float:
    var d := clampf(danger, 0.0, 1.0)
    if d <= 0.5:
        return 0.5 + d
    return 1.0 + (d - 0.5) * 2.0


func _start_launch() -> void:
    var rect := Utils.get_visible_world_rect()
    var platform_w := 170.0
    var platform_h := 18.0
    start_platform.size = Vector2(platform_w, platform_h)
    start_platform.position = Vector2(
        rect.get_center().x - platform_w * 0.5,
        rect.end.y - platform_h - 24.0
    )
    _play_position = rocket.global_position
    var platform_top := start_platform.global_position.y
    var platform_center_x := start_platform.global_position.x + platform_w * 0.5
    rocket.global_position = Vector2(platform_center_x, platform_top - 12.0)
    rocket.auto_shoot = false
    var follower := rocket.get_node_or_null("FingerFollower") as FollowFinger2D
    if follower != null:
        follower.set_process(false)
    asteroid_spawner.stop()
    comet_spawner.stop()
    comet_spawner.reset_distance(0.0)
    _launch_tween = create_tween()
    _launch_tween.tween_property(rocket, "global_position", _play_position, 0.8) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _launch_tween.finished.connect(_on_launch_finished)


func _on_launch_finished() -> void:
    _launch_tween = null
    var follower := rocket.get_node_or_null("FingerFollower") as FollowFinger2D
    if follower != null:
        follower.set_process(true)
    rocket.auto_shoot = true
    asteroid_spawner.enabled = true
    comet_spawner.enabled = true
    PlatformIntegration.mark_game_ready()
    PlatformIntegration.gameplay_started()


func _on_rocket_died() -> void:
    PauseManager.abort()
    PlatformIntegration.gameplay_stopped()
    if run_flow != null:
        run_flow.on_run_dead()
    pause_button.disabled = true
    GameState.submit_distance(_distance)
    GameState.save()
    asteroid_spawner.stop()
    comet_spawner.stop()
    # Смерть — естественная пауза забега: показываем рекламу до магазина.
    PlatformIntegration.show_interstitial()
    _begin_meta_progression()


func _on_exit_to_shop_requested() -> void:
    PlatformIntegration.gameplay_stopped()
    PauseManager.abort()
    if is_instance_valid(rocket) and not rocket.is_dead():
        rocket.force_death()


func _exit_tree() -> void:
    PlatformIntegration.gameplay_stopped()
    PauseManager.reset()


func _on_pause_pressed() -> void:
    PauseManager.pause()


func _begin_meta_progression() -> void:
    var delay := rocket.break_cleanup_delay + 0.1
    await get_tree().create_timer(delay).timeout
    Transition.goto(META_SCENE, Transition.FADE_DURATION, Transition.FADE_DURATION, "progression")
