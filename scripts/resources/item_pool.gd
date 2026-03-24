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

	# Собираем веса по редкости (с учётом тира)
	var weighted_items: Array[ItemData] = []
	var weights: Array[float] = []

	for item in pool:
		var w := _get_rarity_weight(item.rarity, tier)
		if w > 0:
			weighted_items.append(item)
			weights.append(w)

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
	## Тиры 1-3: только текущий тир (низкие тиры слишком слабые).
	## Тиры 4+: окно tier-2 до tier.
	var min_tier: int
	if tier <= 3:
		min_tier = tier
	else:
		min_tier = maxi(1, tier - 1)
	var all_tiers: Array[Array] = [tier_1_items, tier_2_items]
	var result: Array[ItemData] = []
	for t in range(min_tier, tier + 1):
		if t >= 1 and t <= all_tiers.size():
			for item: ItemData in all_tiers[t - 1]:
				if item.required_tier <= tier:
					result.append(item)
	if result.is_empty():
		for item: ItemData in tier_1_items:
			result.append(item)
	return result


func _get_rarity_weight(rarity: ItemData.Rarity, tier: int = 1) -> float:
	## Тир 3+: Common исчезает. Тир 4+: Uncommon тоже исчезает.
	match rarity:
		ItemData.Rarity.COMMON:
			if tier >= 3:
				return 0.0
			return rarity_weight_common
		ItemData.Rarity.UNCOMMON:
			if tier >= 4:
				return 0.0
			return rarity_weight_uncommon
		ItemData.Rarity.RARE: return rarity_weight_rare
		ItemData.Rarity.EPIC: return rarity_weight_epic
		ItemData.Rarity.LEGENDARY: return rarity_weight_legendary
		_: return rarity_weight_common
