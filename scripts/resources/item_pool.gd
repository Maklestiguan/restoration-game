class_name ItemPool
extends Resource
## Пул предметов для генерации. Содержит списки предметов по тирам
## и веса редкости для случайного выбора.

## Предметы 1-го тира (ручная реставрация)
@export var tier_1_items: Array[ItemData] = []

## Предметы 2-го тира (студенты)
@export var tier_2_items: Array[ItemData] = []

## Веса редкости для случайного выбора (чем больше вес, тем чаще выпадает)
@export var rarity_weight_common: float = 60.0
@export var rarity_weight_uncommon: float = 25.0
@export var rarity_weight_rare: float = 10.0
@export var rarity_weight_epic: float = 4.0
@export var rarity_weight_legendary: float = 1.0


func roll_item(tier: int) -> ItemData:
	var pool := _get_pool_for_tier(tier)
	if pool.is_empty():
		return null

	# Собираем веса по редкости
	var weighted_items: Array[ItemData] = []
	var weights: Array[float] = []

	for item in pool:
		weighted_items.append(item)
		weights.append(_get_rarity_weight(item.rarity))

	# Взвешенный случайный выбор
	var total_weight := 0.0
	for w in weights:
		total_weight += w

	var roll := randf() * total_weight
	var cumulative := 0.0
	for i in range(weighted_items.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return weighted_items[i]

	return weighted_items[-1]


func _get_pool_for_tier(tier: int) -> Array[ItemData]:
	# Все предметы до текущего тира включительно
	var result: Array[ItemData] = []
	if tier >= 1:
		result.append_array(tier_1_items)
	if tier >= 2:
		result.append_array(tier_2_items)
	return result


func _get_rarity_weight(rarity: ItemData.Rarity) -> float:
	match rarity:
		ItemData.Rarity.COMMON: return rarity_weight_common
		ItemData.Rarity.UNCOMMON: return rarity_weight_uncommon
		ItemData.Rarity.RARE: return rarity_weight_rare
		ItemData.Rarity.EPIC: return rarity_weight_epic
		ItemData.Rarity.LEGENDARY: return rarity_weight_legendary
		_: return rarity_weight_common
