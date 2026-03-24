extends VBoxContainer
## Tool info sidebar - shows the single restoration tool and its level.

@onready var tool_name: Label = $ToolName
@onready var level_label: Label = $LevelLabel
@onready var strength_label: Label = $StrengthLabel
@onready var radius_label: Label = $RadiusLabel


func _ready() -> void:
	Events.tool_upgraded.connect(_on_tool_upgraded)
	# Auto-select the single tool
	if GameManager.all_tools.size() > 0:
		Events.tool_selected.emit(GameManager.all_tools[0])
	_update_display()


func _on_tool_upgraded(_tool: ToolData, _level: int) -> void:
	_update_display()


func _update_display() -> void:
	if GameManager.all_tools.is_empty():
		return
	var tool_data: ToolData = GameManager.all_tools[0]
	tool_name.text = tool_data.display_name
	var level := GameManager.get_tool_level(tool_data.id)
	level_label.text = "Lv. %d" % level
	var strength := GameManager.get_tool_effectiveness(tool_data)
	var radius := GameManager.get_tool_radius(tool_data)
	strength_label.text = "Strength: %.1f" % strength
	radius_label.text = "Radius: %d" % radius
