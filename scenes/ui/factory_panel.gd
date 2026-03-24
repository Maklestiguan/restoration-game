extends VBoxContainer
## Factories — build in cities, earn income, fight bureaucracy with attorneys.
## No negative cash flow. Bureaucracy starts at -25%, attorneys push it to +25%.

const CITIES := [
	{"id": "moscow", "name": "Moscow", "cost": 500000.0, "income": 10000.0},
	{"id": "berlin", "name": "Berlin", "cost": 2000000.0, "income": 40000.0},
	{"id": "tokyo", "name": "Tokyo", "cost": 8000000.0, "income": 150000.0},
	{"id": "new_york", "name": "New York", "cost": 30000000.0, "income": 500000.0},
	{"id": "london", "name": "London", "cost": 100000000.0, "income": 2000000.0},
]

const ATTORNEY_BASE_COST := 50000.0
const ATTORNEY_SCALING := 1.3
const BUREAU_START := -0.25  # -25%
const BUREAU_PER_ATTORNEY := 0.05  # +5% per attorney level
const MAX_ATTORNEY_LEVEL := 10  # -25% to +25%


func _ready() -> void:
	Events.money_changed.connect(func(_a: float) -> void: _update_buttons())
	Events.game_loaded.connect(_rebuild)
	Events.tier_unlocked.connect(func(_t: int) -> void: _rebuild())
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		if child.name != "Header":
			child.queue_free()

	if GameManager.current_tier < 3:
		var locked := Label.new()
		locked.text = "Unlock Tier 3 to build restoration factories."
		add_child(locked)
		return

	for i in CITIES.size():
		var city: Dictionary = CITIES[i]
		var id: String = city["id"]
		var built: bool = GameManager.tool_levels.has("fac_" + id)
		var atty_level: int = GameManager.tool_levels.get("atty_" + id, 0)

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(panel)

		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_child(hbox)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.mouse_filter = Control.MOUSE_FILTER_PASS
		hbox.add_child(info)

		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 19)
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(name_label)

		var detail_label := Label.new()
		detail_label.add_theme_font_size_override("font_size", 15)
		detail_label.add_theme_color_override("font_color", Color(0.7, 0.67, 0.6))
		detail_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(detail_label)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(170, 40)
		hbox.add_child(btn)

		if not built:
			# Можно строить только по порядку
			var can_build: bool = (i == 0) or GameManager.tool_levels.has("fac_" + CITIES[i - 1]["id"])
			var cost: float = city["cost"]
			name_label.text = "%s Factory" % city["name"]
			detail_label.text = "Gross: $%s/min" % Format.money(city["income"])
			btn.text = "Build $%s" % Format.money(cost)
			btn.disabled = not can_build or GameManager.money < cost
			btn.pressed.connect(_on_build.bind(id, city))
		else:
			var bureau_mult := BUREAU_START + float(atty_level) * BUREAU_PER_ATTORNEY
			var net_income: float = city["income"] * (1.0 + bureau_mult)
			var bureau_pct := int(bureau_mult * 100)
			var bureau_str := "+%d%%" % bureau_pct if bureau_pct >= 0 else "%d%%" % bureau_pct
			name_label.text = "%s Factory" % city["name"]
			detail_label.text = "Net: $%s/min (bureau: %s)" % [Format.money(net_income), bureau_str]

			if atty_level >= MAX_ATTORNEY_LEVEL:
				btn.text = "MAX ATTORNEYS"
				btn.disabled = true
			else:
				var atty_cost := ATTORNEY_BASE_COST * pow(ATTORNEY_SCALING, atty_level)
				btn.text = "Attorney $%s" % Format.money(atty_cost)
				btn.disabled = GameManager.money < atty_cost
				btn.pressed.connect(_on_hire_attorney.bind(id, atty_cost))


func _on_build(id: String, city: Dictionary) -> void:
	var cost: float = city["cost"]
	if GameManager.spend_money(cost, "factory"):
		GameManager.tool_levels["fac_" + id] = 1
		_rebuild()


func _on_hire_attorney(id: String, cost: float) -> void:
	if GameManager.spend_money(cost, "attorney"):
		var key := "atty_" + id
		GameManager.tool_levels[key] = GameManager.tool_levels.get(key, 0) + 1
		_rebuild()


func _update_buttons() -> void:
	_rebuild()  # Простой подход — перестроить при изменении денег


## Общий доход от всех фабрик (с учётом бюрократии).
static func get_total_factory_income() -> float:
	var total := 0.0
	for city: Dictionary in CITIES:
		var id: String = city["id"]
		if GameManager.tool_levels.has("fac_" + id):
			var atty_level: int = GameManager.tool_levels.get("atty_" + id, 0)
			var bureau_mult := BUREAU_START + float(atty_level) * BUREAU_PER_ATTORNEY
			total += city["income"] * (1.0 + bureau_mult)
	return total
