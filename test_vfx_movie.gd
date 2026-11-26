extends Node2D

func _ready() -> void:
    var bg := ColorRect.new()
    bg.size = Vector2(720, 1280)
    bg.color = Color(0.03, 0.035, 0.05)
    add_child(bg)

    var effect: Node2D = load("res://assets/prefabs/vfx/vfx_effect.tscn").instantiate()
    add_child(effect)
    await get_tree().process_frame
    effect.play({
        "lifetime": 1.25, "fade": 0.25, "sparks": 8, "debris": 10,
        "debris_tex": &"rock", "smoke": 4, "flash": 1, "speed": 1.15,
        "scale": 0.95,
    }, Vector2(360, 640), Vector2.UP, Color(1.0, 0.65, 0.3), 0.95, 2)
    await get_tree().create_timer(1.6).timeout
    get_tree().quit()
