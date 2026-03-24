extends PanelContainer
## Всплывающее окно завершения реставрации.
## Показывает название предмета, награду и бонус "Рука мастера".

@onready var item_name_label: Label = $VBox/ItemNameLabel
@onready var reward_label: Label = $VBox/RewardLabel
@onready var masterwork_label: Label = $VBox/MasterworkLabel
@onready var next_button: Button = $VBox/NextButton

signal next_item_requested


func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next_pressed)
	Events.item_restored.connect(_on_item_restored)


func _on_item_restored(item_data: Resource, reward: float, is_masterwork: bool) -> void:
	item_name_label.text = item_data.display_name
	reward_label.text = "$%s" % Format.money(reward)

	if is_masterwork:
		masterwork_label.text = "MASTER'S TOUCH! x2"
		masterwork_label.visible = true
	else:
		masterwork_label.visible = false

	visible = true


func _on_next_pressed() -> void:
	visible = false
	next_item_requested.emit()


