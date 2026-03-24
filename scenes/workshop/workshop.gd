extends Node2D
## Основная сцена мастерской.
## Управляет центральной областью с предметом и координирует UI.

const RestorationItemScene := preload("res://scenes/restoration/restoration_item.tscn")

var restoration_item: Control = null

@onready var item_container: Control = $ItemBorder/ItemContainer
@onready var item_name_label: Label = $ItemNameLabel


func _ready() -> void:
	add_to_group("workshop")
	Events.item_restored.connect(_on_item_restored)
	# Генерируем первый предмет
	_spawn_next_item()


func _spawn_next_item() -> void:
	# Убираем предыдущий предмет
	if restoration_item:
		restoration_item.queue_free()
		restoration_item = null

	var item_data := GameManager.generate_next_item()
	if item_data == null:
		return

	restoration_item = RestorationItemScene.instantiate()
	item_container.add_child(restoration_item)
	restoration_item.setup_item(item_data)

	# Обновляем название с звёздами сложности
	var stars := "★".repeat(item_data.get_difficulty())
	item_name_label.text = "%s  %s" % [item_data.display_name, stars]
	_update_rarity_color(item_data.rarity)


func _on_item_restored(_item: Resource, _reward: float, _masterwork: bool) -> void:
	# Следующий предмет после закрытия попапа
	pass


func request_next_item() -> void:
	_spawn_next_item()


func load_specific_item(item_data: ItemData) -> void:
	## Загружает конкретный предмет (для квестов прогрессии).
	if restoration_item:
		restoration_item.queue_free()
		restoration_item = null

	GameManager.current_item = item_data

	restoration_item = RestorationItemScene.instantiate()
	item_container.add_child(restoration_item)
	restoration_item.setup_item(item_data)

	var stars := "★".repeat(item_data.get_difficulty())
	item_name_label.text = "%s  %s" % [item_data.display_name, stars]
	_update_rarity_color(item_data.rarity)


func _update_rarity_color(rarity: int) -> void:
	match rarity:
		0: item_name_label.modulate = Color.WHITE            # COMMON
		1: item_name_label.modulate = Color(0.3, 0.8, 0.3)  # UNCOMMON
		2: item_name_label.modulate = Color(0.3, 0.5, 1.0)  # RARE
		3: item_name_label.modulate = Color(0.7, 0.3, 0.9)  # EPIC
		4: item_name_label.modulate = Color(1.0, 0.8, 0.2)  # LEGENDARY
