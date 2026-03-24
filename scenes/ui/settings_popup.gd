extends PanelContainer
## Settings popup — UI scale slider + item box positioning toggle.

@onready var scale_slider: HSlider = $VBox/ScaleSlider
@onready var scale_label: Label = $VBox/ScaleLabel
@onready var close_button: Button = $VBox/CloseButton
@onready var move_toggle: CheckButton = $VBox/MoveToggle
@onready var reset_pos_button: Button = $VBox/ResetPosButton

const SAVE_KEY := "ui_scale"
## Позиция по умолчанию из workshop.tscn
const DEFAULT_ITEM_LEFT := 730.0
const DEFAULT_ITEM_TOP := 60.0
const DEFAULT_ITEM_RIGHT := 1250.0
const DEFAULT_ITEM_BOTTOM := 560.0
var _hud: Control = null


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func() -> void: visible = false)
	scale_slider.min_value = 0.7
	scale_slider.max_value = 1.25
	scale_slider.step = 0.05
	scale_slider.value = _load_scale()
	scale_slider.value_changed.connect(_on_scale_changed)
	move_toggle.toggled.connect(_on_move_toggled)
	reset_pos_button.pressed.connect(_on_reset_pos)
	_update_label()


func setup(hud: Control) -> void:
	_hud = hud
	_apply_scale(scale_slider.value)
	# Загружаем сохранённую позицию ItemBorder
	_load_item_pos()


func _on_scale_changed(value: float) -> void:
	_apply_scale(value)
	_update_label()
	_save_scale(value)


func _apply_scale(value: float) -> void:
	if _hud and _hud.get_tree():
		# Масштабируем размер шрифта темы
		var base_size := int(22.0 * value)
		var btn_size := int(20.0 * value)
		var tab_size := int(20.0 * value)
		if _hud.theme:
			_hud.theme.set_default_font_size(base_size)
			_hud.theme.set_font_size("font_size", "Label", base_size)
			_hud.theme.set_font_size("font_size", "Button", btn_size)
			_hud.theme.set_font_size("font_size", "TabContainer", tab_size)


func _update_label() -> void:
	scale_label.text = "UI Scale: %d%%" % int(scale_slider.value * 100)


func _save_scale(value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", SAVE_KEY, value)
	cfg.save("user://settings.cfg")


func _load_scale() -> float:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		return cfg.get_value("settings", SAVE_KEY, 1.0)
	return 1.0


func _on_reset_pos() -> void:
	var item_border := _get_item_border()
	if item_border == null:
		return
	item_border.offset_left = DEFAULT_ITEM_LEFT
	item_border.offset_top = DEFAULT_ITEM_TOP
	item_border.offset_right = DEFAULT_ITEM_RIGHT
	item_border.offset_bottom = DEFAULT_ITEM_BOTTOM
	var name_label := _get_item_name_label()
	if name_label:
		var w := DEFAULT_ITEM_RIGHT - DEFAULT_ITEM_LEFT
		name_label.offset_left = DEFAULT_ITEM_LEFT
		name_label.offset_top = DEFAULT_ITEM_BOTTOM + 8
		name_label.offset_right = DEFAULT_ITEM_RIGHT
		name_label.offset_bottom = DEFAULT_ITEM_BOTTOM + 28
	# Удаляем сохранённую позицию
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("settings", "item_pos_x", null)
	cfg.set_value("settings", "item_pos_y", null)
	cfg.save("user://settings.cfg")


func _on_move_toggled(enabled: bool) -> void:
	var item_border := _get_item_border()
	if item_border == null:
		return
	if enabled:
		# Включаем перетаскивание
		if not item_border.has_meta("_drag_connected"):
			item_border.gui_input.connect(_on_item_border_input.bind(item_border))
			item_border.set_meta("_drag_connected", true)
		item_border.mouse_default_cursor_shape = Control.CURSOR_MOVE
		# Показываем рамку ярче
		var style := item_border.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = Color(0.9, 0.7, 0.2, 0.8)
		item_border.add_theme_stylebox_override("panel", style)
	else:
		item_border.mouse_default_cursor_shape = Control.CURSOR_ARROW
		item_border.remove_theme_stylebox_override("panel")
		_save_item_pos(item_border)


var _dragging := false
var _drag_offset := Vector2.ZERO


func _on_item_border_input(event: InputEvent, item_border: PanelContainer) -> void:
	if not move_toggle.button_pressed:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = event.global_position - item_border.global_position
			else:
				_dragging = false
				_save_item_pos(item_border)
	elif event is InputEventMouseMotion and _dragging:
		var new_pos: Vector2 = event.global_position - _drag_offset
		item_border.global_position = new_pos
		# Двигаем лейбл под ним
		var name_label := _get_item_name_label()
		if name_label:
			name_label.global_position = Vector2(new_pos.x, new_pos.y + item_border.size.y + 8)


func _get_item_border() -> PanelContainer:
	var workshop := get_tree().get_first_node_in_group("workshop")
	if workshop:
		return workshop.get_node_or_null("ItemBorder") as PanelContainer
	return null


func _get_item_name_label() -> Label:
	var workshop := get_tree().get_first_node_in_group("workshop")
	if workshop:
		return workshop.get_node_or_null("ItemNameLabel") as Label
	return null


func _save_item_pos(item_border: PanelContainer) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("settings", "item_pos_x", item_border.offset_left)
	cfg.set_value("settings", "item_pos_y", item_border.offset_top)
	cfg.save("user://settings.cfg")


func _load_item_pos() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return
	var px: float = cfg.get_value("settings", "item_pos_x", -1.0)
	var py: float = cfg.get_value("settings", "item_pos_y", -1.0)
	if px < 0:
		return
	var item_border := _get_item_border()
	if item_border == null:
		return
	var w := item_border.size.x
	var h := item_border.size.y
	item_border.offset_left = px
	item_border.offset_top = py
	item_border.offset_right = px + w
	item_border.offset_bottom = py + h
	var name_label := _get_item_name_label()
	if name_label:
		name_label.offset_left = px
		name_label.offset_top = py + h + 8
		name_label.offset_right = px + w
		name_label.offset_bottom = py + h + 28
