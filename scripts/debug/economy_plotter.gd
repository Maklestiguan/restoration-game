@tool
extends EditorScript
## Отладочный инструмент: выводит таблицу баланса экономики.
## Запускать из редактора Godot: Script → Run (Ctrl+Shift+X)
##
## Показывает для каждого инструмента:
## - Стоимость улучшения на каждом уровне
## - Среднюю награду за предмет на каждом тире
## - Сколько предметов нужно восстановить для улучшения
## - Накопленные расходы


func _run() -> void:
	var config := preload("res://data/resources/economy_config.tres") as EconomyConfig
	if config == null:
		print("ОШИБКА: Не удалось загрузить economy_config.tres")
		return

	_print_tool_curves(config)
	print("")
	_print_tier_rewards(config)
	print("")
	_print_worker_payback(config)


func _print_tool_curves(config: EconomyConfig) -> void:
	var tools_dir := "res://data/resources/tools/"
	var tool_files := ["brush.tres", "cloth.tres", "sandpaper.tres", "chisel.tres", "solvent.tres"]

	for tool_file in tool_files:
		var tool_data := load(tools_dir + tool_file) as ToolData
		if tool_data == null:
			continue

		print("=== %s (%s) ===" % [tool_data.display_name, tool_data.id])
		print("%-6s | %-14s | %-10s | %-10s | %-14s" % [
			"Ур.", "Стоимость", "Сила", "Радиус", "Накоплено"
		])
		print("-".repeat(62))

		var cumulative := 0.0
		for level in range(1, tool_data.max_level + 1):
			var cost := tool_data.upgrade_cost_base * pow(tool_data.upgrade_cost_scaling, level - 1)
			var strength := tool_data.base_strength * (1.0 + tool_data.strength_per_level * (level - 1))
			var radius := tool_data.base_radius + tool_data.radius_per_level * (level - 1)
			cumulative += cost

			print("%-6d | $%-13s | %-10.2f | %-10d | $%-13s" % [
				level,
				_format_number(cost),
				strength,
				radius,
				_format_number(cumulative)
			])
		print("")


func _print_tier_rewards(config: EconomyConfig) -> void:
	print("=== Награды по тирам ===")
	print("%-5s | %-10s | %-12s | %-12s | %-12s | %-12s" % [
		"Тир", "Множ.тира", "Обычный", "Необычный", "Редкий", "Эпический"
	])
	print("-".repeat(72))

	var base_reward := 100.0  # Средняя базовая награда
	for tier in range(1, 9):
		var tier_mult := 1.0 + (tier - 1) * config.tier_reward_scaling
		print("%-5d | %-10.2f | $%-11s | $%-11s | $%-11s | $%-11s" % [
			tier,
			tier_mult,
			_format_number(base_reward * config.reward_mult_common * tier_mult),
			_format_number(base_reward * config.reward_mult_uncommon * tier_mult),
			_format_number(base_reward * config.reward_mult_rare * tier_mult),
			_format_number(base_reward * config.reward_mult_epic * tier_mult),
		])
	print("")


func _print_worker_payback(config: EconomyConfig) -> void:
	print("=== Окупаемость работников ===")
	print("(Средняя награда за обычный предмет на тире 1: $100)")
	print("")

	var avg_reward := 100.0
	var worker_files := DirAccess.get_files_at("res://data/resources/workers/")
	if worker_files.is_empty():
		print("Работники ещё не созданы.")
		return

	for worker_file in worker_files:
		var worker := load("res://data/resources/workers/" + worker_file) as WorkerData
		if worker == null:
			continue
		var income_per_min := worker.restore_speed * avg_reward
		var payback_min := worker.hire_cost / income_per_min if income_per_min > 0 else INF
		print("%s: стоимость $%s, доход $%s/мин, окупаемость %.1f мин" % [
			worker.display_name,
			_format_number(worker.hire_cost),
			_format_number(income_per_min),
			payback_min
		])


func _format_number(value: float) -> String:
	if value >= 1000000:
		return "%.2fM" % (value / 1000000.0)
	elif value >= 1000:
		return "%.1fK" % (value / 1000.0)
	else:
		return "%.0f" % value
