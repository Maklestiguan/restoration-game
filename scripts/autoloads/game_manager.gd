extends Node
## Центральное хранилище состояния игры.
## Все изменения данных проходят через методы этого класса.

# --- Экономика ---
var money: float = 0.0
var total_money_earned: float = 0.0
var items_restored: int = 0

# --- Уровни инструментов (ключ = tool_id, значение = уровень) ---
var tool_levels: Dictionary = {}

# --- Работники ---
var hired_workers: Array = []

# --- Текущий предмет реставрации ---
var current_item: Resource = null
var current_damage_remaining: Dictionary = {}

# --- Прогрессия ---
var current_tier: int = 1
var unlocked_item_categories: Array[String] = ["common"]

# --- Ссылки на ресурсы (загружаются при старте) ---
var economy_config: Resource = null
var item_pool: Resource = null
var all_tools: Array = []
var all_damage_types: Array = []


func _ready() -> void:
	_load_resources()


func _load_resources() -> void:
	economy_config = load("res://data/resources/economy_config.tres")
	item_pool = load("res://data/resources/item_pool.tres")

	# Загружаем все инструменты
	for file in DirAccess.get_files_at("res://data/resources/tools/"):
		if file.ends_with(".tres"):
			var tool_res := load("res://data/resources/tools/" + file)
			if tool_res:
				all_tools.append(tool_res)
				if not tool_levels.has(tool_res.id):
					tool_levels[tool_res.id] = 1

	# Загружаем все типы повреждений
	for file in DirAccess.get_files_at("res://data/resources/damage_types/"):
		if file.ends_with(".tres"):
			var dmg_res := load("res://data/resources/damage_types/" + file)
			if dmg_res:
				all_damage_types.append(dmg_res)

	if economy_config:
		money = economy_config.starting_money


func generate_next_item() -> ItemData:
	if item_pool == null:
		return null
	var item: ItemData = item_pool.roll_item(current_tier)
	current_item = item
	return item


func get_damage_type(damage_type_id: String) -> DamageTypeData:
	for dt in all_damage_types:
		if dt.id == damage_type_id:
			return dt
	return null


func add_money(amount: float, source: String = "restore") -> void:
	money += amount
	total_money_earned += amount
	Events.money_changed.emit(money)
	Events.money_earned.emit(amount, source)


func spend_money(amount: float, purpose: String = "upgrade") -> bool:
	if money < amount:
		return false
	money -= amount
	Events.money_changed.emit(money)
	Events.money_spent.emit(amount, purpose)
	return true


func get_tool_level(tool_id: String) -> int:
	return tool_levels.get(tool_id, 1)


func upgrade_tool(tool_data: Resource) -> bool:
	var level := get_tool_level(tool_data.id)
	if level >= tool_data.max_level:
		return false
	var cost := _calculate_upgrade_cost(tool_data, level)
	if not spend_money(cost, "tool_upgrade"):
		return false
	tool_levels[tool_data.id] = level + 1
	Events.tool_upgraded.emit(tool_data, level + 1)
	return true


func get_tool_effectiveness(tool_data: Resource) -> float:
	var level := get_tool_level(tool_data.id)
	return tool_data.base_strength * (1.0 + tool_data.strength_per_level * (level - 1))


func get_tool_radius(tool_data: Resource) -> int:
	var level := get_tool_level(tool_data.id)
	return tool_data.base_radius + tool_data.radius_per_level * (level - 1)


func get_upgrade_cost(tool_data: Resource) -> float:
	var level := get_tool_level(tool_data.id)
	return _calculate_upgrade_cost(tool_data, level)


func _calculate_upgrade_cost(tool_data: Resource, level: int) -> float:
	return tool_data.upgrade_cost_base * pow(tool_data.upgrade_cost_scaling, level - 1)


func calculate_item_reward(item_data: Resource, _is_manual: bool) -> float:
	## Рассчитывает базовую награду за предмет (без "Рука мастера").
	## Бонус "Рука мастера" применяется отдельно в месте вызова.
	var base: float = item_data.base_reward
	var rarity_mult: float = _get_rarity_multiplier(item_data.rarity)
	var tier_bonus: float = 1.0

	if economy_config:
		tier_bonus = 1.0 + (current_tier - 1) * economy_config.tier_reward_scaling

	var reward := base * rarity_mult * tier_bonus

	if economy_config:
		reward *= economy_config.global_income_multiplier

	return reward


func roll_masters_touch() -> bool:
	## Проверяет, сработала ли "Рука мастера" (только для ручной реставрации).
	if economy_config == null:
		return false
	return randf() < economy_config.masters_touch_chance


func _get_rarity_multiplier(rarity: int) -> float:
	if economy_config == null:
		return 1.0
	match rarity:
		0: return economy_config.reward_mult_common
		1: return economy_config.reward_mult_uncommon
		2: return economy_config.reward_mult_rare
		3: return economy_config.reward_mult_epic
		4: return economy_config.reward_mult_legendary
		_: return economy_config.reward_mult_common
