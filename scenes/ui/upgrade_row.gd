extends HBoxContainer
## Строка улучшения инструмента в панели улучшений.

var tool_data: ToolData = null

@onready var name_label: Label = $NameLabel
@onready var level_label: Label = $LevelLabel
@onready var effect_label: Label = $EffectLabel
@onready var cost_label: Label = $CostLabel
@onready var buy_button: Button = $BuyButton


func setup(data: ToolData) -> void:
	tool_data = data
	name_label.text = data.display_name
	buy_button.pressed.connect(_on_buy_pressed)
	Events.tool_upgraded.connect(_on_tool_upgraded)
	Events.money_changed.connect(_on_money_changed)
	_update_display()


func _on_buy_pressed() -> void:
	if tool_data:
		GameManager.upgrade_tool(tool_data)


func _on_tool_upgraded(upgraded_tool: ToolData, _new_level: int) -> void:
	if tool_data and upgraded_tool.id == tool_data.id:
		_update_display()


func _on_money_changed(_amount: float) -> void:
	_update_button_state()


func _update_display() -> void:
	if tool_data == null:
		return
	var level := GameManager.get_tool_level(tool_data.id)
	level_label.text = "Lv. %d" % level
	var strength := GameManager.get_tool_effectiveness(tool_data)
	var radius := GameManager.get_tool_radius(tool_data)
	effect_label.text = "Str: %.1f  Rad: %d" % [strength, radius]

	if level >= tool_data.max_level:
		cost_label.text = "MAX"
		buy_button.disabled = true
		buy_button.text = "--"
	else:
		var cost := GameManager.get_upgrade_cost(tool_data)
		cost_label.text = "$%s" % Format.money(cost)
		buy_button.text = "Upgrade"
		_update_button_state()


func _update_button_state() -> void:
	if tool_data == null:
		return
	var level := GameManager.get_tool_level(tool_data.id)
	if level >= tool_data.max_level:
		buy_button.disabled = true
		return
	var cost := GameManager.get_upgrade_cost(tool_data)
	buy_button.disabled = GameManager.money < cost


