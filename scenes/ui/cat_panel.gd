extends VBoxContainer
## Cat companion panel — buy, upgrade, see comfort items.

const COMFORT_MILESTONES := {
	1: "Cardboard Box",
	2: "Cozy Carpet",
	3: "Scratching Post",
	5: "Cat Tower",
	7: "Auto Food Dispenser",
	10: "Luxury Cat Bed",
	15: "Fish Tank",
	20: "Cat Palace",
}

@onready var status_label: Label = $StatusLabel
@onready var bonuses_label: Label = $BonusesLabel
@onready var items_label: Label = $ItemsLabel
@onready var cost_label: Label = $CostLabel
@onready var action_button: Button = $ActionButton


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)
	Events.money_changed.connect(func(_a: float) -> void: _update_button())
	Events.tier_unlocked.connect(func(_t: int) -> void: _update_display())
	Events.game_loaded.connect(_update_display)
	_update_display()


func _on_action_pressed() -> void:
	if not GameManager.has_cat:
		_buy_cat()
	else:
		_upgrade_cat()


func _buy_cat() -> void:
	var config := GameManager.economy_config as EconomyConfig
	if config == null:
		return
	if GameManager.spend_money(config.cat_base_cost, "cat"):
		GameManager.has_cat = true
		GameManager.cat_level = 1
		var cat_node := get_tree().get_first_node_in_group("cat")
		if cat_node:
			cat_node.activate()
		_update_display()


func _upgrade_cat() -> void:
	var cost := _get_upgrade_cost()
	if GameManager.spend_money(cost, "cat_upgrade"):
		GameManager.cat_level += 1
		var cat_node := get_tree().get_first_node_in_group("cat")
		if cat_node:
			cat_node.cat_level = GameManager.cat_level
		_update_display()


func _get_upgrade_cost() -> float:
	var config := GameManager.economy_config as EconomyConfig
	if config == null:
		return 99999.0
	return config.cat_upgrade_cost_base * pow(config.cat_upgrade_cost_scaling, GameManager.cat_level)


func _update_display() -> void:
	var config := GameManager.economy_config as EconomyConfig
	var available := GameManager.current_tier >= 2

	if not available:
		status_label.text = "Unlock Tier 2 to adopt a workshop cat!"
		bonuses_label.text = ""
		items_label.text = ""
		cost_label.text = ""
		action_button.visible = false
		return

	if not GameManager.has_cat:
		status_label.text = "A stray cat is looking for a home..."
		bonuses_label.text = "Cats bring good luck!\n+1% Master's Touch per level\n+5% worker income per level"
		items_label.text = ""
		var cat_cost: float = config.cat_base_cost if config else 1000.0
		cost_label.text = "Adoption fee: $%s" % Format.money(cat_cost)
		action_button.text = "Adopt Cat ($%s)" % Format.money(cat_cost)
		action_button.visible = true
		_update_button()
		return

	var lvl := GameManager.cat_level
	status_label.text = "Workshop Cat  Lv. %d" % lvl

	# Bonuses
	if config:
		var mt_total: float = (config.masters_touch_chance + lvl * config.cat_masters_touch_per_level) * 100
		var wk_bonus: float = lvl * config.cat_worker_bonus_per_level * 100
		bonuses_label.text = "Master's Touch: %d%%  |  Worker bonus: +%d%%" % [int(mt_total), int(wk_bonus)]

	# Comfort items — show owned and next
	var owned_items: Array[String] = []
	var next_item := ""
	var next_item_level := 0
	for milestone_lvl: int in COMFORT_MILESTONES:
		var item_name: String = COMFORT_MILESTONES[milestone_lvl]
		if lvl >= milestone_lvl:
			owned_items.append(item_name)
		elif next_item.is_empty():
			next_item = item_name
			next_item_level = milestone_lvl

	var items_text := "Comfort: " + ", ".join(owned_items) if not owned_items.is_empty() else "No items yet"
	if not next_item.is_empty():
		items_text += "\nNext: %s (Lv. %d)" % [next_item, next_item_level]
	items_label.text = items_text

	var upgrade_cost := _get_upgrade_cost()
	cost_label.text = "Upgrade to Lv. %d: $%s" % [lvl + 1, Format.money(upgrade_cost)]
	action_button.text = "Upgrade ($%s)" % Format.money(upgrade_cost)
	action_button.visible = true
	_update_button()


func _update_button() -> void:
	if not GameManager.has_cat:
		var config := GameManager.economy_config as EconomyConfig
		var cat_cost: float = config.cat_base_cost if config else 1000.0
		action_button.disabled = GameManager.money < cat_cost
	else:
		action_button.disabled = GameManager.money < _get_upgrade_cost()
