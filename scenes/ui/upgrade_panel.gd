extends VBoxContainer
## Upgrade panel — shows the single tool upgrade.

const UpgradeRowScene := preload("res://scenes/ui/upgrade_row.tscn")


func _ready() -> void:
	if GameManager.all_tools.size() > 0:
		var row := UpgradeRowScene.instantiate()
		add_child(row)
		row.setup(GameManager.all_tools[0])
