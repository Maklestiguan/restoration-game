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
		_row("Chance", "%d%%" % int(config.masters_touch_chance * 100))
		_row("Multiplier", "x%.1f" % config.masters_touch_multiplier)

	_section("ECONOMY")
	if config:
		var tier_mult := 1.0 + (GameManager.current_tier - 1) * config.tier_reward_scaling
		_row("Tier", str(GameManager.current_tier))
		_row("Tier bonus", "x%.2f" % tier_mult)
		_row("Income mult", "x%.2f" % config.global_income_multiplier)

	_section("WORKERS")
	var wc := GameManager.hired_workers.size()
	_row("Students", str(wc))
	if config and wc > 0:
		_row("Income", "$%s/min" % Format.money(float(wc) * config.worker_income_per_min))
		_row("Per worker", "$%s/min" % Format.money(config.worker_income_per_min))
		_row("Offline", "%d%%" % int(config.offline_efficiency * 100))

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
	label.add_theme_font_size_override("font_size", 18)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_child(label)


func _row(left: String, right: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_child(hbox)

	var l := Label.new()
	l.text = left
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 17)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(l)

	var r := Label.new()
	r.text = right
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_theme_font_size_override("font_size", 17)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(r)
