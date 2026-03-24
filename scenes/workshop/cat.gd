extends Node2D
## Кот-компаньон на полу кабинета. Ходит по всей комнате, прыгает, спит, следует за хозяином.

enum State { IDLE, WALK, JUMP, STRUGGLE, INTERACT, VISIT, NAP, FOLLOW }

var cat_level: int = 0
var _state: int = State.IDLE
var _timer: float = 0.0
var _speed: float = 40.0
var _direction: float = 1.0

## Прыжок
var _jump_vel: float = 0.0
var _base_y: float = 0.0
var _jump_offset: float = 0.0

## Борьба после прыжка
var _struggle_wobble: float = 0.0

## Область кота на полу — весь пол кабинета
var _area := Rect2(80, 560, 1770, 120)

## Позиции предметов комфорта (распределены по всему полу)
const COMFORT_ITEMS := {
	1: {"name": "Cardboard Box", "x": 100.0},
	2: {"name": "Carpet", "x": 350.0},
	3: {"name": "Scratching Post", "x": 600.0},
	5: {"name": "Cat Tower", "x": 900.0},
	7: {"name": "Food Dispenser", "x": 1200.0},
	10: {"name": "Cat Bed", "x": 250.0},
	15: {"name": "Fish Tank", "x": 1500.0},
	20: {"name": "Cat Palace", "x": 1700.0},
}


func _ready() -> void:
	visible = false
	position = Vector2(_area.position.x + 200, _area.position.y + _area.size.y - 20)
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
		State.NAP:
			_process_nap(delta)
		State.FOLLOW:
			_process_follow(delta)

	queue_redraw()


func _process_idle(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		## Всегда выбираем действие — никогда не остаёмся в IDLE
		var roll := randf()
		if roll < 0.30:
			_start_walk()
		elif roll < 0.45:
			_start_jump()
		elif roll < 0.60:
			if _has_comfort_items():
				_start_interact()
			else:
				_start_walk()
		elif roll < 0.72:
			_start_visit()
		elif roll < 0.82:
			_start_nap()
		else:
			_start_follow()


func _process_walk(delta: float) -> void:
	position.x += _speed * _direction * delta
	_timer -= delta

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
	_jump_vel += 500.0 * delta
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
	var target := Vector2(700, 540)
	var diff := target - position
	if diff.length() < 15:
		_timer -= delta
		if _timer <= 0:
			_state = State.WALK
			_direction = -1.0 if position.x > _area.get_center().x else 1.0
			_timer = 3.0
			_base_y = _area.position.y + _area.size.y - 20
			position.y = _base_y
	else:
		position += diff.normalized() * _speed * 1.5 * delta
		_base_y = position.y


func _process_nap(delta: float) -> void:
	## Кот спит — не двигается, рисует "zzz"
	_timer -= delta
	if _timer <= 0:
		_state = State.IDLE
		_timer = randf_range(2.0, 4.0)


func _process_follow(delta: float) -> void:
	## Идёт к хозяину
	var bg := get_parent().get_node_or_null("OfficeBackground")
	if bg == null:
		_state = State.IDLE
		_timer = 2.0
		return

	var owner_x: float = bg.get_character_x()
	var diff_x := owner_x - position.x
	if absf(diff_x) < 30:
		# Рядом с хозяином — стоим, показываем ♥
		_timer -= delta
		if _timer <= 0:
			_state = State.IDLE
			_timer = randf_range(2.0, 4.0)
	else:
		_direction = 1.0 if diff_x > 0 else -1.0
		position.x += _direction * _speed * 1.2 * delta


func _start_walk() -> void:
	_state = State.WALK
	_direction = [-1.0, 1.0][randi() % 2]
	_timer = randf_range(2.0, 6.0)
	_speed = 40.0 + float(cat_level) * 2.0


func _start_jump() -> void:
	_state = State.JUMP
	_jump_vel = -250.0 - float(cat_level) * 5.0
	_jump_offset = 0.0
	_base_y = position.y


func _start_interact() -> void:
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


func _start_nap() -> void:
	_state = State.NAP
	_timer = randf_range(5.0, 10.0)


func _start_follow() -> void:
	_state = State.FOLLOW
	_timer = randf_range(2.0, 3.0)
	_speed = 40.0 + float(cat_level) * 2.0


func _has_comfort_items() -> bool:
	for lvl: int in COMFORT_ITEMS:
		if cat_level >= lvl:
			return true
	return false


func _get_cat_scale() -> float:
	return 1.8 + float(mini(cat_level, 20)) * 0.06


func _draw() -> void:
	_draw_comfort_items()
	_draw_cat()


func _draw_cat() -> void:
	var s := _get_cat_scale()
	var facing := -1.0 if _direction >= 0 else 1.0

	var body := Color(0.45, 0.35, 0.25)
	var dark := Color(0.3, 0.22, 0.15)
	var eye := Color(0.3, 0.8, 0.3)

	# Спящий кот — лежит
	if _state == State.NAP:
		draw_rect(Rect2(-14 * s, -4 * s, 28 * s, 10 * s), body)
		draw_rect(Rect2(12 * s * facing, -6 * s, 8 * s * facing, 8 * s), body)
		# Закрытые глаза (линии)
		draw_rect(Rect2(14 * s * facing, -4 * s, 3 * s * facing, 1 * s), dark)
		# Хвост свёрнут
		draw_rect(Rect2(-12 * s * facing, -2 * s, 8 * s, 3 * s), dark)
		# zzz
		var zzz_off := sin(Time.get_ticks_msec() / 800.0) * 3.0
		draw_string(ThemeDB.fallback_font, Vector2(-3, -12 * s + zzz_off), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * s), Color(0.7, 0.7, 0.9, 0.6))
		draw_string(ThemeDB.fallback_font, Vector2(5, -16 * s + zzz_off), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * s), Color(0.7, 0.7, 0.9, 0.4))
		return

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
	if _state == State.INTERACT or _state == State.FOLLOW:
		draw_string(ThemeDB.fallback_font, Vector2(-5, -22 * s), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * s), Color(1, 0.4, 0.4))
	elif _state == State.STRUGGLE:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -22 * s), "!!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * s), Color(1, 0.8, 0.3))
	elif _state == State.IDLE:
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
