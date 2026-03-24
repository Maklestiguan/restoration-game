extends Node
## Worker auto-income system.
## Each worker earns a flat $/min. No item generation, just constant income.

var _accumulated_money: float = 0.0


func _process(delta: float) -> void:
	var worker_count := GameManager.hired_workers.size()
	if worker_count == 0:
		return

	var config := GameManager.economy_config as EconomyConfig
	var income_per_min: float = 50.0
	if config:
		income_per_min = config.worker_income_per_min

	# $/sec = count * income_per_min / 60
	var income_per_sec := float(worker_count) * income_per_min / 60.0
	_accumulated_money += income_per_sec * delta

	# Pay out in chunks of $1+ to avoid spamming signals
	if _accumulated_money >= 1.0:
		var payout := floorf(_accumulated_money)
		_accumulated_money -= payout
		GameManager.add_money(payout, "worker")
