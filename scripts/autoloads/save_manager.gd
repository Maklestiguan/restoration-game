extends Node
## Система сохранения и загрузки.
## Автосохранение каждые 30 секунд. Расчёт оффлайн-дохода при загрузке.

const SAVE_PATH := "user://savegame.tres"
const AUTOSAVE_INTERVAL := 30.0

var _autosave_timer: Timer


func _ready() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.timeout.connect(_on_autosave)
	_autosave_timer.autostart = true
	add_child(_autosave_timer)


func _on_autosave() -> void:
	save_game()


func save_game() -> void:
	var data := SaveData.new()
	data.save_version = 1
	data.timestamp_unix = Time.get_unix_time_from_system()
	data.money = GameManager.money
	data.total_money_earned = GameManager.total_money_earned
	data.items_restored = GameManager.items_restored
	data.tool_levels = GameManager.tool_levels.duplicate()
	data.current_tier = GameManager.current_tier
	data.unlocked_categories = GameManager.unlocked_item_categories.duplicate()
	data.has_cat = GameManager.has_cat
	data.cat_level = GameManager.cat_level

	# Save worker count (one entry per worker)
	data.hired_worker_ids = []
	for _i in GameManager.hired_workers.size():
		data.hired_worker_ids.append("student")

	# Сохраняем текущий предмет и маски
	if GameManager.current_item:
		data.current_item_id = GameManager.current_item.id
		data.current_damage_remaining = GameManager.current_damage_remaining.duplicate()
		var workshop = get_tree().get_first_node_in_group("workshop")
		if workshop and workshop.restoration_item:
			data.current_mask_data = workshop.restoration_item.serialize_masks()

	var err := ResourceSaver.save(data, SAVE_PATH)
	if err == OK:
		Events.game_saved.emit()
		# На вебе синхронизируем файловую систему с IndexedDB
		if OS.has_feature("web"):
			JavaScriptBridge.eval("if(Module && Module.FS) Module.FS.syncfs(false, function(err){});")


func load_game() -> bool:
	if not ResourceLoader.exists(SAVE_PATH):
		return false

	var data := ResourceLoader.load(SAVE_PATH) as SaveData
	if data == null:
		return false

	# Восстанавливаем состояние
	GameManager.money = data.money
	GameManager.total_money_earned = data.total_money_earned
	GameManager.items_restored = data.items_restored
	GameManager.tool_levels = data.tool_levels.duplicate()
	GameManager.current_tier = data.current_tier
	GameManager.unlocked_item_categories = data.unlocked_categories.duplicate()
	GameManager.has_cat = data.has_cat
	GameManager.cat_level = data.cat_level

	# Activate cat if owned
	if GameManager.has_cat:
		call_deferred("_activate_cat")

	# Restore worker count (each entry = one worker)
	GameManager.hired_workers.clear()
	for _i in data.hired_worker_ids.size():
		GameManager.hired_workers.append(null)

	# Расчёт оффлайн-дохода
	var offline_seconds := Time.get_unix_time_from_system() - data.timestamp_unix
	if offline_seconds > 60.0:
		_calculate_offline_earnings(offline_seconds)

	# Обновляем весь UI — сигналы для каждой подсистемы
	Events.money_changed.emit(GameManager.money)

	# Обновляем отображение инструментов
	for tool_res in GameManager.all_tools:
		var level: int = GameManager.get_tool_level(tool_res.id)
		Events.tool_upgraded.emit(tool_res, level)

	# Обновляем отображение работников (один сигнал чтобы обновить панель)
	if not GameManager.hired_workers.is_empty():
		Events.worker_hired.emit(null)

	Events.game_loaded.emit()
	return true


func _activate_cat() -> void:
	var cat_node := get_tree().get_first_node_in_group("cat")
	if cat_node:
		cat_node.activate()
		cat_node.cat_level = GameManager.cat_level


func _calculate_offline_earnings(seconds: float) -> void:
	var config := GameManager.economy_config as EconomyConfig
	if config == null:
		return

	# Ограничиваем максимальное оффлайн-время
	seconds = minf(seconds, config.max_offline_seconds)

	var total_earnings := 0.0

	# Worker income
	var worker_count := GameManager.hired_workers.size()
	if worker_count > 0:
		var cat_mult: float = GameManager.get_worker_income_multiplier()
		var income_per_sec: float = float(worker_count) * config.worker_income_per_min / 60.0 * cat_mult
		total_earnings += income_per_sec * seconds * config.offline_efficiency

	# Investment income
	var InvestmentsPanel := preload("res://scenes/ui/investments_panel.gd")
	var invest_per_min: float = InvestmentsPanel.get_total_investment_income()
	if invest_per_min > 0:
		total_earnings += invest_per_min / 60.0 * seconds * config.offline_efficiency

	if total_earnings > 0:
		GameManager.add_money(total_earnings, "offline")
		Events.offline_earnings_calculated.emit(total_earnings, seconds)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
