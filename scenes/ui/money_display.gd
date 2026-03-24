extends HBoxContainer
## Shows current money and total passive income rate.

const InvestmentsPanel := preload("res://scenes/ui/investments_panel.gd")
const FactoryPanel := preload("res://scenes/ui/factory_panel.gd")

@onready var amount_label: Label = $AmountLabel
@onready var income_label: Label = $IncomeLabel

var _payout_timer: float = 0.0


func _ready() -> void:
	Events.money_changed.connect(_on_money_changed)
	_on_money_changed(GameManager.money)


func _process(delta: float) -> void:
	var total_per_min := _get_total_passive_income()

	if total_per_min <= 0.0:
		income_label.text = ""
		return

	var per_sec := total_per_min / 60.0
	_payout_timer += delta
	var secs_per_dollar := 1.0 / per_sec
	var next_in := secs_per_dollar - fmod(_payout_timer, secs_per_dollar)
	income_label.text = "+$%s/min  next: %.1fs" % [Format.money(total_per_min), next_in]


func _get_total_passive_income() -> float:
	var total := 0.0
	# Students
	var config := GameManager.economy_config as EconomyConfig
	var wc := GameManager.hired_workers.size()
	if wc > 0 and config:
		var cat_mult: float = GameManager.get_worker_income_multiplier()
		total += float(wc) * config.worker_income_per_min * cat_mult
	# Professionals
	var pro_count: int = GameManager.tool_levels.get("professionals", 0)
	if pro_count > 0:
		var cat_mult_pro: float = GameManager.get_worker_income_multiplier()
		total += float(pro_count) * 500.0 * cat_mult_pro
	# Investments
	total += InvestmentsPanel.get_total_investment_income()
	# Factories (с бонусом аквариума)
	var factory_income: float = FactoryPanel.get_total_factory_income()
	if factory_income > 0 and GameManager.tool_levels.has("eq_fish_tank"):
		factory_income *= 1.15
	total += factory_income
	return total


func _on_money_changed(new_amount: float) -> void:
	amount_label.text = "$%s" % Format.money(new_amount)
	amount_label.tooltip_text = Format.full(new_amount)
