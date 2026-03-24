extends ScrollContainer
## Stats tab — shows all active bonuses, multipliers, and game stats.
## Uses ScrollContainer so content doesn't overflow the tab.

var _content: VBoxContainer
var _refresh_timer: float = 0.0


func _ready() -> void:
	# ScrollContainer needs mouse to scroll, not block tab switching
	mouse_filter = Control.MOUSE_FILTER_PASS

	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_content)
	_refresh()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 1.0:
		_refresh_timer = 0.0
		_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_section("TOOL")
	if GameManager.all_tools.size() > 0:
		var tool_data: ToolData = GameManager.all_tools[0]
		var level := GameManager.get_tool_level(tool_data.id)
		var strength := GameManager.get_tool_effectiveness(tool_data)
		var radius := GameManager.get_tool_radius(tool_data)
		var cost := GameManager.get_upgrade_cost(tool_data)
		_row("Level", str(level))
		_row("Strength", "%.1f" % strength)
		_row("Radius", "%d px" % radius)
		_row("Next upgrade", "$%s" % Format.money(cost))
		var milestone_bonus := 1.0 + 0.05 * floorf(float(level) / 10.0)
		if milestone_bonus > 1.0:
			_row("Milestone bonus", "+%d%%" % int((milestone_bonus - 1.0) * 100))
		@warning_ignore("integer_division")
		var next_milestone: int = (level / 10 + 1) * 10
		_row("Next milestone", "Lv. %d" % next_milestone)

	_section("MASTER'S TOUCH")
	var config := GameManager.economy_config as EconomyConfig
	if config:
		var base_chance: float = config.masters_touch_chance
		var cat_bonus: float = 0.0
		if GameManager.has_cat:
			cat_bonus = float(GameManager.cat_level) * config.cat_masters_touch_per_level
		var EquipPanel := preload("res://scenes/ui/equipment_panel.gd")
		var equip_bonus: float = EquipPanel.get_masters_touch_bonus()
		var total_chance: float = base_chance + cat_bonus + equip_bonus
		_row("Base chance", "%d%%" % int(base_chance * 100))
		if cat_bonus > 0:
			_row("Cat bonus", "+%d%%" % int(cat_bonus * 100))
		if equip_bonus > 0:
			_row("Equipment bonus", "+%d%%" % int(equip_bonus * 100))
		_row("Total chance", "%d%%" % int(total_chance * 100))
		_row("Multiplier", "x%.1f" % config.masters_touch_multiplier)

	_section("ECONOMY")
	if config:
		var tier_mult := 1.0 + (GameManager.current_tier - 1) * config.tier_reward_scaling
		_row("Tier", str(GameManager.current_tier))
		_row("Tier bonus", "x%.2f" % tier_mult)
		_row("Income mult", "x%.2f" % config.global_income_multiplier)

	_section("WORKERS")
	var wc := GameManager.hired_workers.size()
	var pro_count: int = GameManager.tool_levels.get("professionals", 0)
	_row("Students", str(wc))
	if pro_count > 0:
		_row("Professionals", str(pro_count))
	if config and wc > 0:
		_row("Student income", "$%s/min" % Format.money(float(wc) * config.worker_income_per_min))
	if pro_count > 0:
		_row("Pro income", "$%s/min" % Format.money(float(pro_count) * 500.0))
	if config and (wc > 0 or pro_count > 0):
		_row("Offline", "%d%%" % int(config.offline_efficiency * 100))

	if GameManager.piggy_bank_balance > 0:
		_section("PIGGY BANK")
		_row("Balance", "$%s" % Format.money(GameManager.piggy_bank_balance))

	_section("DIFFICULTY")
	if config:
		var stars: Array[String] = ["★", "★★", "★★★", "★★★★", "★★★★★"]
		for i in config.difficulty_bonus.size():
			_row(stars[i] if i < stars.size() else str(i + 1), "x%.2f" % config.difficulty_bonus[i])

	_section("LIFETIME")
	_row("Earned", "$%s" % Format.money(GameManager.total_money_earned))
	_row("Items", str(GameManager.items_restored))


func _section(title: String) -> void:
	var label := Label.new()
	label.text = "— %s —" % title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	label.add_theme_font_size_override("font_size", 22)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_child(label)


func _row(left: String, right: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_child(hbox)

	var l := Label.new()
	l.text = left
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 20)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(l)

	var r := Label.new()
	r.text = right
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_theme_font_size_override("font_size", 20)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(r)
