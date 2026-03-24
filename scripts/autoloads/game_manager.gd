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

# --- Кот ---
var has_cat: bool = false
var cat_level: int = 0

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


func upgrade_tool(tool_data: ToolData) -> bool:
	var level := get_tool_level(tool_data.id)
	if level >= tool_data.max_level:
		return false
	var cost := _calculate_upgrade_cost(tool_data, level)
	if not spend_money(cost, "tool_upgrade"):
		return false
	tool_levels[tool_data.id] = level + 1
	Events.tool_upgraded.emit(tool_data, level + 1)
	return true


func get_tool_effectiveness(tool_data: ToolData) -> float:
	var level := get_tool_level(tool_data.id)
	var base := tool_data.base_strength * (1.0 + tool_data.strength_per_level * (level - 1))
	# Бонус за вехи: +5% за каждые 10 уровней
	var milestone_bonus := 1.0 + 0.05 * floorf(float(level) / 10.0)
	return base * milestone_bonus


func get_tool_radius(tool_data: ToolData) -> int:
	var level := get_tool_level(tool_data.id)
	# Радиус растёт, но ограничен 60 (маска 128px, не больше половины)
	return mini(tool_data.base_radius + tool_data.radius_per_level * (level - 1), 60)


func get_upgrade_cost(tool_data: ToolData) -> float:
	var level := get_tool_level(tool_data.id)
	return _calculate_upgrade_cost(tool_data, level)


func _calculate_upgrade_cost(tool_data: ToolData, level: int) -> float:
	return tool_data.upgrade_cost_base * pow(tool_data.upgrade_cost_scaling, level - 1)


func calculate_item_reward(item_data: ItemData, _is_manual: bool) -> float:
	## Рассчитывает базовую награду за предмет (без "Рука мастера").
	## Бонус "Рука мастера" применяется отдельно в месте вызова.
	var base: float = item_data.base_reward
	var rarity_mult: float = _get_rarity_multiplier(item_data.rarity)
	var tier_bonus: float = 1.0

	if economy_config:
		tier_bonus = 1.0 + (current_tier - 1) * economy_config.tier_reward_scaling

	var reward := base * rarity_mult * tier_bonus

	# Бонус за сложность предмета (★ to ★★★★★)
	if economy_config and item_data is ItemData:
		var difficulty: int = item_data.get_difficulty()
		var diff_idx: int = clampi(difficulty - 1, 0, economy_config.difficulty_bonus.size() - 1)
		reward *= economy_config.difficulty_bonus[diff_idx]

	if economy_config:
		reward *= economy_config.global_income_multiplier

	# Рандомизация +/- 10% от базовой цены
	reward *= randf_range(0.9, 1.1)

	return reward


func roll_masters_touch() -> bool:
	## Проверяет, сработала ли "Рука мастера" (только для ручной реставрации).
	## Кот увеличивает шанс на cat_masters_touch_per_level за уровень.
	if economy_config == null:
		return false
	var chance: float = economy_config.masters_touch_chance
	if has_cat and economy_config:
		chance += float(cat_level) * economy_config.cat_masters_touch_per_level
	# Бонус от оборудования
	var EquipmentPanel := preload("res://scenes/ui/equipment_panel.gd")
	chance += EquipmentPanel.get_masters_touch_bonus()
	return randf() < chance


func get_worker_income_multiplier() -> float:
	## Множитель дохода работников (кот добавляет бонус).
	var mult := 1.0
	if has_cat and economy_config:
		mult += float(cat_level) * economy_config.cat_worker_bonus_per_level
	return mult


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
