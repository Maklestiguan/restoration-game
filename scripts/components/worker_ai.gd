extends Node
## Passive income system — workers + investments.

var _accumulated_money: float = 0.0

const InvestmentsPanel := preload("res://scenes/ui/investments_panel.gd")
const FactoryPanel := preload("res://scenes/ui/factory_panel.gd")


func _process(delta: float) -> void:
	var config := GameManager.economy_config as EconomyConfig
	var income_per_min: float = 0.0

	# Student income
	var student_count := GameManager.hired_workers.size()
	if student_count > 0:
		var student_rate: float = 50.0
		if config:
			student_rate = config.worker_income_per_min
		var cat_mult: float = GameManager.get_worker_income_multiplier()
		income_per_min += float(student_count) * student_rate * cat_mult

	# Professional income (10x student rate)
	var pro_count: int = GameManager.tool_levels.get("professionals", 0)
	if pro_count > 0:
		var pro_rate: float = 500.0
		var cat_mult_pro: float = GameManager.get_worker_income_multiplier()
		income_per_min += float(pro_count) * pro_rate * cat_mult_pro

	# Investment income
	income_per_min += InvestmentsPanel.get_total_investment_income()

	# Factory income (с бонусом аквариума +15%)
	var factory_income := FactoryPanel.get_total_factory_income()
	if factory_income > 0 and GameManager.tool_levels.has("eq_fish_tank"):
		factory_income *= 1.15
	income_per_min += factory_income

	# Piggy bank compounding (2% в минуту)
	if GameManager.piggy_bank_balance > 0:
		var pb_rate := 0.02  # 2% per minute
		var pb_income: float = GameManager.piggy_bank_balance * pb_rate
		GameManager.piggy_bank_balance += (pb_income / 60.0) * delta

	if income_per_min <= 0.0:
		return

	var income_per_sec: float = income_per_min / 60.0
	_accumulated_money += income_per_sec * delta

	if _accumulated_money >= 1.0:
		var payout := floorf(_accumulated_money)
		_accumulated_money -= payout
		GameManager.add_money(payout, "passive")
