@tool
extends EditorScript
## Отладочный инструмент: выводит таблицу баланса экономики.
## Запускать из редактора: Script → Run (Ctrl+Shift+X)
## Результат — в панели Output (внизу редактора).


func _run() -> void:
	print("\n========== ECONOMY BALANCE REPORT ==========\n")

	var config := preload("res://data/resources/economy_config.tres") as EconomyConfig
	if config == null:
		print("ERROR: cannot load economy_config.tres")
		return

	_print_tool_curve()
	print("")
	_print_item_rewards(config)
	print("")
	_print_worker_payback(config)
	print("")
	_print_difficulty_bonuses(config)
	print("\n========== END REPORT ==========\n")


func _print_tool_curve() -> void:
	var tool_data := preload("res://data/resources/tools/restoration_kit.tres") as ToolData
	if tool_data == null:
		print("ERROR: cannot load restoration_kit.tres")
		return

	print("=== TOOL: %s (cost_scaling=%.2f) ===" % [tool_data.display_name, tool_data.upgrade_cost_scaling])
	print("%-8s | %-14s | %-10s | %-8s | %-14s" % [
		"Level", "Upgrade Cost", "Strength", "Radius", "Cumulative"
	])
	print("-".repeat(64))

	var cumulative := 0.0
	var levels_to_show: Array[int] = [1, 2, 3, 5, 10, 20, 50, 100, 200, 500, 1000]
	for level: int in levels_to_show:
		var cost := tool_data.upgrade_cost_base * pow(tool_data.upgrade_cost_scaling, level - 1)
		var strength := tool_data.base_strength * (1.0 + tool_data.strength_per_level * (level - 1))
		# Milestone bonus: +5% per 10 levels
		strength *= 1.0 + 0.05 * floorf(float(level) / 10.0)
		var radius := mini(tool_data.base_radius + tool_data.radius_per_level * (level - 1), 60)
		# Approximate cumulative (geometric series)
		if level <= 1:
			cumulative = cost
		else:
			cumulative = tool_data.upgrade_cost_base * (pow(tool_data.upgrade_cost_scaling, level) - 1.0) / (tool_data.upgrade_cost_scaling - 1.0)

		print("%-8d | $%-13s | %-10.1f | %-8d | $%-13s" % [
			level, _fmt(cost), strength, radius, _fmt(cumulative)
		])


func _print_item_rewards(config: EconomyConfig) -> void:
	print("=== ITEM REWARDS BY RARITY & TIER ===")
	print("%-6s | %-12s | %-12s | %-12s | %-12s | %-12s" % [
		"Tier", "Common", "Uncommon", "Rare", "Epic", "Legendary"
	])
	print("-".repeat(76))

	var base := 100.0
	for tier in range(1, 11):
		var tier_mult := 1.0 + (tier - 1) * config.tier_reward_scaling
		print("%-6d | $%-11s | $%-11s | $%-11s | $%-11s | $%-11s" % [
			tier,
			_fmt(base * config.reward_mult_common * tier_mult),
			_fmt(base * config.reward_mult_uncommon * tier_mult),
			_fmt(base * config.reward_mult_rare * tier_mult),
			_fmt(base * config.reward_mult_epic * tier_mult),
			_fmt(base * config.reward_mult_legendary * tier_mult),
		])


func _print_worker_payback(config: EconomyConfig) -> void:
	print("=== WORKER HIRING COSTS (exponential) ===")
	print("Income per worker: $%s/min" % _fmt(config.worker_income_per_min))
	print("")
	print("%-10s | %-14s | %-14s | %-14s" % [
		"Workers", "Hire Cost", "Total $/min", "Payback (min)"
	])
	print("-".repeat(60))

	var base_cost := 500.0
	var scaling := 1.4
	for count in range(0, 15):
		var cost := base_cost * pow(scaling, count)
		var total_income := float(count + 1) * config.worker_income_per_min
		var payback: float = cost / config.worker_income_per_min if config.worker_income_per_min > 0.0 else 0.0
		print("%-10d | $%-13s | $%-13s | %-14.1f" % [
			count + 1, _fmt(cost), _fmt(total_income), payback
		])


func _print_difficulty_bonuses(config: EconomyConfig) -> void:
	print("=== DIFFICULTY BONUSES ===")
	var stars := ["★", "★★", "★★★", "★★★★", "★★★★★"]
	for i in config.difficulty_bonus.size():
		var label: String = stars[i] if i < stars.size() else str(i + 1)
		print("%s : x%.2f reward" % [label, config.difficulty_bonus[i]])


func _fmt(value: float) -> String:
	if value >= 1e15:
		return "%.2eQ" % (value / 1e15)
	elif value >= 1e12:
		return "%.2fT" % (value / 1e12)
	elif value >= 1e9:
		return "%.2fB" % (value / 1e9)
	elif value >= 1e6:
		return "%.2fM" % (value / 1e6)
	elif value >= 1000:
		return "%.1fK" % (value / 1000.0)
	else:
		return "%.0f" % value
