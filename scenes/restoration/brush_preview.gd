extends Node2D
## Отображение области действия кисти — круг вокруг курсора.


func _draw() -> void:
	var radius: float = get_meta("radius", 32.0)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 1, 1, 0.4), 2.0)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0, 0, 0, 0.2), 4.0)
