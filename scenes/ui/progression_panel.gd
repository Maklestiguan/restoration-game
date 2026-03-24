extends VBoxContainer
## Progression tab — buy licenses to unlock higher tier items.
## Shows current tier items and what next tier unlocks.

enum State { IDLE, LICENSE_AVAILABLE, QUEST_ACTIVE, COMPLETED }

var _state: int = State.IDLE
var _quest_item: ItemData = null

@onready var tier_label: Label = $TierLabel
@onready var current_items_label: Label = $CurrentItemsLabel
@onready var next_items_label: Label = $NextItemsLabel
@onready var description_label: Label = $DescriptionLabel
@onready var cost_label: Label = $CostLabel
@onready var action_button: Button = $ActionButton
@onready var quest_info: Label = $QuestInfo


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)
	Events.money_changed.connect(_on_money_changed)
	Events.item_restored.connect(_on_item_restored)
	Events.game_loaded.connect(_on_game_loaded)
	_update_display()


func _on_game_loaded() -> void:
	_update_display()


func _on_money_changed(_amount: float) -> void:
	_update_button_state()


func _on_action_pressed() -> void:
	match _state:
		State.LICENSE_AVAILABLE:
			_buy_license()
		State.QUEST_ACTIVE:
			_start_quest_restoration()
		_:
			_update_display()


func _buy_license() -> void:
	var cost := _get_license_cost()
	if GameManager.spend_money(cost, "license"):
		_state = State.QUEST_ACTIVE
		_quest_item = _generate_quest_item()
		_update_display()


func _on_item_restored(item_data: Resource, _reward: float, _masterwork: bool) -> void:
	if _state == State.QUEST_ACTIVE and item_data == _quest_item:
		GameManager.current_tier += 1
		Events.tier_unlocked.emit(GameManager.current_tier)
		_state = State.IDLE
		_quest_item = null
		_update_display()


func _generate_quest_item() -> ItemData:
	var pool := GameManager.item_pool as ItemPool
	if pool == null:
		return null
	var base_item := pool.roll_item(GameManager.current_tier)
	if base_item == null:
		return null
	var quest := base_item.duplicate() as ItemData
	quest.display_name = "[QUEST] " + quest.display_name
	quest.base_reward *= 3.0
	for i in quest.damage_layers.size():
		var layer := quest.damage_layers[i].duplicate() as DamageLayer
		layer.depth = mini(layer.depth + 2, 5)
		quest.damage_layers[i] = layer
	return quest


func _start_quest_restoration() -> void:
	if _quest_item == null:
		return
	var workshop := get_tree().get_first_node_in_group("workshop")
	if workshop:
		workshop.load_specific_item(_quest_item)


func _get_license_cost() -> float:
	var config := GameManager.economy_config as EconomyConfig
	if config == null:
		return 99999.0
	var next_tier := GameManager.current_tier + 1
	if next_tier < config.tier_unlock_costs.size():
		return config.tier_unlock_costs[next_tier]
	return config.tier_unlock_costs[-1] * pow(3.0, next_tier - config.tier_unlock_costs.size() + 1)


func _get_items_for_tier(tier: int) -> Array[ItemData]:
	var pool := GameManager.item_pool as ItemPool
	if pool == null:
		return []
	var all_tiers: Array[Array] = [pool.tier_1_items, pool.tier_2_items]
	if tier >= 1 and tier <= all_tiers.size():
		var result: Array[ItemData] = []
		for item: ItemData in all_tiers[tier - 1]:
			result.append(item)
		return result
	return []


func _format_item_list(items: Array[ItemData]) -> String:
	if items.is_empty():
		return "No items yet"
	var names: Array[String] = []
	for item: ItemData in items:
		var stars := "★".repeat(item.get_difficulty())
		var rarity_tag := ""
		match item.rarity:
			1: rarity_tag = "[U]"
			2: rarity_tag = "[R]"
			3: rarity_tag = "[E]"
			4: rarity_tag = "[L]"
		names.append("%s %s %s $%s" % [item.display_name, stars, rarity_tag, Format.money(item.base_reward)])
	return "\n".join(names)


func _update_display() -> void:
	var current := GameManager.current_tier
	tier_label.text = "Current Tier: %d / 8" % current

	# Показываем предметы текущего тира
	var current_items := _get_items_for_tier(current)
	if current_items.is_empty():
		current_items_label.text = "Tier %d items: All available items" % current
	else:
		current_items_label.text = "Tier %d items:\n%s" % [current, _format_item_list(current_items)]

	if current >= 8:
		_state = State.COMPLETED
		next_items_label.text = ""
		description_label.text = "Maximum tier reached! You are a Grand Master Restorer."
		cost_label.text = ""
		action_button.visible = false
		quest_info.text = ""
		return

	# Показываем предметы следующего тира
	var next_items := _get_items_for_tier(current + 1)
	if next_items.is_empty():
		next_items_label.text = "Tier %d unlocks: New challenging items!" % (current + 1)
	else:
		next_items_label.text = "Tier %d unlocks:\n%s" % [current + 1, _format_item_list(next_items)]

	var cost := _get_license_cost()

	match _state:
		State.IDLE, State.LICENSE_AVAILABLE:
			_state = State.LICENSE_AVAILABLE
			description_label.text = "Buy a Tier %d License to access harder, more rewarding items." % (current + 1)
			cost_label.text = "License cost: $%s" % Format.money(cost)
			action_button.text = "Buy License ($%s)" % Format.money(cost)
			action_button.visible = true
			quest_info.text = "After buying, complete a special quest item to earn your diploma."
			_update_button_state()

		State.QUEST_ACTIVE:
			description_label.text = "Complete the quest to earn your Tier %d Diploma!" % (current + 1)
			cost_label.text = ""
			action_button.text = "Start Quest"
			action_button.visible = true
			if _quest_item:
				var stars := "★".repeat(_quest_item.get_difficulty())
				quest_info.text = "Quest: Restore \"%s\" %s (3x reward!)" % [_quest_item.display_name, stars]

		State.COMPLETED:
			description_label.text = "Maximum tier reached!"
			cost_label.text = ""
			action_button.visible = false
			quest_info.text = ""


func _update_button_state() -> void:
	match _state:
		State.LICENSE_AVAILABLE:
			action_button.disabled = GameManager.money < _get_license_cost()
		State.QUEST_ACTIVE:
			action_button.disabled = _quest_item == null
		_:
			action_button.disabled = true
