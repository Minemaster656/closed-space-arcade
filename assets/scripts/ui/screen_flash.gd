extends ColorRect
class_name ScreenFlash

## Полноэкранная вспышка. Живёт в UI CanvasLayer, поэтому не зависит от камеры.

var _tween: Tween


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    color.a = 0.0


func flash(flash_color: Color, alpha: float, duration: float) -> void:
    if _tween != null and _tween.is_valid():
        _tween.kill()
    color = Color(flash_color.r, flash_color.g, flash_color.b, clampf(alpha, 0.0, 1.0))
    _tween = create_tween()
    _tween.tween_property(self, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
