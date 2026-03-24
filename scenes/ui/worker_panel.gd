extends VBoxContainer
## Worker hiring panel.
## You can hire identical workers; each new one costs more (exponential).
## Each worker adds the same linear amount of restoration speed.

@onready var count_label: Label = $CountLabel
@onready var speed_label: Label = $SpeedLabel
@onready var cost_label: Label = $CostLabel
@onready var hire_button: Button = $HireButton


func _ready() -> void:
	hire_button.pressed.connect(_on_hire_pressed)
	Events.money_changed.connect(_on_money_changed)
	Events.worker_hired.connect(_on_worker_hired)
	_update_display()


func _on_hire_pressed() -> void:
	var cost := _get_hire_cost()
	if GameManager.spend_money(cost, "hire_worker"):
		GameManager.hired_workers.append(null)  # Just track count
		Events.worker_hired.emit(null)
		_update_display()


func _on_money_changed(_amount: float) -> void:
	_update_button_state()


func _on_worker_hired(_w: Variant) -> void:
	_update_display()


func _get_worker_count() -> int:
	return GameManager.hired_workers.size()


func _get_hire_cost() -> float:
	var config := GameManager.economy_config as EconomyConfig
	var base: float = 300.0
	var scaling: float = 1.15
	if config:
		base *= config.global_cost_multiplier
	return base * pow(scaling, _get_worker_count())


func _get_money_per_min() -> float:
	var config := GameManager.economy_config as EconomyConfig
	var income: float = 50.0
	if config:
		income = config.worker_income_per_min
	return float(_get_worker_count()) * income


func _update_display() -> void:
	var count := _get_worker_count()
	count_label.text = "Students hired: %d" % count
	var money_min := _get_money_per_min()
	speed_label.text = "Income: $%s/min" % Format.money(money_min)
	cost_label.text = "Next: $%s" % Format.money(_get_hire_cost())
	_update_button_state()


func _update_button_state() -> void:
	hire_button.disabled = GameManager.money < _get_hire_cost()


