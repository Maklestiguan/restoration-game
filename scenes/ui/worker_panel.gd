extends VBoxContainer
## Worker hiring panel — Students and Professionals.
## Students: cheap, linear income. Available from start.
## Professionals: 5x base price, 10x base income. Available from Tier 3.

## --- Базовые параметры студентов ---
const STUDENT_BASE_COST := 300.0
const STUDENT_COST_SCALING := 1.15
const STUDENT_INCOME_PER_MIN := 50.0

## --- Базовые параметры профессионалов (5x цена, 10x доход) ---
const PRO_BASE_COST := 1500.0
const PRO_COST_SCALING := 1.15
const PRO_INCOME_PER_MIN := 500.0

## Кэшированные ссылки на кнопки и метки для обновления без пересоздания
var _student_btn: Button = null
var _pro_btn: Button = null
var _student_count_label: Label = null
var _student_speed_label: Label = null
var _student_cost_label: Label = null
var _pro_count_label: Label = null
var _pro_speed_label: Label = null
var _pro_cost_label: Label = null
var _total_label: Label = null
var _had_pros: bool = false


func _ready() -> void:
	Events.money_changed.connect(func(_a: float) -> void: _update_buttons())
	Events.worker_hired.connect(func(_w: Variant) -> void: _on_hired())
	Events.game_loaded.connect(_rebuild)
	Events.tier_unlocked.connect(func(_t: int) -> void: _rebuild())
	_rebuild()


func _on_hired() -> void:
	_update_labels()
	_update_buttons()


func _rebuild() -> void:
	for child in get_children():
		if child.name != "Header":
			child.queue_free()

	_student_btn = null
	_pro_btn = null
	_had_pros = GameManager.current_tier >= 3

	# Students section
	var s1 := Control.new()
	s1.custom_minimum_size = Vector2(0, 4)
	add_child(s1)

	var st := Label.new()
	st.text = "STUDENTS"
	st.add_theme_font_size_override("font_size", 18)
	st.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	st.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(st)

	_student_count_label = Label.new()
	_student_count_label.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_student_count_label)

	_student_speed_label = Label.new()
	_student_speed_label.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_student_speed_label)

	_student_cost_label = Label.new()
	_student_cost_label.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_student_cost_label)

	_student_btn = Button.new()
	_student_btn.custom_minimum_size = Vector2(220, 45)
	_student_btn.pressed.connect(_on_hire_student)
	add_child(_student_btn)

	# Professionals section (Tier 3+)
	if _had_pros:
		var sep := HSeparator.new()
		add_child(sep)

		var s2 := Control.new()
		s2.custom_minimum_size = Vector2(0, 4)
		add_child(s2)

		var pt := Label.new()
		pt.text = "PROFESSIONALS"
		pt.add_theme_font_size_override("font_size", 18)
		pt.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
		pt.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(pt)

		_pro_count_label = Label.new()
		_pro_count_label.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(_pro_count_label)

		_pro_speed_label = Label.new()
		_pro_speed_label.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(_pro_speed_label)

		_pro_cost_label = Label.new()
		_pro_cost_label.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(_pro_cost_label)

		_pro_btn = Button.new()
		_pro_btn.custom_minimum_size = Vector2(220, 45)
		_pro_btn.pressed.connect(_on_hire_pro)
		add_child(_pro_btn)

	# Total income
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	add_child(spacer)

	_total_label = Label.new()
	_total_label.add_theme_font_size_override("font_size", 19)
	_total_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_total_label.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_total_label)

	_update_labels()
	_update_buttons()


func _update_labels() -> void:
	## Обновляет текст меток без пересоздания узлов.
	if _student_count_label:
		_student_count_label.text = "Students hired: %d" % _get_student_count()
	if _student_speed_label:
		_student_speed_label.text = "Income: $%s/min" % Format.money(_get_student_income())
	if _student_cost_label:
		_student_cost_label.text = "Next: $%s" % Format.money(_get_student_cost())
	if _pro_count_label:
		_pro_count_label.text = "Professionals hired: %d" % _get_pro_count()
	if _pro_speed_label:
		_pro_speed_label.text = "Income: $%s/min" % Format.money(_get_pro_income())
	if _pro_cost_label:
		_pro_cost_label.text = "Next: $%s" % Format.money(_get_pro_cost())
	if _total_label:
		_total_label.text = "Total worker income: $%s/min" % Format.money(get_total_worker_income())


func _update_buttons() -> void:
	## Обновляет только состояние кнопок (disabled/text) без пересоздания.
	if _student_btn:
		var cost := _get_student_cost()
		_student_btn.text = "Hire Student ($%s)" % Format.money(cost)
		_student_btn.disabled = GameManager.money < cost
	if _pro_btn:
		var cost := _get_pro_cost()
		_pro_btn.text = "Hire Professional ($%s)" % Format.money(cost)
		_pro_btn.disabled = GameManager.money < cost


# --- Students ---
func _get_student_count() -> int:
	return GameManager.hired_workers.size()


func _get_student_cost() -> float:
	var config := GameManager.economy_config as EconomyConfig
	var base := STUDENT_BASE_COST
	if config:
		base *= config.global_cost_multiplier
	return base * pow(STUDENT_COST_SCALING, _get_student_count())


func _get_student_income() -> float:
	return float(_get_student_count()) * STUDENT_INCOME_PER_MIN


func _on_hire_student() -> void:
	var cost := _get_student_cost()
	if GameManager.spend_money(cost, "hire_worker"):
		GameManager.hired_workers.append(null)
		Events.worker_hired.emit(null)


# --- Professionals ---
func _get_pro_count() -> int:
	return GameManager.tool_levels.get("professionals", 0)


func _get_pro_cost() -> float:
	var config := GameManager.economy_config as EconomyConfig
	var base := PRO_BASE_COST
	if config:
		base *= config.global_cost_multiplier
	return base * pow(PRO_COST_SCALING, _get_pro_count())


func _get_pro_income() -> float:
	return float(_get_pro_count()) * PRO_INCOME_PER_MIN


func _on_hire_pro() -> void:
	var cost := _get_pro_cost()
	if GameManager.spend_money(cost, "hire_worker"):
		GameManager.tool_levels["professionals"] = _get_pro_count() + 1
		Events.worker_hired.emit(null)


# --- Общий доход ---
static func get_total_worker_income() -> float:
	## Общий доход от всех работников (студенты + профессионалы) в $/мин.
	var student_count := GameManager.hired_workers.size()
	var pro_count: int = GameManager.tool_levels.get("professionals", 0)
	return float(student_count) * STUDENT_INCOME_PER_MIN + float(pro_count) * PRO_INCOME_PER_MIN
