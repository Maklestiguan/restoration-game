extends Node
## Passive income system — workers + investments.

var _accumulated_money: float = 0.0

const InvestmentsPanel := preload("res://scenes/ui/investments_panel.gd")
const FactoryPanel := preload("res://scenes/ui/factory_panel.gd")


func _process(delta: float) -> void:
	var config := GameManager.economy_config as EconomyConfig
	var income_per_min: float = 0.0

	# Worker income
	var worker_count := GameManager.hired_workers.size()
	if worker_count > 0:
		var worker_rate: float = 50.0
		if config:
			worker_rate = config.worker_income_per_min
		var cat_mult: float = GameManager.get_worker_income_multiplier()
		income_per_min += float(worker_count) * worker_rate * cat_mult

	# Investment income
	income_per_min += InvestmentsPanel.get_total_investment_income()

	# Factory income
	income_per_min += FactoryPanel.get_total_factory_income()

	if income_per_min <= 0.0:
		return

	var income_per_sec: float = income_per_min / 60.0
	_accumulated_money += income_per_sec * delta

	if _accumulated_money >= 1.0:
		var payout := floorf(_accumulated_money)
		_accumulated_money -= payout
		GameManager.add_money(payout, "passive")
