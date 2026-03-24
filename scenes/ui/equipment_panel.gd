extends VBoxContainer
## Equipment shop — buy professional tools that give permanent passive bonuses.
## No auto-processing. Just makes YOUR cleaning easier.

const EQUIPMENT := [
	{"id": "ultrasonic_cleaner", "name": "Ultrasonic Cleaner", "cost": 15000.0, "desc": "-15% rust resistance", "type": "resist", "target": "rust", "value": 0.15},
	{"id": "chemical_bath", "name": "Chemical Bath", "cost": 30000.0, "desc": "-15% grime resistance", "type": "resist", "target": "grime", "value": 0.15},
	{"id": "precision_tools", "name": "Precision Tools", "cost": 50000.0, "desc": "+10% Master's Touch chance", "type": "masters_touch", "target": "", "value": 0.10},
	{"id": "laser_scanner", "name": "Laser Scanner", "cost": 100000.0, "desc": "Show damage % per layer", "type": "qol", "target": "", "value": 0.0},
]

var _buttons: Dictionary = {}


func _ready() -> void:
	Events.money_changed.connect(func(_a: float) -> void: _update_buttons())
	Events.game_loaded.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	_buttons.clear()
	# Remove old dynamic children (keep Header)
	for child in get_children():
		if child.name != "Header":
			child.queue_free()

	if GameManager.current_tier < 3:
		var locked := Label.new()
		locked.text = "Unlock Tier 3 to access professional equipment."
		add_child(locked)
		return

	for eq: Dictionary in EQUIPMENT:
		var id: String = eq["id"]
		var owned: bool = GameManager.tool_levels.has("eq_" + id)

		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(hbox)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.mouse_filter = Control.MOUSE_FILTER_PASS
		hbox.add_child(info)

		var name_label := Label.new()
		name_label.text = eq["name"]
		name_label.add_theme_font_size_override("font_size", 19)
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = eq["desc"]
		desc_label.add_theme_font_size_override("font_size", 15)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.67, 0.6))
		desc_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(desc_label)

		var btn := Button.new()
		if owned:
			btn.text = "OWNED"
			btn.disabled = true
		else:
			var cost: float = eq["cost"]
			btn.text = "Buy $%s" % Format.money(cost)
			btn.disabled = GameManager.money < cost
			btn.pressed.connect(_on_buy.bind(id, eq))
		btn.custom_minimum_size = Vector2(150, 40)
		hbox.add_child(btn)
		_buttons[id] = btn


func _on_buy(id: String, eq: Dictionary) -> void:
	var cost: float = eq["cost"]
	if GameManager.spend_money(cost, "equipment"):
		GameManager.tool_levels["eq_" + id] = 1
		_rebuild()


func _update_buttons() -> void:
	for eq: Dictionary in EQUIPMENT:
		var id: String = eq["id"]
		if id not in _buttons:
			continue
		var btn: Button = _buttons[id]
		var owned: bool = GameManager.tool_levels.has("eq_" + id)
		if owned:
			btn.text = "OWNED"
			btn.disabled = true
		else:
			var cost: float = eq["cost"]
			btn.text = "Buy $%s" % Format.money(cost)
			btn.disabled = GameManager.money < cost


## Проверяет, снижает ли оборудование сопротивление определённого типа повреждений.
static func get_resistance_reduction(damage_type_id: String) -> float:
	var total := 0.0
	for eq: Dictionary in EQUIPMENT:
		if eq["type"] == "resist" and eq["target"] == damage_type_id:
			var id: String = eq["id"]
			if GameManager.tool_levels.has("eq_" + id):
				total += eq["value"]
	return total


## Проверяет, даёт ли оборудование бонус к Master's Touch.
static func get_masters_touch_bonus() -> float:
	var total := 0.0
	for eq: Dictionary in EQUIPMENT:
		if eq["type"] == "masters_touch":
			var id: String = eq["id"]
			if GameManager.tool_levels.has("eq_" + id):
				total += eq["value"]
	return total


## Проверяет, куплен ли лазерный сканер (показ % повреждений).
static func has_laser_scanner() -> bool:
	return GameManager.tool_levels.has("eq_laser_scanner")


## Проверяет, куплено ли всё оборудование.
static func all_owned() -> bool:
	for eq: Dictionary in EQUIPMENT:
		if not GameManager.tool_levels.has("eq_" + eq["id"]):
			return false
	return true
