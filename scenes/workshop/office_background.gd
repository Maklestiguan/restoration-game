extends Node2D
## Фон мастерской — кабинет старого реставратора.
## Всё рисуется через _draw(): стены, книжные шкафы, стол, персонаж, детали.
## Книги генерируются один раз. Погода за окном меняется со временем.

var _breath_timer: float = 0.0
var _clock_angle: float = 0.0

# Пре-сгенерированные данные книг (чтобы не мерцали)
var _books_generated: bool = false
var _books_data: Array = []  # [{x, y, w, h, color}]

# === Погода ===
enum Weather { SUNNY, CLOUDY, RAIN, SNOW, NIGHT, RAINBOW }
var _weather: int = Weather.SUNNY
var _weather_timer: float = 0.0
var _weather_transition: float = 1.0  # 0-1, плавный переход
var _weather_duration: float = 60.0
var _rain_drops: Array = []  # [{x, y, speed}]
var _snow_flakes: Array = []  # [{x, y, speed, size}]

# Цвета
const WALL := Color(0.35, 0.28, 0.2)
const WALL_DARK := Color(0.28, 0.22, 0.16)
const FLOOR := Color(0.25, 0.18, 0.12)
const FLOOR_LIGHT := Color(0.3, 0.22, 0.15)
const DESK := Color(0.4, 0.28, 0.15)
const DESK_DARK := Color(0.3, 0.2, 0.1)
const DESK_TOP := Color(0.45, 0.32, 0.18)
const SHELF := Color(0.35, 0.25, 0.14)
const SHELF_DARK := Color(0.25, 0.18, 0.1)
const BRASS := Color(0.75, 0.6, 0.25)
const BRASS_DARK := Color(0.55, 0.42, 0.15)
const SKIN := Color(0.85, 0.72, 0.58)
const SHIRT := Color(0.9, 0.88, 0.82)
const VEST := Color(0.25, 0.22, 0.2)
const HAIR := Color(0.82, 0.8, 0.76)
const GLASS_RIM := Color(0.4, 0.38, 0.35)
const CURTAIN := Color(0.5, 0.15, 0.12)
const RUG := Color(0.55, 0.2, 0.15)
const RUG_PATTERN := Color(0.65, 0.35, 0.18)
const GREEN := Color(0.3, 0.55, 0.25)
const GREEN_DARK := Color(0.2, 0.4, 0.15)

const DESK_RECT := Rect2(550, 360, 820, 180)
const CAT_AREA := Rect2(150, 560, 500, 140)

const BOOK_COLORS := [
	Color(0.6, 0.2, 0.15), Color(0.2, 0.35, 0.55), Color(0.5, 0.4, 0.2),
	Color(0.3, 0.5, 0.3), Color(0.55, 0.25, 0.4), Color(0.4, 0.3, 0.2),
	Color(0.65, 0.55, 0.3), Color(0.25, 0.25, 0.4), Color(0.7, 0.35, 0.2),
	Color(0.35, 0.2, 0.15), Color(0.5, 0.5, 0.45), Color(0.6, 0.4, 0.25),
]


func _ready() -> void:
	_generate_books()
	_init_weather_particles()
	_weather_duration = randf_range(45.0, 90.0)


func _process(delta: float) -> void:
	_breath_timer += delta * 1.5
	_clock_angle += delta * 0.1

	# Погода
	_weather_timer += delta
	if _weather_timer >= _weather_duration:
		_weather_timer = 0.0
		_weather_duration = randf_range(45.0, 90.0)
		_weather = (_weather + 1 + randi() % 3) % 6  # Случайная следующая
		_weather_transition = 0.0
		_init_weather_particles()
	if _weather_transition < 1.0:
		_weather_transition = minf(_weather_transition + delta * 0.5, 1.0)

	_update_weather_particles(delta)
	queue_redraw()


func _draw() -> void:
	_draw_wall()
	_draw_floor()
	_draw_window()
	_draw_bookshelves()
	_draw_wall_decorations()
	_draw_filing_cabinet()
	_draw_desk()
	_draw_desk_items()
	_draw_character()
	_draw_rug()
	_draw_potted_plant()
	_draw_umbrella_stand()


# === КНИГИ (пре-генерация) ===

func _generate_books() -> void:
	_books_data.clear()
	var shelves := [[400, 50, 160, 460], [1500, 50, 160, 460], [1700, 80, 130, 430]]
	for shelf_info: Array in shelves:
		var sx: int = shelf_info[0]
		var sy: int = shelf_info[1]
		var sw: int = shelf_info[2]
		var sh: int = shelf_info[3]
		@warning_ignore("integer_division")
		var shelf_h: int = (sh - 20) / 5
		for s in 5:
			var shelf_y: int = sy + 10 + s * shelf_h
			var bx: int = sx + 10
			while bx < sx + sw - 15:
				var bw: int = randi_range(6, 14)
				var bh: int = randi_range(shelf_h - 20, shelf_h - 6)
				var color: Color = BOOK_COLORS[randi() % BOOK_COLORS.size()]
				_books_data.append({
					"x": bx, "y": shelf_y + shelf_h - 4 - bh,
					"w": bw, "h": bh, "color": color,
					"shelf_x": sx, "shelf_y": sy, "shelf_w": sw, "shelf_h_total": sh
				})
				bx += bw + 2
	_books_generated = true


# === ПОГОДА ===

func _init_weather_particles() -> void:
	_rain_drops.clear()
	_snow_flakes.clear()
	if _weather == Weather.RAIN:
		for i in 40:
			_rain_drops.append({"x": randf_range(0, 200), "y": randf_range(0, 280), "speed": randf_range(300, 500)})
	elif _weather == Weather.SNOW:
		for i in 30:
			_snow_flakes.append({"x": randf_range(0, 200), "y": randf_range(0, 280), "speed": randf_range(30, 80), "size": randf_range(2, 5)})


func _update_weather_particles(delta: float) -> void:
	for drop: Dictionary in _rain_drops:
		drop["y"] += drop["speed"] * delta
		if drop["y"] > 280:
			drop["y"] = randf_range(-20, 0)
			drop["x"] = randf_range(0, 200)
	for flake: Dictionary in _snow_flakes:
		flake["y"] += flake["speed"] * delta
		flake["x"] += sin(flake["y"] * 0.02) * 0.5
		if flake["y"] > 280:
			flake["y"] = randf_range(-20, 0)
			flake["x"] = randf_range(0, 200)


func _get_sky_color() -> Color:
	match _weather:
		Weather.SUNNY: return Color(0.45, 0.65, 0.9)
		Weather.CLOUDY: return Color(0.55, 0.58, 0.62)
		Weather.RAIN: return Color(0.35, 0.4, 0.48)
		Weather.SNOW: return Color(0.7, 0.72, 0.78)
		Weather.NIGHT: return Color(0.08, 0.1, 0.18)
		Weather.RAINBOW: return Color(0.5, 0.68, 0.88)
		_: return Color(0.45, 0.65, 0.9)


# === СТЕНА ===
func _draw_wall() -> void:
	draw_rect(Rect2(0, 0, 1920, 520), WALL)
	for y in range(0, 520, 65):
		draw_rect(Rect2(0, y, 1920, 2), WALL_DARK)
	draw_rect(Rect2(0, 0, 1920, 8), DESK_DARK)
	draw_rect(Rect2(0, 515, 1920, 6), DESK_DARK)


# === ПОЛ ===
func _draw_floor() -> void:
	draw_rect(Rect2(0, 520, 1920, 560), FLOOR)
	for x in range(0, 1920, 120):
		draw_rect(Rect2(x, 520, 2, 560), FLOOR_LIGHT)
	for y in range(520, 1080, 40):
		draw_rect(Rect2(0, y, 1920, 1), Color(0.2, 0.15, 0.1, 0.3))


# === ОКНО С ПОГОДОЙ ===
func _draw_window() -> void:
	var wx := 120
	var wy := 60
	var ww := 200
	var wh := 280

	# Рама
	draw_rect(Rect2(wx - 6, wy - 6, ww + 12, wh + 12), DESK_DARK)
	draw_rect(Rect2(wx - 3, wy - 3, ww + 6, wh + 6), DESK)

	# Небо (зависит от погоды)
	var sky := _get_sky_color()
	draw_rect(Rect2(wx, wy, ww, wh), sky)

	# Погодные эффекты
	match _weather:
		Weather.SUNNY:
			# Солнце
			draw_circle(Vector2(wx + 150, wy + 50), 25, Color(1, 0.95, 0.5, 0.8))
			draw_circle(Vector2(wx + 150, wy + 50), 30, Color(1, 0.95, 0.5, 0.15))
			# Лучи
			for i in 8:
				var a := float(i) / 8.0 * TAU + _breath_timer * 0.2
				var ex := wx + 150 + int(cos(a) * 40)
				var ey := wy + 50 + int(sin(a) * 40)
				draw_line(Vector2(wx + 150, wy + 50), Vector2(ex, ey), Color(1, 0.95, 0.5, 0.1), 2)

		Weather.CLOUDY:
			# Облака
			for cx_off in [40, 100, 150]:
				_draw_cloud(wx + cx_off, wy + 40 + (cx_off % 30), 0.9)

		Weather.RAIN:
			# Тёмные облака
			for cx_off in [30, 80, 130, 170]:
				_draw_cloud(wx + cx_off, wy + 25, 0.6)
			# Капли дождя
			for drop: Dictionary in _rain_drops:
				var dx: float = wx + drop["x"]
				var dy: float = wy + drop["y"]
				if dy > wy and dy < wy + wh:
					draw_line(Vector2(dx, dy), Vector2(dx - 1, dy + 8), Color(0.6, 0.7, 0.85, 0.6), 1)

		Weather.SNOW:
			# Светлые облака
			for cx_off in [40, 110, 160]:
				_draw_cloud(wx + cx_off, wy + 30, 0.95)
			# Снежинки
			for flake: Dictionary in _snow_flakes:
				var fx: float = wx + flake["x"]
				var fy: float = wy + flake["y"]
				var fs: float = flake["size"]
				if fy > wy and fy < wy + wh:
					draw_circle(Vector2(fx, fy), fs, Color(1, 1, 1, 0.7))
			# Снег на подоконнике
			draw_rect(Rect2(wx, wy + wh - 8, ww, 8), Color(0.9, 0.92, 0.95, 0.8))

		Weather.NIGHT:
			# Звёзды
			for i in 15:
				@warning_ignore("integer_division")
				var sx: int = wx + 10 + (i * 37 + i * i * 7) % (ww - 20)
				@warning_ignore("integer_division")
				var sy: int = wy + 10 + (i * 53 + i * 13) % (wh - 40)
				var blink: float = 0.5 + 0.5 * sin(_breath_timer * 2.0 + float(i))
				draw_circle(Vector2(sx, sy), 1.5, Color(1, 1, 0.9, blink))
			# Луна
			draw_circle(Vector2(wx + 160, wy + 45), 18, Color(0.95, 0.93, 0.8, 0.9))
			draw_circle(Vector2(wx + 166, wy + 40), 15, sky)  # Полумесяц

		Weather.RAINBOW:
			# Солнце + облака + радуга
			draw_circle(Vector2(wx + 160, wy + 40), 20, Color(1, 0.95, 0.5, 0.6))
			_draw_cloud(wx + 40, wy + 50, 0.85)
			# Радуга (дуга)
			var rainbow_colors := [
				Color(1, 0.2, 0.2, 0.3), Color(1, 0.5, 0.1, 0.3),
				Color(1, 1, 0.2, 0.3), Color(0.2, 0.8, 0.2, 0.3),
				Color(0.2, 0.4, 1, 0.3), Color(0.5, 0.2, 0.8, 0.3),
			]
			for ri in rainbow_colors.size():
				@warning_ignore("integer_division")
				draw_arc(Vector2(wx + ww / 2, wy + wh + 30), 120 + ri * 6, PI * 0.15, PI * 0.85, 20, rainbow_colors[ri], 5)

	# Стекло (лёгкий блик поверх всего)
	draw_rect(Rect2(wx + 15, wy + 20, 30, 60), Color(1, 1, 1, 0.06))

	# Перекладины
	@warning_ignore("integer_division")
	draw_rect(Rect2(wx + ww / 2 - 2, wy, 4, wh), DESK_DARK)
	@warning_ignore("integer_division")
	draw_rect(Rect2(wx, wy + wh / 2 - 2, ww, 4), DESK_DARK)

	# Шторы
	for i in range(8):
		var cx: float = float(wx - 30 + i * 8)
		var shade: float = 0.85 + sin(float(i) * 1.2) * 0.15
		draw_rect(Rect2(cx, wy - 10, 7, wh + 30), CURTAIN * shade)
	for i in range(8):
		var cx: float = float(wx + ww + i * 8 - 25)
		var shade: float = 0.85 + sin(float(i) * 1.2) * 0.15
		draw_rect(Rect2(cx, wy - 10, 7, wh + 30), CURTAIN * shade)
	# Карниз
	draw_rect(Rect2(wx - 40, wy - 16, ww + 80, 6), BRASS)
	draw_circle(Vector2(wx - 38, wy - 13), 4, BRASS_DARK)
	draw_circle(Vector2(wx + ww + 38, wy - 13), 4, BRASS_DARK)


func _draw_cloud(x: int, y: int, brightness: float) -> void:
	var c := Color(brightness, brightness, brightness, 0.7)
	draw_circle(Vector2(x, y), 15, c)
	draw_circle(Vector2(x + 15, y - 5), 12, c)
	draw_circle(Vector2(x - 12, y + 3), 10, c)
	draw_circle(Vector2(x + 8, y + 5), 11, c)


# === КНИЖНЫЕ ШКАФЫ ===
func _draw_bookshelves() -> void:
	var shelves := [[400, 50, 160, 460], [1500, 50, 160, 460], [1700, 80, 130, 430]]
	for shelf_info: Array in shelves:
		var sx: int = shelf_info[0]
		var sy: int = shelf_info[1]
		var sw: int = shelf_info[2]
		var sh: int = shelf_info[3]
		# Корпус
		draw_rect(Rect2(sx, sy, sw, sh), SHELF_DARK)
		draw_rect(Rect2(sx + 4, sy + 4, sw - 8, sh - 4), SHELF)
		# Полки
		@warning_ignore("integer_division")
		var shelf_h: int = (sh - 20) / 5
		for s in 5:
			var shelf_y: int = sy + 10 + s * shelf_h
			draw_rect(Rect2(sx + 4, shelf_y + shelf_h - 4, sw - 8, 5), SHELF_DARK)

	# Рисуем пре-сгенерированные книги
	for book: Dictionary in _books_data:
		var bx: int = book["x"]
		var by: int = book["y"]
		var bw: int = book["w"]
		var bh: int = book["h"]
		var color: Color = book["color"]
		draw_rect(Rect2(bx, by, bw, bh), color)
		draw_rect(Rect2(bx + 1, by + 3, bw - 2, 2), color.darkened(0.2))


# === СТЕНА: УКРАШЕНИЯ ===
func _draw_wall_decorations() -> void:
	var cx := 1400
	var cy := 140
	draw_circle(Vector2(cx, cy), 40, DESK_DARK)
	draw_circle(Vector2(cx, cy), 36, Color(0.9, 0.88, 0.82))
	var hour_angle := _clock_angle * 0.08 - PI / 2
	var min_angle := _clock_angle - PI / 2
	draw_line(Vector2(cx, cy), Vector2(cx + cos(hour_angle) * 20, cy + sin(hour_angle) * 20), Color(0.15, 0.1, 0.08), 3)
	draw_line(Vector2(cx, cy), Vector2(cx + cos(min_angle) * 28, cy + sin(min_angle) * 28), Color(0.15, 0.1, 0.08), 2)
	draw_circle(Vector2(cx, cy), 3, BRASS)
	_draw_certificate(1150, 80, 120, 90)
	_draw_certificate(1290, 100, 100, 75)


func _draw_certificate(x: int, y: int, w: int, h: int) -> void:
	draw_rect(Rect2(x - 3, y - 3, w + 6, h + 6), BRASS_DARK)
	draw_rect(Rect2(x, y, w, h), Color(0.95, 0.92, 0.85))
	for ly in range(y + 15, y + h - 10, 10):
		@warning_ignore("integer_division")
		var lw := w / 3 + (ly * 7) % (w / 2)
		@warning_ignore("integer_division")
		draw_rect(Rect2(x + (w - lw) / 2, ly, lw, 2), Color(0.3, 0.25, 0.2, 0.4))
	@warning_ignore("integer_division")
	draw_circle(Vector2(x + w / 2, y + h - 18), 8, Color(0.7, 0.2, 0.15, 0.5))


# === СТОЛ ===
func _draw_desk() -> void:
	draw_rect(Rect2(580, 500, 15, 60), DESK_DARK)
	draw_rect(Rect2(1340, 500, 15, 60), DESK_DARK)
	draw_rect(Rect2(DESK_RECT.position.x, DESK_RECT.position.y, DESK_RECT.size.x, DESK_RECT.size.y), DESK)
	draw_rect(Rect2(DESK_RECT.position.x, DESK_RECT.position.y, DESK_RECT.size.x, 6), DESK_TOP)
	draw_rect(Rect2(DESK_RECT.position.x, DESK_RECT.position.y + DESK_RECT.size.y - 8, DESK_RECT.size.x, 8), DESK_DARK)
	for i in range(3):
		var dy: float = DESK_RECT.position.y + 30 + float(i) * 50
		draw_rect(Rect2(DESK_RECT.position.x + 10, dy, 130, 40), DESK_DARK)
		draw_rect(Rect2(DESK_RECT.position.x + 12, dy + 2, 126, 36), DESK)
		draw_rect(Rect2(DESK_RECT.position.x + 60, dy + 16, 30, 6), BRASS)


# === ПРЕДМЕТЫ НА СТОЛЕ ===
func _draw_desk_items() -> void:
	var dx: float = DESK_RECT.position.x
	var dy: float = DESK_RECT.position.y
	_draw_lamp(int(dx + 80), int(dy - 80))
	for i in range(5):
		var px: float = dx + 640 + float(i) * 3
		var py: float = dy + 8 - float(i) * 4
		draw_rect(Rect2(px, py, 80, 55), Color(0.92 - float(i) * 0.02, 0.9 - float(i) * 0.02, 0.84))
	draw_rect(Rect2(dx + 750, dy + 10, 20, 20), Color(0.15, 0.12, 0.1))
	draw_rect(Rect2(dx + 748, dy + 8, 24, 5), BRASS)
	draw_circle(Vector2(dx + 620, dy + 30), 15, Color(0.7, 0.75, 0.8, 0.3))
	draw_arc(Vector2(dx + 620, dy + 30), 15, 0, TAU, 24, BRASS, 3)
	draw_line(Vector2(dx + 630, dy + 42), Vector2(dx + 645, dy + 60), BRASS_DARK, 3)


func _draw_lamp(x: int, y: int) -> void:
	draw_rect(Rect2(x - 15, y + 65, 30, 8), BRASS_DARK)
	draw_rect(Rect2(x - 3, y + 15, 6, 52), BRASS)
	for i in range(20):
		var t := float(i) / 20.0
		var w := int(lerpf(8.0, 30.0, t))
		draw_rect(Rect2(x - w, y + i * 2, w * 2, 2), Color(0.3, 0.5, 0.3))
	draw_circle(Vector2(x, y + 40), 45, Color(1.0, 0.95, 0.7, 0.06))


# === ПЕРСОНАЖ ===
func _draw_character() -> void:
	var cx := 500
	var cy := 340
	var breath := sin(_breath_timer) * 1.5
	draw_rect(Rect2(cx - 25, cy + 40, 50, 80), DESK_DARK)
	draw_rect(Rect2(cx - 30, cy - 20, 8, 140), DESK_DARK)
	draw_rect(Rect2(cx - 10, cy + 100 + breath, 20, 30), Color(0.3, 0.28, 0.25))
	draw_rect(Rect2(cx - 18, cy + 10 + breath, 36, 60), SHIRT)
	draw_rect(Rect2(cx - 15, cy + 12 + breath, 30, 56), VEST)
	draw_rect(Rect2(cx + 15, cy + 35 + breath, 40, 10), SHIRT)
	draw_rect(Rect2(cx + 50, cy + 33 + breath, 12, 12), SKIN)
	draw_rect(Rect2(cx - 25, cy + 30 + breath, 12, 30), SHIRT)
	var head_y: float = cy - 10 + breath
	draw_rect(Rect2(cx - 5, head_y + 15, 10, 10), SKIN)
	draw_rect(Rect2(cx - 14, head_y - 20, 28, 35), SKIN)
	draw_rect(Rect2(cx - 16, head_y - 24, 32, 8), HAIR)
	draw_rect(Rect2(cx - 16, head_y - 24, 6, 20), HAIR)
	draw_arc(Vector2(cx + 2, head_y - 5), 7, 0, TAU, 16, GLASS_RIM, 2)
	draw_arc(Vector2(cx + 18, head_y - 5), 7, 0, TAU, 16, GLASS_RIM, 2)
	draw_line(Vector2(cx + 9, head_y - 5), Vector2(cx + 11, head_y - 5), GLASS_RIM, 2)
	draw_line(Vector2(cx - 5, head_y - 5), Vector2(cx - 14, head_y - 8), GLASS_RIM, 2)
	for i in range(8):
		var bw := 14 - i
		draw_rect(Rect2(cx - bw + 2, head_y + 12 + i * 3, bw * 2, 3), HAIR)
	draw_rect(Rect2(cx + 12, head_y - 6, 5, 8), SKIN.darkened(0.1))


# === КОВЁР ===
func _draw_rug() -> void:
	draw_rect(Rect2(300, 600, 400, 80), RUG)
	draw_rect(Rect2(305, 605, 390, 70), RUG_PATTERN)
	draw_rect(Rect2(312, 612, 376, 56), RUG)
	for i in range(6):
		draw_rect(Rect2(340 + i * 60, 630, 20, 20), RUG_PATTERN)


# === ШКАФ ===
func _draw_filing_cabinet() -> void:
	var fx := 1650
	var fy := 400
	draw_rect(Rect2(fx, fy, 80, 160), Color(0.4, 0.38, 0.35))
	draw_rect(Rect2(fx + 2, fy + 2, 76, 156), Color(0.5, 0.48, 0.44))
	for i in range(4):
		var dy := fy + 6 + i * 38
		draw_rect(Rect2(fx + 6, dy, 68, 34), Color(0.45, 0.43, 0.4))
		draw_rect(Rect2(fx + 30, dy + 14, 20, 5), BRASS)


# === РАСТЕНИЕ ===
func _draw_potted_plant() -> void:
	var px := 1770
	var py := 470
	draw_rect(Rect2(px - 15, py, 30, 30), Color(0.6, 0.35, 0.2))
	draw_rect(Rect2(px - 18, py - 3, 36, 6), Color(0.55, 0.3, 0.18))
	draw_rect(Rect2(px - 13, py - 2, 26, 5), Color(0.3, 0.2, 0.12))
	for i in range(5):
		var angle := float(i) * 1.2 - 1.2
		var lx := px + int(cos(angle) * 20)
		var ly := py - 15 + int(sin(angle) * 12) - i * 6
		draw_rect(Rect2(lx - 8, ly, 16, 8), GREEN)
		draw_rect(Rect2(lx - 6, ly + 2, 12, 4), GREEN_DARK)


# === ЗОНТ ===
func _draw_umbrella_stand() -> void:
	var ux := 80
	var uy := 460
	draw_rect(Rect2(ux - 12, uy, 24, 50), Color(0.35, 0.3, 0.25))
	draw_rect(Rect2(ux - 14, uy - 3, 28, 6), BRASS)
	draw_line(Vector2(ux - 4, uy - 5), Vector2(ux - 15, uy - 60), Color(0.2, 0.18, 0.15), 3)
	draw_arc(Vector2(ux - 15, uy - 65), 6, PI * 0.5, PI * 1.5, 8, Color(0.5, 0.3, 0.15), 3)
