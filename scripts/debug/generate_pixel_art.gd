@tool
extends EditorScript
## Генератор пиксель-арта для предметов и текстур повреждений.
## Запускать из редактора: Script -> Run (Ctrl+Shift+X)
## Создаёт PNG файлы в assets/sprites/


func _run() -> void:
	_generate_items()
	_generate_damage_overlays()
	print("Пиксель-арт сгенерирован!")


func _generate_items() -> void:
	_save_png("res://assets/sprites/items/old_clock_clean.png", _draw_clock())
	_save_png("res://assets/sprites/items/dusty_vase_clean.png", _draw_vase())
	_save_png("res://assets/sprites/items/rusty_lamp_clean.png", _draw_lamp())
	_save_png("res://assets/sprites/items/cracked_frame_clean.png", _draw_frame())
	_save_png("res://assets/sprites/items/ornate_box_clean.png", _draw_box())
	print("  Предметы: 5 файлов")


func _generate_damage_overlays() -> void:
	_save_png("res://assets/sprites/damage/rust_overlay.png", _draw_rust_overlay())
	_save_png("res://assets/sprites/damage/dust_overlay.png", _draw_dust_overlay())
	_save_png("res://assets/sprites/damage/cracks_overlay.png", _draw_cracks_overlay())
	_save_png("res://assets/sprites/damage/grime_overlay.png", _draw_grime_overlay())
	print("  Повреждения: 4 файла")


# === ПРЕДМЕТЫ (128x128, прозрачный фон) ===

func _draw_clock() -> Image:
	var img := _create_blank()
	var cx := 64
	var cy := 64

	# Корпус часов — заполняет почти весь холст
	_fill_circle(img, cx, cy, 62, Color(0.45, 0.28, 0.15))
	# Ободок (латунь)
	_draw_circle_outline(img, cx, cy, 62, Color(0.75, 0.6, 0.25), 4)
	# Циферблат (кремовый)
	_fill_circle(img, cx, cy, 52, Color(0.95, 0.92, 0.85))
	# Часовые метки
	for i in 12:
		var angle := (float(i) / 12.0) * TAU - PI / 2.0
		var mx := cx + int(cos(angle) * 45)
		var my := cy + int(sin(angle) * 45)
		_fill_rect(img, mx - 2, my - 2, 4, 4, Color(0.2, 0.15, 0.1))
	# Часовая стрелка
	_draw_line(img, cx, cy, cx - 14, cy - 30, Color(0.1, 0.08, 0.05), 3)
	# Минутная стрелка
	_draw_line(img, cx, cy, cx + 28, cy - 10, Color(0.1, 0.08, 0.05), 2)
	# Центральная точка
	_fill_circle(img, cx, cy, 4, Color(0.75, 0.6, 0.25))
	return img


func _draw_vase() -> Image:
	var img := _create_blank()
	var cx := 64

	var body_color := Color(0.3, 0.65, 0.7)
	var dark_color := Color(0.2, 0.5, 0.55)
	var highlight := Color(0.5, 0.8, 0.85)

	# Горловина
	_fill_ellipse(img, cx, 8, 18, 8, dark_color)
	_fill_ellipse(img, cx, 8, 16, 6, body_color)

	# Шейка
	for y in range(14, 30):
		var w: int = int(lerpf(16, 30, float(y - 14) / 16.0))
		_fill_rect(img, cx - w, y, w * 2, 1, body_color)
		img.set_pixel(clampi(cx - w, 0, 127), y, dark_color)
		img.set_pixel(clampi(cx + w - 1, 0, 127), y, dark_color)

	# Тело вазы — заполняет почти всю ширину
	for y in range(30, 115):
		var t := float(y - 30) / 85.0
		var w: int
		if t < 0.4:
			w = int(lerpf(30, 58, t / 0.4))
		elif t < 0.8:
			w = int(lerpf(58, 54, (t - 0.4) / 0.4))
		else:
			w = int(lerpf(54, 26, (t - 0.8) / 0.2))
		_fill_rect(img, cx - w, y, w * 2, 1, body_color)
		img.set_pixel(clampi(cx - w, 0, 127), y, dark_color)
		if cx - w + 1 < 128:
			img.set_pixel(cx - w + 1, y, dark_color)
		img.set_pixel(clampi(cx + w - 1, 0, 127), y, highlight)

	# Подставка
	_fill_rect(img, cx - 28, 115, 56, 8, dark_color)
	_fill_rect(img, cx - 26, 115, 52, 6, body_color)

	# Узор
	for x in range(cx - 50, cx + 50):
		var wave_y := 65 + int(sin(float(x) * 0.25) * 4)
		if x >= 0 and x < 128 and wave_y >= 0 and wave_y < 128:
			img.set_pixel(x, wave_y, Color(0.9, 0.85, 0.6))
			if wave_y + 1 < 128:
				img.set_pixel(x, wave_y + 1, Color(0.9, 0.85, 0.6))

	return img


func _draw_lamp() -> Image:
	var img := _create_blank()
	var cx := 64

	var shade_color := Color(0.9, 0.8, 0.5)
	var shade_dark := Color(0.7, 0.6, 0.35)
	# Абажур — широкий конус, заполняет верхнюю часть
	for y in range(4, 55):
		var t := float(y - 4) / 51.0
		var w := int(lerpf(10, 60, t))
		_fill_rect(img, cx - w, y, w * 2, 1, shade_color)
		img.set_pixel(clampi(cx - w, 0, 127), y, shade_dark)
		img.set_pixel(clampi(cx + w - 1, 0, 127), y, shade_dark)
	_fill_rect(img, cx - 60, 53, 120, 4, shade_dark)

	var copper := Color(0.72, 0.45, 0.2)
	var copper_dark := Color(0.55, 0.35, 0.15)
	# Стойка
	_fill_rect(img, cx - 4, 57, 8, 40, copper)
	_fill_rect(img, cx - 4, 57, 3, 40, copper_dark)

	# Основание — широкое
	_fill_ellipse(img, cx, 108, 42, 14, copper_dark)
	_fill_ellipse(img, cx, 106, 40, 12, copper)
	_fill_ellipse(img, cx + 10, 103, 10, 4, Color(0.85, 0.6, 0.3))

	# Лампочка
	_fill_circle(img, cx, 8, 6, Color(1.0, 0.95, 0.8))

	return img


func _draw_frame() -> Image:
	var img := _create_blank()

	var wood := Color(0.55, 0.35, 0.18)
	var wood_light := Color(0.7, 0.48, 0.25)
	var wood_dark := Color(0.35, 0.22, 0.1)

	# Внешняя рамка — заполняет весь холст
	_fill_rect(img, 2, 2, 124, 124, wood)
	# Вырез внутри
	_fill_rect(img, 18, 18, 92, 92, Color(0.0, 0.0, 0.0, 0.0))

	# Текстура дерева
	for y in range(2, 126):
		for x in range(2, 126):
			if img.get_pixel(x, y).a < 0.5:
				continue
			if (y + int(sin(float(x) * 0.2) * 2)) % 4 == 0:
				img.set_pixel(x, y, wood_dark)
			elif (y + int(sin(float(x) * 0.15) * 1.5)) % 7 == 0:
				img.set_pixel(x, y, wood_light)

	# Внутренний бордюр (золотой)
	_draw_rect_outline(img, 16, 16, 96, 96, Color(0.8, 0.7, 0.3), 2)

	# Фотография внутри
	for y in range(18, 110):
		for x in range(18, 110):
			var t := float(y - 18) / 92.0
			var sky := Color(0.5, 0.7, 0.9).lerp(Color(0.7, 0.85, 0.95), t * 0.5)
			var ground := Color(0.35, 0.55, 0.25)
			if t > 0.6:
				img.set_pixel(x, y, ground.lerp(Color(0.3, 0.45, 0.2), randf() * 0.3))
			else:
				img.set_pixel(x, y, sky)

	# Уголки
	for corner in [Vector2i(2, 2), Vector2i(118, 2), Vector2i(2, 118), Vector2i(118, 118)]:
		_fill_rect(img, corner.x, corner.y, 10, 10, Color(0.65, 0.55, 0.2))

	return img


func _draw_box() -> Image:
	var img := _create_blank()

	var wood := Color(0.4, 0.25, 0.12)
	var wood_top := Color(0.5, 0.33, 0.17)
	var brass := Color(0.75, 0.6, 0.25)
	var brass_dark := Color(0.55, 0.45, 0.15)

	# Передняя стенка — заполняет нижнюю часть
	_fill_rect(img, 4, 35, 120, 88, wood)
	# Верхняя грань (перспектива)
	for y in range(10, 35):
		var t := float(y - 10) / 25.0
		var x_start := int(lerpf(20, 4, t))
		var x_end := int(lerpf(108, 124, t))
		_fill_rect(img, x_start, y, x_end - x_start, 1, wood_top)

	# Резьба
	for y in range(42, 118, 10):
		_fill_rect(img, 8, y, 112, 1, Color(0.35, 0.2, 0.08))
	for x in range(15, 115, 14):
		_fill_rect(img, x, 40, 1, 78, Color(0.35, 0.2, 0.08))

	# Замочная скважина
	_fill_circle(img, 64, 80, 6, brass)
	_fill_rect(img, 62, 80, 5, 14, brass)
	_fill_circle(img, 64, 80, 4, brass_dark)

	# Уголки
	for corner in [Vector2i(4, 35), Vector2i(116, 35), Vector2i(4, 115), Vector2i(116, 115)]:
		_fill_rect(img, corner.x, corner.y, 10, 10, brass)
		_fill_rect(img, corner.x + 1, corner.y + 1, 8, 8, brass_dark)

	# Петли
	_fill_rect(img, 25, 32, 12, 6, brass)
	_fill_rect(img, 91, 32, 12, 6, brass)

	return img


# === ТЕКСТУРЫ ПОВРЕЖДЕНИЙ (128x128, полупрозрачные) ===

func _draw_rust_overlay() -> Image:
	var img := _create_blank()
	var colors := [
		Color(0.72, 0.35, 0.15, 0.7),
		Color(0.6, 0.25, 0.1, 0.6),
		Color(0.8, 0.4, 0.12, 0.5),
		Color(0.5, 0.2, 0.08, 0.8),
	]
	# Случайные пятна ржавчины
	for i in 80:
		var x := randi_range(0, 127)
		var y := randi_range(0, 127)
		var r := randi_range(2, 8)
		var color: Color = colors[randi() % colors.size()]
		_fill_circle(img, x, y, r, color)
	# Подтёки
	for i in 15:
		var x := randi_range(10, 118)
		var y := randi_range(10, 80)
		var length := randi_range(10, 40)
		for dy in length:
			var px := x + randi_range(-1, 1)
			var py := y + dy
			if px >= 0 and px < 128 and py >= 0 and py < 128:
				img.set_pixel(px, py, Color(0.65, 0.3, 0.1, 0.5))
				if px + 1 < 128:
					img.set_pixel(px + 1, py, Color(0.6, 0.28, 0.1, 0.3))
	return img


func _draw_dust_overlay() -> Image:
	var img := _create_blank()
	# Мелкие пылинки повсюду
	for i in 2000:
		var x := randi_range(0, 127)
		var y := randi_range(0, 127)
		var brightness := randf_range(0.55, 0.8)
		var alpha := randf_range(0.2, 0.6)
		img.set_pixel(x, y, Color(brightness, brightness, brightness * 0.95, alpha))
	# Более крупные скопления пыли
	for i in 30:
		var x := randi_range(5, 123)
		var y := randi_range(5, 123)
		var r := randi_range(3, 6)
		_fill_circle(img, x, y, r, Color(0.7, 0.68, 0.63, 0.3))
	return img


func _draw_cracks_overlay() -> Image:
	var img := _create_blank()
	var crack_color := Color(0.15, 0.12, 0.1, 0.85)
	var crack_edge := Color(0.3, 0.25, 0.2, 0.4)

	# Основные трещины (несколько линий из центра)
	for i in 5:
		var start_x := randi_range(30, 98)
		var start_y := randi_range(30, 98)
		var x := float(start_x)
		var y := float(start_y)
		var angle := randf() * TAU
		var length := randi_range(30, 70)

		for step in length:
			angle += randf_range(-0.4, 0.4)
			x += cos(angle) * 1.5
			y += sin(angle) * 1.5
			var px := int(x)
			var py := int(y)
			if px >= 1 and px < 127 and py >= 1 and py < 127:
				img.set_pixel(px, py, crack_color)
				# Края трещины
				img.set_pixel(px - 1, py, crack_edge)
				img.set_pixel(px + 1, py, crack_edge)
				img.set_pixel(px, py - 1, crack_edge)
				img.set_pixel(px, py + 1, crack_edge)

			# Ответвления
			if randi() % 8 == 0:
				var bx := x
				var by := y
				var b_angle := angle + randf_range(-1.0, 1.0)
				for b_step in randi_range(5, 15):
					bx += cos(b_angle) * 1.2
					by += sin(b_angle) * 1.2
					var bpx := int(bx)
					var bpy := int(by)
					if bpx >= 0 and bpx < 128 and bpy >= 0 and bpy < 128:
						img.set_pixel(bpx, bpy, crack_color)
	return img


func _draw_grime_overlay() -> Image:
	var img := _create_blank()
	var colors := [
		Color(0.2, 0.3, 0.15, 0.5),
		Color(0.25, 0.22, 0.12, 0.6),
		Color(0.18, 0.28, 0.1, 0.4),
		Color(0.3, 0.25, 0.15, 0.55),
	]
	# Крупные пятна грязи
	for i in 40:
		var x := randi_range(0, 127)
		var y := randi_range(0, 127)
		var r := randi_range(5, 15)
		var color: Color = colors[randi() % colors.size()]
		_fill_circle(img, x, y, r, color)
	# Мелкие капли
	for i in 100:
		var x := randi_range(0, 127)
		var y := randi_range(0, 127)
		var r := randi_range(1, 3)
		_fill_circle(img, x, y, r, Color(0.22, 0.25, 0.12, 0.4))
	return img


# === УТИЛИТЫ РИСОВАНИЯ ===

func _create_blank() -> Image:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _fill_circle(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for x in range(maxi(cx - radius, 0), mini(cx + radius + 1, 128)):
		for y in range(maxi(cy - radius, 0), mini(cy + radius + 1, 128)):
			if Vector2(x - cx, y - cy).length() <= float(radius):
				_blend_pixel(img, x, y, color)


func _fill_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	for x in range(maxi(cx - rx, 0), mini(cx + rx + 1, 128)):
		for y in range(maxi(cy - ry, 0), mini(cy + ry + 1, 128)):
			var dx := float(x - cx) / float(rx)
			var dy := float(y - cy) / float(ry)
			if dx * dx + dy * dy <= 1.0:
				_blend_pixel(img, x, y, color)


func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, 128)):
		for py in range(maxi(y, 0), mini(y + h, 128)):
			_blend_pixel(img, px, py, color)


func _draw_circle_outline(img: Image, cx: int, cy: int, radius: int, color: Color, thickness: int = 1) -> void:
	for x in range(maxi(cx - radius - thickness, 0), mini(cx + radius + thickness + 1, 128)):
		for y in range(maxi(cy - radius - thickness, 0), mini(cy + radius + thickness + 1, 128)):
			var dist := Vector2(x - cx, y - cy).length()
			if dist >= float(radius - thickness) and dist <= float(radius):
				_blend_pixel(img, x, y, color)


func _draw_rect_outline(img: Image, x: int, y: int, w: int, h: int, color: Color, thickness: int = 1) -> void:
	_fill_rect(img, x, y, w, thickness, color)
	_fill_rect(img, x, y + h - thickness, w, thickness, color)
	_fill_rect(img, x, y, thickness, h, color)
	_fill_rect(img, x + w - thickness, y, thickness, h, color)


func _draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 1) -> void:
	var dx: int = x1 - x0
	if dx < 0:
		dx = -dx
	var dy: int = y1 - y0
	if dy < 0:
		dy = -dy
	var steps: int = maxi(dx, dy)
	if steps == 0:
		_blend_pixel(img, x0, y0, color)
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := int(lerpf(float(x0), float(x1), t))
		var y := int(lerpf(float(y0), float(y1), t))
		for tx in range(-thickness / 2, thickness / 2 + 1):
			for ty in range(-thickness / 2, thickness / 2 + 1):
				var px := x + tx
				var py := y + ty
				if px >= 0 and px < 128 and py >= 0 and py < 128:
					_blend_pixel(img, px, py, color)


func _blend_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= 128 or y < 0 or y >= 128:
		return
	if color.a >= 1.0:
		img.set_pixel(x, y, color)
		return
	var existing := img.get_pixel(x, y)
	var blended := Color(
		existing.r * (1.0 - color.a) + color.r * color.a,
		existing.g * (1.0 - color.a) + color.g * color.a,
		existing.b * (1.0 - color.a) + color.b * color.a,
		clampf(existing.a + color.a * (1.0 - existing.a), 0.0, 1.0)
	)
	img.set_pixel(x, y, blended)


func _save_png(path: String, img: Image) -> void:
	var err := img.save_png(path)
	if err != OK:
		print("  ОШИБКА сохранения: %s (код %d)" % [path, err])
