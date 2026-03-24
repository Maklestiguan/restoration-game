extends HBoxContainer
## Shows current money and worker income rate with payout timer.

@onready var amount_label: Label = $AmountLabel
@onready var income_label: Label = $IncomeLabel

var _payout_timer: float = 0.0


func _ready() -> void:
	Events.money_changed.connect(_on_money_changed)
	_on_money_changed(GameManager.money)


func _process(delta: float) -> void:
	var worker_count := GameManager.hired_workers.size()
	if worker_count == 0:
		income_label.text = ""
		return

	var config := GameManager.economy_config as EconomyConfig
	var income_per_min: float = 50.0
	if config:
		income_per_min = config.worker_income_per_min
	var total_per_min := float(worker_count) * income_per_min

	var per_sec := total_per_min / 60.0
	if per_sec > 0:
		_payout_timer += delta
		var secs_per_dollar := 1.0 / per_sec
		var next_in := secs_per_dollar - fmod(_payout_timer, secs_per_dollar)
		income_label.text = "+$%s/min  next: %.1fs" % [Format.money(total_per_min), next_in]


func _on_money_changed(new_amount: float) -> void:
	amount_label.text = "$%s" % Format.money(new_amount)
	amount_label.tooltip_text = Format.full(new_amount)
