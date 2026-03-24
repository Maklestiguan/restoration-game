extends Node2D
## Кот-компаньон на полу кабинета. Ходит, прыгает, борется, взаимодействует.
## Живёт в области CAT_AREA (определена в office_background.gd).

enum State { IDLE, WALK, JUMP, STRUGGLE, INTERACT, VISIT }

var cat_level: int = 0
var _state: int = State.IDLE
var _timer: float = 0.0
var _speed: float = 40.0
var _direction: float = 1.0

# Прыжок
var _jump_vel: float = 0.0
var _base_y: float = 0.0
var _jump_offset: float = 0.0

# Борьба после прыжка
var _struggle_wobble: float = 0.0

# Область кота на полу (из office_background)
var _area := Rect2(150, 580, 500, 100)

# Позиции предметов комфорта (в локальных координатах области)
const COMFORT_ITEMS := {
	1: {"name": "Cardboard Box", "x": 50.0},
	2: {"name": "Carpet", "x": 150.0},
	3: {"name": "Scratching Post", "x": 250.0},
	5: {"name": "Cat Tower", "x": 350.0},
	7: {"name": "Food Dispenser", "x": 420.0},
	10: {"name": "Cat Bed", "x": 100.0},
	15: {"name": "Fish Tank", "x": 300.0},
	20: {"name": "Cat Palace", "x": 200.0},
}


func _ready() -> void:
	visible = false
	position = Vector2(_area.position.x + 100, _area.position.y + _area.size.y - 20)
	_base_y = position.y


func activate() -> void:
	visible = true
	if cat_level < 1:
		cat_level = 1


func _process(delta: float) -> void:
	if not visible:
		return

	match _state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta)
		State.JUMP:
			_process_jump(delta)
		State.STRUGGLE:
			_process_struggle(delta)
		State.INTERACT:
			_process_interact(delta)
		State.VISIT:
			_process_visit(delta)

	queue_redraw()


func _process_idle(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		# Выбираем случайное действие
		var roll := randf()
		if roll < 0.35:
			_start_walk()
		elif roll < 0.55:
			_start_jump()
		elif roll < 0.75 and _has_comfort_items():
			_start_interact()
		elif roll < 0.85:
			_start_visit()
		else:
			_timer = randf_range(1.0, 3.0)  # Остаёмся в IDLE


func _process_walk(delta: float) -> void:
	position.x += _speed * _direction * delta
	_timer -= delta

	# Границы области
	var min_x := _area.position.x + 20
	var max_x := _area.position.x + _area.size.x - 20
	if position.x > max_x:
		_direction = -1.0
	elif position.x < min_x:
		_direction = 1.0

	if _timer <= 0:
		_state = State.IDLE
		_timer = randf_range(1.5, 4.0)


func _process_jump(delta: float) -> void:
	_jump_vel += 500.0 * delta  # Гравитация
	_jump_offset += _jump_vel * delta

	if _jump_offset >= 0:
		_jump_offset = 0
		position.y = _base_y
		_state = State.STRUGGLE
		_timer = randf_range(0.5, 1.2)
		_struggle_wobble = 0.0
	else:
		position.y = _base_y + _jump_offset


func _process_struggle(delta: float) -> void:
	_timer -= delta
	_struggle_wobble += delta * 15.0
	position.x += sin(_struggle_wobble) * 1.5

	if _timer <= 0:
		_state = State.IDLE
		_timer = randf_range(1.0, 2.5)


func _process_interact(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		_state = State.IDLE
		_timer = randf_range(2.0, 4.0)


func _process_visit(delta: float) -> void:
	# Идёт к столу (y ~520, x ~700)
	var target := Vector2(700, 540)
	var diff := target - position
	if diff.length() < 15:
		_timer -= delta
		if _timer <= 0:
			# Возвращаемся
			_state = State.WALK
			_direction = -1.0 if position.x > _area.get_center().x else 1.0
			_timer = 3.0
			_base_y = _area.position.y + _area.size.y - 20
	else:
		position += diff.normalized() * _speed * 1.5 * delta
		_base_y = position.y


func _start_walk() -> void:
	_state = State.WALK
	_direction = [-1.0, 1.0][randi() % 2]
	_timer = randf_range(2.0, 5.0)
	_speed = 40.0 + float(cat_level) * 2.0


func _start_jump() -> void:
	_state = State.JUMP
	_jump_vel = -250.0 - float(cat_level) * 5.0  # Выше с уровнем
	_jump_offset = 0.0
	_base_y = position.y


func _start_interact() -> void:
	# Идём к ближайшему предмету
	var best_x: float = position.x
	var best_dist: float = 9999.0
	for lvl: int in COMFORT_ITEMS:
		if cat_level >= lvl:
			var item: Dictionary = COMFORT_ITEMS[lvl]
			var ix: float = _area.position.x + item["x"]
			var d: float = absf(position.x - ix)
			if d < best_dist:
				best_dist = d
				best_x = ix

	position.x = lerpf(position.x, best_x, 0.3)
	_state = State.INTERACT
	_timer = randf_range(2.0, 4.0)


func _start_visit() -> void:
	_state = State.VISIT
	_timer = randf_range(1.5, 3.0)


func _has_comfort_items() -> bool:
	for lvl: int in COMFORT_ITEMS:
		if cat_level >= lvl:
			return true
	return false


func _get_cat_scale() -> float:
	return 1.0 + float(mini(cat_level, 20)) * 0.06


func _draw() -> void:
	# Рисуем предметы комфорта в области
	_draw_comfort_items()
	# Рисуем кота
	_draw_cat()


func _draw_cat() -> void:
	var s := _get_cat_scale()
	var facing := 1.0 if _direction >= 0 else -1.0

	var body := Color(0.45, 0.35, 0.25)
	var dark := Color(0.3, 0.22, 0.15)
	var eye := Color(0.3, 0.8, 0.3)

	# Тело
	draw_rect(Rect2(-12 * s, -8 * s, 24 * s, 12 * s), body)
	# Голова
	var hx: float = 10 * s * facing
	draw_rect(Rect2(hx, -14 * s, 12 * s * facing, 12 * s), body)
	# Уши
	draw_rect(Rect2(hx, -18 * s, 4 * s * facing, 5 * s), dark)
	draw_rect(Rect2(hx + 8 * s * facing, -18 * s, 4 * s * facing, 5 * s), dark)
	# Глаза
	draw_rect(Rect2(hx + 3 * s * facing, -12 * s, 2 * s, 2 * s), eye)
	draw_rect(Rect2(hx + 7 * s * facing, -12 * s, 2 * s, 2 * s), eye)
	# Хвост
	draw_rect(Rect2(-16 * s * facing, -12 * s, 5 * s, 4 * s), dark)
	draw_rect(Rect2(-20 * s * facing, -16 * s, 4 * s, 6 * s), dark)
	# Лапы
	draw_rect(Rect2(-8 * s, 4 * s, 4 * s, 4 * s), dark)
	draw_rect(Rect2(4 * s, 4 * s, 4 * s, 4 * s), dark)

	# Эмоции
	if _state == State.INTERACT:
		draw_string(ThemeDB.fallback_font, Vector2(-5, -22 * s), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * s), Color(1, 0.4, 0.4))
	elif _state == State.STRUGGLE:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -22 * s), "!!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * s), Color(1, 0.8, 0.3))
	elif _state == State.IDLE:
		# Иногда мигает
		if fmod(Time.get_ticks_msec() / 1000.0, 4.0) < 0.2:
			draw_rect(Rect2(hx + 3 * s * facing, -12 * s, 2 * s, 2 * s), body)
			draw_rect(Rect2(hx + 7 * s * facing, -12 * s, 2 * s, 2 * s), body)


func _draw_comfort_items() -> void:
	for lvl: int in COMFORT_ITEMS:
		if cat_level < lvl:
			continue
		var item: Dictionary = COMFORT_ITEMS[lvl]
		var ix: float = _area.position.x + item["x"] - position.x
		var iy: float = _area.position.y + _area.size.y - 20 - position.y

		match lvl:
			1:  # Cardboard Box
				draw_rect(Rect2(ix - 12, iy - 4, 24, 12), Color(0.6, 0.45, 0.25))
				draw_rect(Rect2(ix - 12, iy - 4, 24, 3), Color(0.5, 0.35, 0.18))
			2:  # Carpet
				draw_rect(Rect2(ix - 20, iy + 4, 40, 5), Color(0.6, 0.2, 0.2))
			3:  # Scratching Post
				draw_rect(Rect2(ix - 3, iy - 28, 6, 32), Color(0.65, 0.55, 0.35))
				draw_rect(Rect2(ix - 8, iy + 2, 16, 4), Color(0.5, 0.4, 0.25))
			5:  # Cat Tower
				draw_rect(Rect2(ix - 4, iy - 40, 8, 44), Color(0.55, 0.45, 0.3))
				draw_rect(Rect2(ix - 12, iy - 40, 24, 6), Color(0.6, 0.2, 0.2))
				draw_rect(Rect2(ix - 10, iy - 18, 20, 5), Color(0.6, 0.2, 0.2))
			7:  # Food Dispenser
				draw_rect(Rect2(ix - 8, iy - 14, 16, 18), Color(0.7, 0.7, 0.72))
				draw_rect(Rect2(ix - 10, iy + 2, 20, 4), Color(0.6, 0.6, 0.62))
			10:  # Cat Bed
				draw_rect(Rect2(ix - 16, iy - 1, 32, 10), Color(0.4, 0.3, 0.5))
				draw_rect(Rect2(ix - 14, iy + 1, 28, 6), Color(0.55, 0.4, 0.6))
			15:  # Fish Tank
				draw_rect(Rect2(ix - 12, iy - 20, 24, 24), Color(0.3, 0.5, 0.7, 0.5))
				draw_rect(Rect2(ix - 12, iy - 20, 24, 3), Color(0.5, 0.5, 0.52))
			20:  # Cat Palace
				draw_rect(Rect2(ix - 16, iy - 35, 32, 40), Color(0.7, 0.55, 0.25))
				draw_rect(Rect2(ix - 6, iy - 3, 12, 10), Color(0.3, 0.25, 0.18))
				draw_rect(Rect2(ix - 20, iy - 35, 40, 5), Color(0.8, 0.65, 0.3))
