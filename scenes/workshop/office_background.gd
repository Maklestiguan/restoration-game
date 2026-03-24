extends Node2D
## Фон мастерской — кабинет старого реставратора.
## Книги генерируются один раз. Погода за окном меняется со временем.

var _breath_timer: float = 0.0
var _clock_angle: float = 0.0

## Состояния персонажа (всегда стоит/ходит, никогда не сидит)
enum CharState { WALKING, AT_WINDOW, AT_BOOKSHELF, AT_TEA, AT_CABINET, AT_PLANT, AT_FISH_TANK, WANDERING }
var _char_state: int = CharState.AT_BOOKSHELF
var _char_timer: float = 3.0
var _char_anim: float = 0.0
var _char_x: float = 420.0  ## Текущая позиция X (старт у шкафа)
var _char_target_x: float = 420.0  ## Куда идёт
var _char_facing: float = 1.0  ## Направление взгляда (1 = вправо)
var _walk_cycle: float = 0.0  ## Фаза шага для анимации ног
const WINDOW_X := 220.0  ## У окна
const BOOKSHELF_X := 420.0  ## У левого шкафа
const TEA_X := 1100.0  ## У столика с чаем
const CABINET_X := 1420.0  ## У шкафа с документами
const FISH_TANK_X := 1580.0  ## У аквариума
const PLANT_X := 1780.0  ## У растения
const CHAR_SPEED := 60.0  ## Скорость ходьбы
const CHAR_FLOOR_Y := 580.0  ## Уровень пола (ноги стоят тут, ниже стола)
## Все возможные точки назначения с весами (чаще ходит к окну и шкафу)
const DESTINATIONS := [
	{"x": 220.0, "state": 1, "weight": 3.0},   # AT_WINDOW
	{"x": 420.0, "state": 2, "weight": 3.0},   # AT_BOOKSHELF
	{"x": 1100.0, "state": 3, "weight": 2.0},  # AT_TEA
	{"x": 1420.0, "state": 4, "weight": 1.5},  # AT_CABINET
	{"x": 1780.0, "state": 5, "weight": 1.0},  # AT_PLANT
	{"x": 1580.0, "state": 6, "weight": 1.5},  # AT_FISH_TANK
]

## Данные рыбок для аквариума
var _fish_data: Array = []

var _books_generated: bool = false
var _books_data: Array = []

enum Weather { SUNNY, CLOUDY, RAIN, SNOW, NIGHT, RAINBOW }
var _weather: int = Weather.SUNNY
var _weather_timer: float = 0.0
var _weather_transition: float = 1.0
var _weather_duration: float = 60.0
var _rain_drops: Array = []
var _snow_flakes: Array = []

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
const CAT_AREA := Rect2(200, 560, 500, 140)

const BOOK_COLORS := [
	Color(0.6, 0.2, 0.15), Color(0.2, 0.35, 0.55), Color(0.5, 0.4, 0.2),
	Color(0.3, 0.5, 0.3), Color(0.55, 0.25, 0.4), Color(0.4, 0.3, 0.2),
	Color(0.65, 0.55, 0.3), Color(0.25, 0.25, 0.4), Color(0.7, 0.35, 0.2),
	Color(0.35, 0.2, 0.15), Color(0.5, 0.5, 0.45), Color(0.6, 0.4, 0.25),
]


func _ready() -> void:
	_generate_books()
	_generate_fish()
	_init_weather_particles()
	_weather_duration = randf_range(45.0, 90.0)


func _process(delta: float) -> void:
	_breath_timer += delta * 1.5
	_clock_angle += delta * 0.1
	_weather_timer += delta
	if _weather_timer >= _weather_duration:
		_weather_timer = 0.0
		_weather_duration = randf_range(45.0, 90.0)
		_weather = (_weather + 1 + randi() % 3) % 6
		_weather_transition = 0.0
		_init_weather_particles()
	if _weather_transition < 1.0:
		_weather_transition = minf(_weather_transition + delta * 0.5, 1.0)
	_update_weather_particles(delta)
	# Персонаж: движение и смена действий
	_char_anim += delta
	_update_character(delta)
	queue_redraw()


func _draw() -> void:
	# Слой 1: задний фон (стена, пол, окно)
	_draw_wall()
	_draw_floor()
	_draw_window()
	# Слой 2: стенные элементы (шкафы, монитор, декор)
	_draw_bookshelves()
	_draw_monitor_frame()
	_draw_wall_decorations()
	_draw_fish_tank()
	# Слой 3: мебель на полу (перед стеной)
	_draw_filing_cabinet()
	_draw_coat_rack()
	_draw_potted_plant()
	_draw_umbrella_stand()
	_draw_side_table()
	# Слой 4: стол и предметы на нём
	_draw_desk()
	_draw_desk_lamp()
	_draw_desk_items()
	_draw_piggy_bank()
	# Слой 5: ковёр и персонаж (передний план)
	_draw_rug()
	_draw_character()


# === КНИГИ ===
func _generate_books() -> void:
	_books_data.clear()
	var shelves := [[380, 50, 170, 460]]
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
				_books_data.append({"x": bx, "y": shelf_y + shelf_h - 4 - bh, "w": bw, "h": bh, "color": color})
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


# === ОКНО (большое, с горами и деревьями за стеклом) ===
func _draw_window() -> void:
	var wx := 80
	var wy := 40
	var ww := 280
	var wh := 380
	# Рамка окна (толстая, деревянная)
	draw_rect(Rect2(wx - 8, wy - 8, ww + 16, wh + 16), DESK_DARK)
	draw_rect(Rect2(wx - 4, wy - 4, ww + 8, wh + 8), DESK)

	# === Всё за стеклом (небо, горы, деревья, погода) ===
	var sky := _get_sky_color()
	draw_rect(Rect2(wx, wy, ww, wh), sky)

	# Горы на заднем плане
	var mountain_col := sky.darkened(0.15)
	var mountain_base := wy + wh - 60
	# Большая гора слева
	_draw_triangle(wx + 60, mountain_base - 120, wx - 10, mountain_base, wx + 130, mountain_base, mountain_col)
	# Средняя гора справа
	_draw_triangle(wx + 200, mountain_base - 90, wx + 130, mountain_base, wx + 290, mountain_base, mountain_col.lightened(0.05))
	# Маленькая гора по центру
	_draw_triangle(wx + 140, mountain_base - 60, wx + 80, mountain_base, wx + 200, mountain_base, mountain_col.darkened(0.05))
	# Снежные шапки
	if _weather != Weather.NIGHT:
		_draw_triangle(wx + 60, mountain_base - 120, wx + 35, mountain_base - 90, wx + 85, mountain_base - 90, Color(0.95, 0.95, 0.98, 0.6))
		_draw_triangle(wx + 200, mountain_base - 90, wx + 180, mountain_base - 65, wx + 220, mountain_base - 65, Color(0.95, 0.95, 0.98, 0.5))

	# Деревья (тёмно-зелёные силуэты перед горами)
	var tree_col := Color(0.15, 0.3, 0.12) if _weather != Weather.NIGHT else Color(0.05, 0.1, 0.05)
	var tree_base := wy + wh - 20
	for tx_off in [20, 55, 85, 120, 160, 195, 230, 260]:
		var tree_h: int = 25 + (tx_off * 7) % 20
		var tree_x: int = wx + tx_off
		# Ствол
		draw_rect(Rect2(tree_x - 2, tree_base - tree_h, 4, tree_h), tree_col.darkened(0.2))
		# Крона (ёлка — треугольник)
		_draw_triangle(tree_x, tree_base - tree_h - 15, tree_x - 10, tree_base - tree_h + 5, tree_x + 10, tree_base - tree_h + 5, tree_col)
		_draw_triangle(tree_x, tree_base - tree_h - 8, tree_x - 8, tree_base - tree_h + 10, tree_x + 8, tree_base - tree_h + 10, tree_col.lightened(0.03))

	# Земля/трава
	draw_rect(Rect2(wx, tree_base, ww, wy + wh - tree_base), Color(0.2, 0.35, 0.15) if _weather != Weather.NIGHT else Color(0.08, 0.12, 0.06))

	# Погодные эффекты (за стеклом)
	match _weather:
		Weather.SUNNY:
			draw_circle(Vector2(wx + 220, wy + 50), 30, Color(1, 0.95, 0.5, 0.7))
			draw_circle(Vector2(wx + 220, wy + 50), 40, Color(1, 0.95, 0.5, 0.12))
			for i in 8:
				var a := float(i) / 8.0 * TAU + _breath_timer * 0.2
				draw_line(Vector2(wx + 220, wy + 50), Vector2(wx + 220 + int(cos(a) * 50), wy + 50 + int(sin(a) * 50)), Color(1, 0.95, 0.5, 0.08), 2)
		Weather.CLOUDY:
			for cx_off in [40, 120, 200]:
				_draw_cloud(wx + cx_off, wy + 50 + (cx_off % 30), 0.9)
		Weather.RAIN:
			for cx_off in [30, 90, 150, 220]:
				_draw_cloud(wx + cx_off, wy + 30, 0.6)
			for drop: Dictionary in _rain_drops:
				var dx: float = wx + drop["x"] * 1.4
				var dy: float = wy + drop["y"] * 1.35
				if dy > wy and dy < wy + wh:
					draw_line(Vector2(dx, dy), Vector2(dx - 1, dy + 8), Color(0.6, 0.7, 0.85, 0.5), 1)
		Weather.SNOW:
			for cx_off in [50, 140, 220]:
				_draw_cloud(wx + cx_off, wy + 35, 0.95)
			for flake: Dictionary in _snow_flakes:
				var fx: float = wx + flake["x"] * 1.4
				var fy: float = wy + flake["y"] * 1.35
				var fs: float = flake["size"]
				if fy > wy and fy < wy + wh:
					draw_circle(Vector2(fx, fy), fs, Color(1, 1, 1, 0.7))
			draw_rect(Rect2(wx, wy + wh - 12, ww, 12), Color(0.9, 0.92, 0.95, 0.7))
		Weather.NIGHT:
			for i in 20:
				@warning_ignore("integer_division")
				var sx: int = wx + 10 + (i * 37 + i * i * 7) % (ww - 20)
				@warning_ignore("integer_division")
				var sy: int = wy + 10 + (i * 53 + i * 13) % (wh / 2)
				var blink: float = 0.5 + 0.5 * sin(_breath_timer * 2.0 + float(i))
				draw_circle(Vector2(sx, sy), 1.5, Color(1, 1, 0.9, blink))
			draw_circle(Vector2(wx + 220, wy + 45), 22, Color(0.95, 0.93, 0.8, 0.9))
			draw_circle(Vector2(wx + 228, wy + 40), 18, sky)
		Weather.RAINBOW:
			draw_circle(Vector2(wx + 220, wy + 40), 24, Color(1, 0.95, 0.5, 0.5))
			_draw_cloud(wx + 50, wy + 60, 0.85)
			var rc := [Color(1, 0.2, 0.2, 0.3), Color(1, 0.5, 0.1, 0.3), Color(1, 1, 0.2, 0.3), Color(0.2, 0.8, 0.2, 0.3), Color(0.2, 0.4, 1, 0.3), Color(0.5, 0.2, 0.8, 0.3)]
			for ri in rc.size():
				@warning_ignore("integer_division")
				draw_arc(Vector2(wx + ww / 2, wy + wh - 60), 140 + ri * 6, PI * 1.15, PI * 1.85, 20, rc[ri], 5)

	# Блик на стекле
	draw_rect(Rect2(wx + 15, wy + 20, 30, 80), Color(1, 1, 1, 0.04))
	draw_rect(Rect2(wx + 20, wy + 30, 15, 40), Color(1, 1, 1, 0.03))

	# === Рамка окна (поверх всего за стеклом) ===
	@warning_ignore("integer_division")
	draw_rect(Rect2(wx + ww / 2 - 2, wy, 4, wh), DESK_DARK)
	@warning_ignore("integer_division")
	draw_rect(Rect2(wx, wy + wh / 2 - 2, ww, 4), DESK_DARK)

	# Шторы (поверх рамки)
	for i in range(10):
		var curtain_x: float = float(wx - 35 + i * 8)
		draw_rect(Rect2(curtain_x, wy - 15, 7, wh + 40), CURTAIN * (0.85 + sin(float(i) * 1.2) * 0.15))
	for i in range(10):
		var curtain_x: float = float(wx + ww + i * 8 - 30)
		draw_rect(Rect2(curtain_x, wy - 15, 7, wh + 40), CURTAIN * (0.85 + sin(float(i) * 1.2) * 0.15))
	# Карниз
	draw_rect(Rect2(wx - 45, wy - 20, ww + 90, 6), BRASS)
	draw_circle(Vector2(wx - 43, wy - 17), 4, BRASS_DARK)
	draw_circle(Vector2(wx + ww + 43, wy - 17), 4, BRASS_DARK)

func _draw_triangle(x1: int, y1: int, x2: int, y2: int, x3: int, y3: int, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x1, y1), Vector2(x2, y2), Vector2(x3, y3)]), color)


func _draw_cloud(x: int, y: int, brightness: float) -> void:
	var c := Color(brightness, brightness, brightness, 0.7)
	draw_circle(Vector2(x, y), 15, c)
	draw_circle(Vector2(x + 15, y - 5), 12, c)
	draw_circle(Vector2(x - 12, y + 3), 10, c)
	draw_circle(Vector2(x + 8, y + 5), 11, c)


# === КНИЖНЫЕ ШКАФЫ ===
func _draw_bookshelves() -> void:
	var shelves := [[380, 50, 170, 460]]
	for shelf_info: Array in shelves:
		var sx: int = shelf_info[0]
		var sy: int = shelf_info[1]
		var sw: int = shelf_info[2]
		var sh: int = shelf_info[3]
		draw_rect(Rect2(sx, sy, sw, sh), SHELF_DARK)
		draw_rect(Rect2(sx + 4, sy + 4, sw - 8, sh - 4), SHELF)
		@warning_ignore("integer_division")
		var shelf_h: int = (sh - 20) / 5
		for s in 5:
			var shelf_y: int = sy + 10 + s * shelf_h
			draw_rect(Rect2(sx + 4, shelf_y + shelf_h - 4, sw - 8, 5), SHELF_DARK)
	for book: Dictionary in _books_data:
		draw_rect(Rect2(book["x"], book["y"], book["w"], book["h"]), book["color"])
		draw_rect(Rect2(book["x"] + 1, book["y"] + 3, book["w"] - 2, 2), book["color"].darkened(0.2))


# === СТЕНА: УКРАШЕНИЯ ===
func _draw_wall_decorations() -> void:
	# Часы (между шкафами)
	var cx := 1300
	var cy := 130
	draw_circle(Vector2(cx, cy), 45, DESK_DARK)
	draw_circle(Vector2(cx, cy), 40, Color(0.9, 0.88, 0.82))
	var ha := _clock_angle * 0.08 - PI / 2
	var ma := _clock_angle - PI / 2
	draw_line(Vector2(cx, cy), Vector2(cx + cos(ha) * 22, cy + sin(ha) * 22), Color(0.15, 0.1, 0.08), 3)
	draw_line(Vector2(cx, cy), Vector2(cx + cos(ma) * 32, cy + sin(ma) * 32), Color(0.15, 0.1, 0.08), 2)
	draw_circle(Vector2(cx, cy), 3, BRASS)

	# 3 сертификата (слева от монитора, на стене)
	_draw_certificate(600, 80, 110, 80)
	_draw_certificate(600, 175, 110, 80)
	_draw_certificate(600, 270, 110, 80)

	# Карта мира (между правыми шкафами)
	draw_rect(Rect2(1400, 220, 80, 60), BRASS_DARK)
	draw_rect(Rect2(1402, 222, 76, 56), Color(0.85, 0.8, 0.7))
	# Условные континенты
	draw_rect(Rect2(1415, 235, 15, 20), Color(0.4, 0.55, 0.3, 0.5))
	draw_rect(Rect2(1440, 240, 20, 15), Color(0.4, 0.55, 0.3, 0.5))
	draw_rect(Rect2(1455, 250, 12, 18), Color(0.4, 0.55, 0.3, 0.5))

func _draw_certificate(x: int, y: int, w: int, h: int) -> void:
	draw_rect(Rect2(x - 3, y - 3, w + 6, h + 6), BRASS_DARK)
	draw_rect(Rect2(x, y, w, h), Color(0.95, 0.92, 0.85))
	for ly in range(y + 15, y + h - 10, 10):
		@warning_ignore("integer_division")
		var lw := w / 3 + (ly * 7) % (w / 2)
		@warning_ignore("integer_division")
		draw_rect(Rect2(x + (w - lw) / 2, ly, lw, 2), Color(0.3, 0.25, 0.2, 0.4))
	@warning_ignore("integer_division")
	draw_circle(Vector2(x + w / 2, y + h - 16), 8, Color(0.7, 0.2, 0.15, 0.5))


# === МОНИТОР-РАМКА вокруг области предмета ===
func _draw_monitor_frame() -> void:
	## Рисуем рамку экрана реставрационного сканера вокруг ItemBorder (750,30 — 1230,340)
	var mx := 743
	var my := 22
	var mw := 494
	var mh := 326
	# Внешняя рамка (тёмная)
	draw_rect(Rect2(mx - 6, my - 6, mw + 12, mh + 12), DESK_DARK)
	# Средняя рамка (светлее)
	draw_rect(Rect2(mx - 3, my - 3, mw + 6, mh + 6), Color(0.32, 0.26, 0.18))
	# Подставка снизу (крепление к стене)
	draw_rect(Rect2(mx + 220, my + mh + 6, 100, 8), DESK_DARK)
	draw_rect(Rect2(mx + 250, my + mh + 14, 40, 16), DESK_DARK)
	# LED индикатор (зелёный, мигает)
	var led_alpha := 0.5 + 0.5 * sin(_breath_timer * 2.0)
	draw_circle(Vector2(mx + mw - 10, my + mh + 2), 3, Color(0.2, 0.8, 0.2, led_alpha))


# === СТОЛ ===
func _draw_desk() -> void:
	# Ножки
	draw_rect(Rect2(570, 510, 18, 50), DESK_DARK)
	draw_rect(Rect2(1345, 510, 18, 50), DESK_DARK)
	# Столешница
	draw_rect(Rect2(DESK_RECT.position.x, DESK_RECT.position.y, DESK_RECT.size.x, DESK_RECT.size.y), DESK)
	draw_rect(Rect2(DESK_RECT.position.x, DESK_RECT.position.y, DESK_RECT.size.x, 6), DESK_TOP)
	draw_rect(Rect2(DESK_RECT.position.x, DESK_RECT.position.y + DESK_RECT.size.y - 8, DESK_RECT.size.x, 8), DESK_DARK)
	# Ящики СЛЕВА (под персонажем)
	for i in range(3):
		var dy: float = DESK_RECT.position.y + 25 + float(i) * 50
		draw_rect(Rect2(DESK_RECT.position.x + 10, dy, 110, 42), DESK_DARK)
		draw_rect(Rect2(DESK_RECT.position.x + 12, dy + 2, 106, 38), DESK)
		draw_rect(Rect2(DESK_RECT.position.x + 50, dy + 17, 28, 6), BRASS)


# === НАСТОЛЬНАЯ ЛАМПА (большая, узнаваемая) ===
func _draw_desk_lamp() -> void:
	var lx := 620  # Слева от монитора, на столе
	var ly := 270  # Выше стола

	# Основание (тяжёлое, на столе)
	draw_rect(Rect2(lx - 20, ly + 80, 40, 10), BRASS_DARK)
	draw_rect(Rect2(lx - 16, ly + 78, 32, 6), BRASS)

	# Стойка
	draw_rect(Rect2(lx - 3, ly + 20, 6, 60), BRASS)
	draw_rect(Rect2(lx - 2, ly + 20, 4, 60), BRASS_DARK)

	# Абажур (большой зелёный конус)
	for i in range(25):
		var t := float(i) / 25.0
		var w := int(lerpf(6.0, 40.0, t))
		var shade := Color(0.2, 0.42, 0.2).lerp(Color(0.35, 0.55, 0.3), t)
		draw_rect(Rect2(lx - w, ly + i * 2, w * 2, 2), shade)
	# Нижний край абажура
	draw_rect(Rect2(lx - 40, ly + 48, 80, 3), Color(0.15, 0.3, 0.15))

	# Свечение тёплое (большой мягкий круг под абажуром)
	draw_circle(Vector2(lx, ly + 60), 60, Color(1.0, 0.95, 0.7, 0.04))
	draw_circle(Vector2(lx, ly + 55), 35, Color(1.0, 0.95, 0.7, 0.06))


# === ПРЕДМЕТЫ НА СТОЛЕ (справа от зоны предмета, НА столешнице) ===
func _draw_desk_items() -> void:
	var dy: float = DESK_RECT.position.y  # y=360 — верх столешницы

	# Стопка бумаг (на столе справа)
	for i in range(3):
		var px: float = 1260.0 + float(i) * 2
		var py: float = dy - 2 - float(i) * 2
		draw_rect(Rect2(px, py, 60, 40), Color(0.92 - float(i) * 0.02, 0.9 - float(i) * 0.02, 0.84))

	# Чернильница (на столе)
	draw_rect(Rect2(1250, dy - 22, 22, 22), Color(0.15, 0.12, 0.1))
	draw_rect(Rect2(1248, dy - 24, 26, 5), BRASS)
	# Перо
	draw_line(Vector2(1261, dy - 24), Vector2(1275, dy - 52), Color(0.9, 0.88, 0.82), 2)

	# Лупа (на столе)
	draw_circle(Vector2(1340, dy - 15), 14, Color(0.7, 0.75, 0.8, 0.3))
	draw_arc(Vector2(1340, dy - 15), 14, 0, TAU, 20, BRASS, 2)
	draw_line(Vector2(1350, dy - 5), Vector2(1358, dy + 6), BRASS_DARK, 3)


# === КОПИЛКА НА СТОЛЕ ===
func _draw_piggy_bank() -> void:
	if not GameManager.tool_levels.has("eq_piggy_bank"):
		return
	var px := 690
	var py := int(DESK_RECT.position.y) - 16  ## Сидит на столешнице
	var pig := Color(0.9, 0.6, 0.65)
	var pig_dark := Color(0.75, 0.45, 0.5)
	# Тело
	draw_rect(Rect2(px - 14, py - 8, 28, 18), pig)
	draw_rect(Rect2(px - 12, py - 10, 24, 4), pig)
	# Ноги
	draw_rect(Rect2(px - 10, py + 10, 5, 6), pig_dark)
	draw_rect(Rect2(px - 2, py + 10, 5, 6), pig_dark)
	draw_rect(Rect2(px + 5, py + 10, 5, 6), pig_dark)
	draw_rect(Rect2(px + 10, py + 10, 5, 6), pig_dark)
	# Голова (морда)
	draw_rect(Rect2(px + 14, py - 6, 10, 12), pig)
	# Пятачок
	draw_rect(Rect2(px + 22, py - 2, 6, 6), pig_dark)
	# Ухо
	draw_rect(Rect2(px + 16, py - 12, 6, 6), pig_dark)
	# Глаз
	draw_rect(Rect2(px + 18, py - 4, 2, 2), Color(0.15, 0.1, 0.1))
	# Щель для монет
	draw_rect(Rect2(px - 6, py - 12, 12, 3), Color(0.3, 0.2, 0.2))
	# Блеск (если есть баланс)
	if GameManager.piggy_bank_balance > 0:
		var sparkle := sin(_breath_timer * 3.0) * 0.5 + 0.5
		draw_rect(Rect2(px - 2, py - 14, 3, 3), Color(1, 0.9, 0.3, sparkle * 0.6))


# === РЫБКИ ДЛЯ АКВАРИУМА ===
func _generate_fish() -> void:
	_fish_data.clear()
	var colors := [Color(1, 0.5, 0.2), Color(0.3, 0.6, 1), Color(1, 0.3, 0.3), Color(0.9, 0.8, 0.2)]
	for i in 4:
		_fish_data.append({
			"x": randf_range(10, 80), "y": randf_range(15, 50),
			"phase": randf() * TAU, "speed": randf_range(0.8, 1.5),
			"color": colors[i], "size": randf_range(5, 8),
		})


func get_character_x() -> float:
	## Для кота — узнать где сейчас персонаж
	return _char_x


# === ПЕРСОНАЖ: логика движения ===
func _update_character(delta: float) -> void:
	match _char_state:
		CharState.WALKING:
			_walk_cycle += delta * 6.0
			var dir := 1.0 if _char_target_x > _char_x else -1.0
			_char_facing = dir
			_char_x += dir * CHAR_SPEED * delta
			# Дошёл до цели?
			if absf(_char_x - _char_target_x) < 5.0:
				_char_x = _char_target_x
				_char_anim = 0.0
				_char_state = _get_state_for_position(_char_target_x)
				_char_timer = _get_duration_for_state(_char_state)
		CharState.WANDERING:
			_char_timer -= delta
			if _char_timer <= 0:
				_pick_next_destination()
		_:
			# Все остальные состояния — стоит и делает что-то
			_char_timer -= delta
			if _char_timer <= 0:
				_pick_next_destination()


func _pick_next_destination() -> void:
	## Выбираем случайную точку назначения (взвешенный выбор, не туда где стоим)
	var total_weight := 0.0
	for dest: Dictionary in DESTINATIONS:
		if absf(dest["x"] - _char_x) > 30:  # Не идём туда же
			total_weight += dest["weight"]
	# 20% шанс просто побродить
	if randf() < 0.2:
		_char_state = CharState.WALKING
		_char_target_x = randf_range(100.0, 1800.0)
		_char_facing = 1.0 if _char_target_x > _char_x else -1.0
		_walk_cycle = 0.0
		# После прихода — WANDERING (просто постоять)
		return
	var roll := randf() * total_weight
	var cumulative := 0.0
	for dest: Dictionary in DESTINATIONS:
		if absf(dest["x"] - _char_x) > 30:
			cumulative += dest["weight"]
			if roll <= cumulative:
				_char_state = CharState.WALKING
				_char_target_x = dest["x"]
				_char_facing = 1.0 if _char_target_x > _char_x else -1.0
				_walk_cycle = 0.0
				return
	# Fallback
	_char_state = CharState.WALKING
	_char_target_x = BOOKSHELF_X
	_char_facing = -1.0 if _char_x > BOOKSHELF_X else 1.0
	_walk_cycle = 0.0


func _get_state_for_position(x: float) -> int:
	if absf(x - WINDOW_X) < 30: return CharState.AT_WINDOW
	if absf(x - BOOKSHELF_X) < 30: return CharState.AT_BOOKSHELF
	if absf(x - TEA_X) < 30: return CharState.AT_TEA
	if absf(x - CABINET_X) < 30: return CharState.AT_CABINET
	if absf(x - PLANT_X) < 30: return CharState.AT_PLANT
	if absf(x - FISH_TANK_X) < 30: return CharState.AT_FISH_TANK
	return CharState.WANDERING


func _get_duration_for_state(state: int) -> float:
	match state:
		CharState.AT_WINDOW: return randf_range(4.0, 6.0)
		CharState.AT_BOOKSHELF: return randf_range(3.0, 5.0)
		CharState.AT_TEA: return randf_range(2.0, 4.0)
		CharState.AT_CABINET: return randf_range(2.0, 4.0)
		CharState.AT_PLANT: return randf_range(2.0, 3.0)
		CharState.AT_FISH_TANK: return randf_range(3.0, 5.0)
		CharState.WANDERING: return randf_range(1.0, 2.0)
		_: return 2.0


# === ПЕРСОНАЖ: отрисовка (всегда стоит, масштаб ~200px) ===
func _draw_character() -> void:
	var cx := int(_char_x)
	var foot_y := int(CHAR_FLOOR_Y)
	var b := sin(_breath_timer) * 1.5
	## Масштаб персонажа (1.7x от базовых значений)
	var S := 1.7

	# Анимация шага
	var leg_swing: float = 0.0
	var arm_swing: float = 0.0
	if _char_state == CharState.WALKING:
		leg_swing = sin(_walk_cycle) * 12.0
		arm_swing = sin(_walk_cycle + PI) * 10.0

	# Тело стоя (~200px выше пола)
	var body_top := foot_y - int(120 * S)
	if _char_state == CharState.WALKING:
		body_top -= int(absf(sin(_walk_cycle)) * 3.0)

	var leg_h := int(80 * S)   # Длина ног
	var leg_w := int(14 * S)   # Ширина ноги
	var shoe_h := int(10 * S)
	var torso_w := int(28 * S) # Полуширина торса
	var torso_h := int(70 * S) # Высота торса
	var arm_w := int(12 * S)   # Ширина руки
	var arm_h := int(50 * S)   # Длина руки
	var hand := int(14 * S)    # Размер кисти

	# Ноги
	var pants := Color(0.3, 0.28, 0.25)
	var shoe := Color(0.2, 0.15, 0.1)
	var leg_top := foot_y - leg_h
	draw_rect(Rect2(cx - int(15 * S), leg_top - leg_swing, leg_w, leg_h - shoe_h), pants)
	draw_rect(Rect2(cx - int(17 * S), foot_y - shoe_h - leg_swing, int(18 * S), shoe_h), shoe)
	draw_rect(Rect2(cx + int(3 * S), leg_top + leg_swing, leg_w, leg_h - shoe_h), pants)
	draw_rect(Rect2(cx + int(1 * S), foot_y - shoe_h + leg_swing, int(18 * S), shoe_h), shoe)

	# Торс
	draw_rect(Rect2(cx - torso_w, body_top + b, torso_w * 2, torso_h), SHIRT)
	draw_rect(Rect2(cx - torso_w + int(5 * S), body_top + int(4 * S) + b, torso_w * 2 - int(10 * S), torso_h - int(6 * S)), VEST)

	# Руки — зависят от состояния
	var la_x := cx - torso_w - arm_w  # Левая рука x
	var ra_x := cx + torso_w          # Правая рука x
	match _char_state:
		CharState.AT_WINDOW, CharState.AT_FISH_TANK:
			# Руки за спиной
			draw_rect(Rect2(cx - int(12 * S), body_top + int(45 * S) + b, int(24 * S), int(14 * S)), VEST)
			draw_rect(Rect2(cx - int(10 * S), body_top + int(47 * S) + b, int(20 * S), int(12 * S)), SKIN)
		CharState.AT_BOOKSHELF:
			# Левая вдоль тела, правая тянется вверх
			draw_rect(Rect2(la_x, body_top + int(10 * S) + b, arm_w, arm_h), SHIRT)
			draw_rect(Rect2(la_x - 2, body_top + int(10 * S) + arm_h + b, hand, hand), SKIN)
			draw_rect(Rect2(ra_x, body_top - int(15 * S) + b, arm_w, int(40 * S)), SHIRT)
			draw_rect(Rect2(ra_x, body_top - int(20 * S) + b, hand, hand), SKIN)
		CharState.AT_TEA:
			# Левая вдоль тела, правая держит чашку
			draw_rect(Rect2(la_x, body_top + int(10 * S) + b, arm_w, arm_h), SHIRT)
			draw_rect(Rect2(la_x - 2, body_top + int(10 * S) + arm_h + b, hand, hand), SKIN)
			draw_rect(Rect2(ra_x, body_top + int(18 * S) + b, arm_w, int(35 * S)), SHIRT)
			draw_rect(Rect2(ra_x, body_top + int(50 * S) + b, hand, hand), SKIN)
			# Чашка
			draw_rect(Rect2(ra_x + 2, body_top + int(46 * S) + b, int(16 * S), int(14 * S)), Color(0.9, 0.88, 0.82))
			draw_rect(Rect2(ra_x + 4, body_top + int(48 * S) + b, int(12 * S), int(10 * S)), Color(0.55, 0.35, 0.18))
		CharState.AT_CABINET:
			draw_rect(Rect2(la_x, body_top + int(10 * S) + b, arm_w, arm_h), SHIRT)
			draw_rect(Rect2(la_x - 2, body_top + int(10 * S) + arm_h + b, hand, hand), SKIN)
			var reach := sin(_char_anim * 2.0) * 6.0
			draw_rect(Rect2(ra_x, body_top + int(28 * S) + b + reach, arm_w, int(30 * S)), SHIRT)
			draw_rect(Rect2(ra_x + 6, body_top + int(28 * S) + b + reach, hand, hand), SKIN)
		CharState.AT_PLANT:
			draw_rect(Rect2(la_x, body_top + int(10 * S) + b, arm_w, arm_h), SHIRT)
			draw_rect(Rect2(la_x - 2, body_top + int(10 * S) + arm_h + b, hand, hand), SKIN)
			draw_rect(Rect2(ra_x, body_top + int(15 * S) + b, arm_w, int(35 * S)), SHIRT)
			draw_rect(Rect2(ra_x, body_top + int(12 * S) + b, hand, hand), SKIN)
			# Лейка
			draw_rect(Rect2(ra_x + hand, body_top + int(10 * S) + b, int(20 * S), int(12 * S)), Color(0.5, 0.5, 0.52))
			draw_rect(Rect2(ra_x + hand + int(18 * S), body_top + int(14 * S) + b, int(10 * S), 4), Color(0.5, 0.5, 0.52))
		_:
			# Обычные руки (ходьба/стояние)
			draw_rect(Rect2(la_x, body_top + int(10 * S) + b - arm_swing, arm_w, arm_h), SHIRT)
			draw_rect(Rect2(la_x - 2, body_top + int(10 * S) + arm_h + b - arm_swing, hand, hand), SKIN)
			draw_rect(Rect2(ra_x, body_top + int(10 * S) + b + arm_swing, arm_w, arm_h), SHIRT)
			draw_rect(Rect2(ra_x, body_top + int(10 * S) + arm_h + b + arm_swing, hand, hand), SKIN)

	# Голова
	var head_tilt: float = 0.0
	var look_up: bool = false
	match _char_state:
		CharState.AT_WINDOW:
			look_up = true
			head_tilt = sin(_char_anim * 0.5) * 4.0
		CharState.AT_FISH_TANK:
			head_tilt = sin(_char_anim * 0.8) * 5.0
		CharState.WANDERING:
			head_tilt = sin(_char_anim * 0.6) * 6.0

	_draw_head(cx, body_top - int(50 * S) + b, head_tilt, look_up, S)


func _draw_head(cx: int, hy: float, hx_off: float, look_up: bool = false, S: float = 1.0) -> void:
	## Общая отрисовка головы (масштабируемая)
	var head_y := hy - 5.0 if look_up else hy
	var hw := int(22 * S)  # Полуширина головы
	var hh := int(55 * S)  # Высота головы
	# Шея
	draw_rect(Rect2(cx - int(7 * S) + hx_off, head_y + hh - int(10 * S), int(14 * S), int(14 * S)), SKIN)
	# Голова
	draw_rect(Rect2(cx - hw + hx_off, head_y, hw * 2, hh - int(12 * S)), SKIN)
	# Волосы
	draw_rect(Rect2(cx - hw - int(2 * S) + hx_off, head_y - int(4 * S), hw * 2 + int(4 * S), int(10 * S)), HAIR)
	draw_rect(Rect2(cx - hw - int(2 * S) + hx_off, head_y - int(4 * S), int(8 * S), int(28 * S)), HAIR)
	draw_rect(Rect2(cx + hw - int(6 * S) + hx_off, head_y - int(4 * S), int(8 * S), int(28 * S)), HAIR)
	# Уши
	draw_rect(Rect2(cx - hw - int(4 * S) + hx_off, head_y + int(10 * S), int(6 * S), int(14 * S)), SKIN.darkened(0.08))
	draw_rect(Rect2(cx + hw - int(2 * S) + hx_off, head_y + int(10 * S), int(6 * S), int(14 * S)), SKIN.darkened(0.08))
	# Очки
	var glass_r := int(10 * S)
	draw_arc(Vector2(cx - int(6 * S) + hx_off, head_y + int(16 * S)), glass_r, 0, TAU, 20, GLASS_RIM, int(2 * S))
	draw_arc(Vector2(cx + int(14 * S) + hx_off, head_y + int(16 * S)), glass_r, 0, TAU, 20, GLASS_RIM, int(2 * S))
	draw_rect(Rect2(cx + int(3 * S) + hx_off, head_y + int(15 * S), int(3 * S), int(3 * S)), GLASS_RIM)
	draw_line(Vector2(cx - int(16 * S) + hx_off, head_y + int(16 * S)), Vector2(cx - hw - int(3 * S) + hx_off, head_y + int(12 * S)), GLASS_RIM, 2)
	draw_line(Vector2(cx + int(24 * S) + hx_off, head_y + int(16 * S)), Vector2(cx + hw + int(3 * S) + hx_off, head_y + int(12 * S)), GLASS_RIM, 2)
	# Блики
	draw_rect(Rect2(cx - int(9 * S) + hx_off, head_y + int(12 * S), int(3 * S), int(3 * S)), Color(1, 1, 1, 0.15))
	draw_rect(Rect2(cx + int(11 * S) + hx_off, head_y + int(12 * S), int(3 * S), int(3 * S)), Color(1, 1, 1, 0.15))
	# Глаза
	var eye_y := head_y + int(14 * S) if look_up else head_y + int(16 * S)
	draw_rect(Rect2(cx - int(7 * S) + hx_off, eye_y, int(4 * S), int(4 * S)), Color(0.25, 0.2, 0.15))
	draw_rect(Rect2(cx + int(13 * S) + hx_off, eye_y, int(4 * S), int(4 * S)), Color(0.25, 0.2, 0.15))
	# Нос
	draw_rect(Rect2(cx + int(2 * S) + hx_off, head_y + int(22 * S), int(8 * S), int(12 * S)), SKIN.darkened(0.08))
	# Борода
	for i in range(12):
		var bw := int((18 - i) * S)
		draw_rect(Rect2(cx - bw + int(5 * S) + hx_off, head_y + int(36 * S) + int(float(i) * 3.5 * S), bw * 2, int(3.5 * S)), HAIR)
	# Брови
	var brow_y := head_y + int(6 * S) if look_up else head_y + int(8 * S)
	draw_rect(Rect2(cx - int(10 * S) + hx_off, brow_y, int(10 * S), int(3 * S)), Color(0.6, 0.58, 0.55))
	draw_rect(Rect2(cx + int(9 * S) + hx_off, brow_y, int(10 * S), int(3 * S)), Color(0.6, 0.58, 0.55))


# === АКВАРИУМ (на стене, между правым шкафом и кабинетом) ===
func _draw_fish_tank() -> void:
	var tx := 1580
	var ty := 300
	var tw := 100
	var th := 70
	var owned := GameManager.tool_levels.has("eq_fish_tank")
	# Полка на стене (кронштейн)
	draw_rect(Rect2(tx - 10, ty + th, tw + 20, 6), SHELF_DARK)
	draw_rect(Rect2(tx - 6, ty + th + 6, 8, 12), SHELF_DARK)  # Левая опора
	draw_rect(Rect2(tx + tw - 2, ty + th + 6, 8, 12), SHELF_DARK)  # Правая опора
	# Рамка аквариума
	draw_rect(Rect2(tx - 4, ty - 4, tw + 8, th + 8), DESK_DARK)
	# Стекло (тусклее если не куплен)
	var glass_alpha := 1.0 if owned else 0.4
	draw_rect(Rect2(tx, ty, tw, th), Color(0.2, 0.35, 0.5, glass_alpha))
	# Вода (пустая если не куплен)
	draw_rect(Rect2(tx + 2, ty + 6, tw - 4, th - 8), Color(0.25, 0.45, 0.65, 0.35 if owned else 0.1))
	# Гравий
	for gx in range(tx + 4, tx + tw - 4, 6):
		draw_rect(Rect2(gx, ty + th - 10, 5, 4), Color(0.5, 0.4, 0.25, 0.5 if owned else 0.2))
	if not owned:
		return
	# Растение (только если куплен)
	draw_rect(Rect2(tx + 12, ty + 30, 4, 30), Color(0.2, 0.5, 0.2))
	draw_rect(Rect2(tx + 8, ty + 28, 12, 6), Color(0.3, 0.6, 0.3))
	draw_rect(Rect2(tx + 10, ty + 38, 8, 5), Color(0.25, 0.55, 0.25))
	# Рыбки
	for fish: Dictionary in _fish_data:
		var fx: float = tx + fish["x"] + sin(_breath_timer * fish["speed"] + fish["phase"]) * 20.0
		var fy: float = ty + fish["y"] + cos(_breath_timer * fish["speed"] * 0.7 + fish["phase"]) * 5.0
		fx = clampf(fx, tx + 8, tx + tw - 12)
		fy = clampf(fy, ty + 10, ty + th - 14)
		var fs: float = fish["size"]
		var fc: Color = fish["color"]
		# Тело рыбки (овал из 2 прямоугольников)
		draw_rect(Rect2(fx - fs, fy - fs * 0.4, fs * 2, fs * 0.8), fc)
		# Хвост
		var tail_dir := -1.0 if sin(_breath_timer * fish["speed"] + fish["phase"]) > 0 else 1.0
		draw_rect(Rect2(fx + fs * tail_dir, fy - fs * 0.3, fs * 0.6 * tail_dir, fs * 0.6), fc.darkened(0.15))
		# Глаз
		draw_rect(Rect2(fx - fs * 0.4 * tail_dir, fy - 1, 2, 2), Color(0.1, 0.1, 0.1))
	# Пузырьки
	for bi in 3:
		var bx := tx + 70 + bi * 10
		var by_off := fmod(_breath_timer * 15.0 + float(bi) * 20.0, float(th - 15))
		var by := ty + th - 10 - by_off
		if by > ty + 5:
			draw_circle(Vector2(bx, by), 2, Color(0.7, 0.85, 1, 0.4))


# === КОВЁР ===
func _draw_rug() -> void:
	draw_rect(Rect2(350, 590, 450, 90), RUG)
	draw_rect(Rect2(356, 596, 438, 78), RUG_PATTERN)
	draw_rect(Rect2(364, 604, 422, 62), RUG)
	for i in range(6):
		draw_rect(Rect2(390 + i * 65, 625, 22, 22), RUG_PATTERN)


# === ШКАФ ===
func _draw_filing_cabinet() -> void:
	var fx := 1420
	var fy := 380
	draw_rect(Rect2(fx, fy, 60, 140), Color(0.4, 0.38, 0.35))
	draw_rect(Rect2(fx + 2, fy + 2, 56, 136), Color(0.5, 0.48, 0.44))
	for i in range(4):
		var dy := fy + 5 + i * 33
		draw_rect(Rect2(fx + 5, dy, 50, 28), Color(0.45, 0.43, 0.4))
		draw_rect(Rect2(fx + 20, dy + 11, 20, 5), BRASS)


# === ВЕШАЛКА ===
func _draw_coat_rack() -> void:
	var rx := 1850
	var ry := 350
	# Стойка
	draw_rect(Rect2(rx - 4, ry, 8, 210), DESK_DARK)
	# Основание
	draw_rect(Rect2(rx - 20, ry + 200, 40, 8), DESK_DARK)
	# Крючки
	draw_rect(Rect2(rx - 18, ry + 10, 14, 4), BRASS)
	draw_rect(Rect2(rx + 4, ry + 10, 14, 4), BRASS)
	# Пальто (висит на крючке)
	draw_rect(Rect2(rx - 22, ry + 14, 20, 80), Color(0.25, 0.22, 0.2))
	# Шарф
	draw_rect(Rect2(rx + 6, ry + 14, 8, 50), Color(0.55, 0.2, 0.2))


# === РАСТЕНИЕ (побольше) ===
func _draw_potted_plant() -> void:
	var px := 1780
	var py := 440
	# Горшок (крупнее)
	draw_rect(Rect2(px - 22, py + 10, 44, 45), Color(0.6, 0.35, 0.2))
	draw_rect(Rect2(px - 25, py + 6, 50, 8), Color(0.55, 0.3, 0.18))
	draw_rect(Rect2(px - 18, py + 8, 36, 6), Color(0.3, 0.2, 0.12))
	# Листья (больше и пышнее)
	for i in range(7):
		var angle := float(i) * 0.9 - 1.5
		var lx := px + int(cos(angle) * 28)
		var ly := py - 5 + int(sin(angle) * 15) - i * 7
		draw_rect(Rect2(lx - 12, ly, 24, 12), GREEN)
		draw_rect(Rect2(lx - 10, ly + 3, 20, 6), GREEN_DARK)


# === ЗОНТ ===
func _draw_umbrella_stand() -> void:
	var ux := 80
	var uy := 460
	draw_rect(Rect2(ux - 14, uy, 28, 55), Color(0.35, 0.3, 0.25))
	draw_rect(Rect2(ux - 16, uy - 3, 32, 6), BRASS)
	draw_line(Vector2(ux - 4, uy - 5), Vector2(ux - 15, uy - 60), Color(0.2, 0.18, 0.15), 3)
	draw_arc(Vector2(ux - 15, uy - 65), 6, PI * 0.5, PI * 1.5, 8, Color(0.5, 0.3, 0.15), 3)


# === СТОЛИК С ЧАШКОЙ (правая сторона пола, вид спереди) ===
func _draw_side_table() -> void:
	var tx := 1100
	var ty := 480  # Верх столешницы
	var tw := 60  # Ширина
	var th := 6  # Толщина столешницы
	var leg_h := 40  # Высота ножек
	# Ножки (две, вид спереди)
	draw_rect(Rect2(tx - 24, ty + th, 8, leg_h), DESK_DARK)
	draw_rect(Rect2(tx + 16, ty + th, 8, leg_h), DESK_DARK)
	# Столешница
	draw_rect(Rect2(tx - 30, ty, tw, th), DESK)
	draw_rect(Rect2(tx - 30, ty, tw, 2), DESK_TOP)
	# Полка между ножками
	draw_rect(Rect2(tx - 22, ty + th + 22, 44, 4), DESK_DARK)
	# Чашка с чаем
	draw_rect(Rect2(tx - 12, ty - 16, 24, 16), Color(0.9, 0.88, 0.82))
	draw_rect(Rect2(tx - 10, ty - 14, 20, 12), Color(0.55, 0.35, 0.18))
	# Ручка чашки
	draw_rect(Rect2(tx + 12, ty - 12, 6, 10), Color(0.85, 0.82, 0.78))
	# Блюдце
	draw_rect(Rect2(tx - 16, ty - 2, 32, 4), Color(0.88, 0.85, 0.8))
	# Пар
	var steam_off := sin(_breath_timer * 1.5) * 2
	draw_line(Vector2(tx - 3, ty - 18), Vector2(tx - 5, ty - 30 + steam_off), Color(1, 1, 1, 0.12), 2)
	draw_line(Vector2(tx + 3, ty - 18), Vector2(tx + 5, ty - 32 + steam_off), Color(1, 1, 1, 0.10), 2)
