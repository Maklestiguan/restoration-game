extends VBoxContainer
## Investments panel — passive income sources that compound.
## Three investment tiers: Savings, Bonds, Stocks.

const INVESTMENTS := [
	{"id": "savings", "name": "Savings Account", "base_cost": 1000.0, "income": 10.0, "scaling": 1.08, "desc": "Safe and steady. $10/min per level."},
	{"id": "bonds", "name": "Restoration Bonds", "base_cost": 10000.0, "income": 120.0, "scaling": 1.12, "desc": "Government-backed. $120/min per level."},
	{"id": "stocks", "name": "Antique Market Shares", "base_cost": 100000.0, "income": 1500.0, "scaling": 1.15, "desc": "Volatile but rewarding. $1,500/min per level."},
]

var content: VBoxContainer
var _refresh_timer: float = 0.0


func _ready() -> void:
	content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(content)
	Events.money_changed.connect(func(_a: float) -> void: _refresh_buttons())
	Events.game_loaded.connect(_rebuild)
	_rebuild()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 2.0:
		_refresh_timer = 0.0
		_refresh_buttons()
		_update_piggy_display()


var _piggy_balance_label: Label = null
var _piggy_time_label: Label = null
var _piggy_withdraw_btn: Button = null
var _deposit_buttons: Array[Button] = []


func _rebuild() -> void:
	for child in content.get_children():
		child.queue_free()
	_piggy_balance_label = null
	_piggy_time_label = null
	_piggy_withdraw_btn = null
	_deposit_buttons.clear()

	for inv: Dictionary in INVESTMENTS:
		var id: String = inv["id"]
		var level: int = GameManager.tool_levels.get("inv_" + id, 0)

		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		content.add_child(hbox)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.mouse_filter = Control.MOUSE_FILTER_PASS
		hbox.add_child(info)

		var name_label := Label.new()
		name_label.text = "%s (Lv. %d)" % [inv["name"], level]
		name_label.add_theme_font_size_override("font_size", 19)
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(name_label)

		var desc_label := Label.new()
		var income_val: float = inv["income"]
		if level > 0:
			desc_label.text = "%s  Income: $%s/min" % [inv["desc"], Format.money(income_val * float(level))]
		else:
			desc_label.text = inv["desc"]
		desc_label.add_theme_font_size_override("font_size", 15)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.67, 0.6))
		desc_label.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(desc_label)

		var cost: float = _get_cost(inv, level)
		var buy_btn := Button.new()
		buy_btn.text = "Buy $%s" % Format.money(cost)
		buy_btn.custom_minimum_size = Vector2(160, 40)
		buy_btn.disabled = GameManager.money < cost
		buy_btn.pressed.connect(_on_buy.bind(id, inv))
		hbox.add_child(buy_btn)

	# --- Piggy Bank section (всегда показываем) ---
	_build_piggy_bank_section()


func _build_piggy_bank_section() -> void:
	var owned := GameManager.tool_levels.has("eq_piggy_bank")

	var sep := HSeparator.new()
	content.add_child(sep)

	var title := Label.new()
	title.text = "PIGGY BANK"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.75))
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(title)

	if not owned:
		var locked := Label.new()
		locked.text = "Buy Piggy Bank from Equipment tab to unlock savings."
		locked.add_theme_font_size_override("font_size", 15)
		locked.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
		locked.mouse_filter = Control.MOUSE_FILTER_PASS
		content.add_child(locked)
		return

	_piggy_balance_label = Label.new()
	_piggy_balance_label.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(_piggy_balance_label)

	_piggy_time_label = Label.new()
	_piggy_time_label.add_theme_font_size_override("font_size", 15)
	_piggy_time_label.add_theme_color_override("font_color", Color(0.7, 0.67, 0.6))
	_piggy_time_label.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(_piggy_time_label)

	# Deposit buttons
	var dep_hbox := HBoxContainer.new()
	dep_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(dep_hbox)
	_deposit_buttons.clear()
	for amount in [100.0, 1000.0, 10000.0]:
		var btn := Button.new()
		btn.text = "Deposit $%s" % Format.money(amount)
		btn.custom_minimum_size = Vector2(140, 36)
		btn.pressed.connect(_on_piggy_deposit.bind(amount))
		dep_hbox.add_child(btn)
		_deposit_buttons.append(btn)

	# Withdraw button
	_piggy_withdraw_btn = Button.new()
	_piggy_withdraw_btn.custom_minimum_size = Vector2(200, 40)
	_piggy_withdraw_btn.pressed.connect(_on_piggy_withdraw)
	content.add_child(_piggy_withdraw_btn)

	_update_piggy_display()


func _update_piggy_display() -> void:
	if _piggy_balance_label == null:
		return
	var balance: float = GameManager.piggy_bank_balance
	var deposited: float = GameManager.piggy_bank_deposited
	var profit: float = maxf(balance - deposited, 0.0)

	if balance > 0:
		_piggy_balance_label.text = "Balance: $%s  (profit: +$%s)" % [Format.money(balance), Format.money(profit)]
	else:
		_piggy_balance_label.text = "Balance: $0  —  Deposit money to earn 2%/min compound interest."

	var elapsed := 0.0
	if GameManager.piggy_bank_deposit_time > 0:
		elapsed = Time.get_unix_time_from_system() - GameManager.piggy_bank_deposit_time
	var mins := int(elapsed / 60.0)
	var secs := int(elapsed) % 60
	if balance > 0:
		if elapsed < 300.0:
			_piggy_time_label.text = "Time: %dm %ds  (10%% penalty for %ds more)" % [mins, secs, int(300.0 - elapsed)]
		else:
			_piggy_time_label.text = "Time: %dm %ds  (mature — no penalty!)" % [mins, secs]
	else:
		_piggy_time_label.text = ""

	# Update deposit button states
	for i in _deposit_buttons.size():
		var amounts := [100.0, 1000.0, 10000.0]
		if i < amounts.size():
			_deposit_buttons[i].disabled = GameManager.money < amounts[i]

	# Withdraw button
	if balance > 0:
		if elapsed < 300.0:
			var penalty_amount: float = balance * 0.1
			var payout: float = balance - penalty_amount
			_piggy_withdraw_btn.text = "Withdraw $%s (-$%s penalty)" % [Format.money(payout), Format.money(penalty_amount)]
		else:
			_piggy_withdraw_btn.text = "Withdraw $%s (full)" % Format.money(balance)
		_piggy_withdraw_btn.disabled = false
	else:
		_piggy_withdraw_btn.text = "Nothing to withdraw"
		_piggy_withdraw_btn.disabled = true


func _on_piggy_deposit(amount: float) -> void:
	if GameManager.spend_money(amount, "piggy_deposit"):
		GameManager.piggy_bank_balance += amount
		GameManager.piggy_bank_deposited += amount
		if GameManager.piggy_bank_deposit_time <= 0:
			GameManager.piggy_bank_deposit_time = Time.get_unix_time_from_system()
		_update_piggy_display()


func _on_piggy_withdraw() -> void:
	var balance: float = GameManager.piggy_bank_balance
	if balance <= 0:
		return
	var elapsed: float = Time.get_unix_time_from_system() - GameManager.piggy_bank_deposit_time
	var payout: float = balance
	if elapsed < 300.0:
		payout *= 0.9  # 10% penalty
	GameManager.piggy_bank_balance = 0.0
	GameManager.piggy_bank_deposit_time = 0.0
	GameManager.piggy_bank_deposited = 0.0
	GameManager.add_money(payout, "piggy_withdraw")
	_update_piggy_display()


func _on_buy(id: String, inv: Dictionary) -> void:
	var level: int = GameManager.tool_levels.get("inv_" + id, 0)
	var cost: float = _get_cost(inv, level)
	if GameManager.spend_money(cost, "investment"):
		GameManager.tool_levels["inv_" + id] = level + 1
		_rebuild()


func _get_cost(inv: Dictionary, level: int) -> float:
	var base: float = inv["base_cost"]
	var scaling: float = inv["scaling"]
	return base * pow(scaling, level)


func _refresh_buttons() -> void:
	# Quick update of button disabled states without full rebuild
	var idx := 0
	for child in content.get_children():
		if child is HBoxContainer and idx < INVESTMENTS.size():
			var inv: Dictionary = INVESTMENTS[idx]
			var id: String = inv["id"]
			var level: int = GameManager.tool_levels.get("inv_" + id, 0)
			var cost: float = _get_cost(inv, level)
			var btn: Button = child.get_child(1) as Button
			if btn:
				btn.disabled = GameManager.money < cost
				btn.text = "Buy $%s" % Format.money(cost)
			idx += 1


static func get_total_investment_income() -> float:
	## Общий доход от всех инвестиций ($/мин).
	var total := 0.0
	for inv: Dictionary in INVESTMENTS:
		var id: String = inv["id"]
		var level: int = GameManager.tool_levels.get("inv_" + id, 0)
		var income: float = inv["income"]
		total += income * float(level)
	return total
