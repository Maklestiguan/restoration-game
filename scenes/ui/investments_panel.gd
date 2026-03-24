extends VBoxContainer
## Investments panel — passive income sources that compound.
## Three investment tiers: Savings, Bonds, Stocks.

const INVESTMENTS := [
	{"id": "savings", "name": "Savings Account", "base_cost": 1000.0, "income": 10.0, "scaling": 1.08, "desc": "Safe and steady. $10/min per level."},
	{"id": "bonds", "name": "Restoration Bonds", "base_cost": 10000.0, "income": 120.0, "scaling": 1.12, "desc": "Government-backed. $120/min per level."},
	{"id": "stocks", "name": "Antique Market Shares", "base_cost": 100000.0, "income": 1500.0, "scaling": 1.15, "desc": "Volatile but rewarding. $1,500/min per level."},
]

var content: VBoxContainer
var _refresh_timer: float = 0.0


func _ready() -> void:
	content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(content)
	Events.money_changed.connect(func(_a: float) -> void: _refresh_buttons())
	Events.game_loaded.connect(_rebuild)
	_rebuild()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 2.0:
		_refresh_timer = 0.0
		_refresh_buttons()


func _rebuild() -> void:
	for child in content.get_children():
		child.queue_free()

	for inv: Dictionary in INVESTMENTS:
		var id: String = inv["id"]
		var level: int = GameManager.tool_levels.get("inv_" + id, 0)

		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		content.add_child(hbox)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.mouse_filter = Control.MOUSE_FILTER_PASS
		hbox.add_child(info)

		var name_label := Label.new()
		name_label.text = "%s (Lv. %d)" % [inv["name"], level]
		name_label.add_theme_font_size_override("font_size", 19)
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(name_label)

		var desc_label := Label.new()
		var income_val: float = inv["income"]
		if level > 0:
			desc_label.text = "%s  Income: $%s/min" % [inv["desc"], Format.money(income_val * float(level))]
		else:
			desc_label.text = inv["desc"]
		desc_label.add_theme_font_size_override("font_size", 15)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.67, 0.6))
		desc_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(desc_label)

		var cost: float = _get_cost(inv, level)
		var buy_btn := Button.new()
		buy_btn.text = "Buy $%s" % Format.money(cost)
		buy_btn.custom_minimum_size = Vector2(160, 40)
		buy_btn.disabled = GameManager.money < cost
		buy_btn.pressed.connect(_on_buy.bind(id, inv))
		hbox.add_child(buy_btn)


func _on_buy(id: String, inv: Dictionary) -> void:
	var level: int = GameManager.tool_levels.get("inv_" + id, 0)
	var cost: float = _get_cost(inv, level)
	if GameManager.spend_money(cost, "investment"):
		GameManager.tool_levels["inv_" + id] = level + 1
		_rebuild()


func _get_cost(inv: Dictionary, level: int) -> float:
	var base: float = inv["base_cost"]
	var scaling: float = inv["scaling"]
	return base * pow(scaling, level)


func _refresh_buttons() -> void:
	# Quick update of button disabled states without full rebuild
	var idx := 0
	for child in content.get_children():
		if child is HBoxContainer and idx < INVESTMENTS.size():
			var inv: Dictionary = INVESTMENTS[idx]
			var id: String = inv["id"]
			var level: int = GameManager.tool_levels.get("inv_" + id, 0)
			var cost: float = _get_cost(inv, level)
			var btn: Button = child.get_child(1) as Button
			if btn:
				btn.disabled = GameManager.money < cost
				btn.text = "Buy $%s" % Format.money(cost)
			idx += 1


static func get_total_investment_income() -> float:
	## Общий доход от всех инвестиций ($/мин).
	var total := 0.0
	for inv: Dictionary in INVESTMENTS:
		var id: String = inv["id"]
		var level: int = GameManager.tool_levels.get("inv_" + id, 0)
		var income: float = inv["income"]
		total += income * float(level)
	return total
