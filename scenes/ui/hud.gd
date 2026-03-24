extends Control
## Главный HUD — объединяет все панели интерфейса.

@onready var items_counter: Label = $TopBar/HBox/ItemsCounter
@onready var tier_label: Label = $TopBar/HBox/TierLabel


func _ready() -> void:
	_apply_theme()
	Events.item_restored.connect(_on_item_restored)
	_update_counters()


func _apply_theme() -> void:
	# Пробуем загрузить тему из файла, если сгенерирована
	var theme_path := "res://assets/themes/game_theme.tres"
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path)
		return

	# Иначе создаём минимальную тему в коде
	var t := Theme.new()
	t.set_default_font_size(22)
	t.set_font_size("font_size", "Label", 22)
	t.set_font_size("font_size", "Button", 20)
	t.set_font_size("font_size", "TabContainer", 20)
	t.set_font_size("font_size", "ProgressBar", 16)
	t.set_color("font_color", "Label", Color(0.95, 0.92, 0.85))
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_color("font_color", "Button", Color(0.95, 0.92, 0.85))
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.42))

	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.35, 0.28, 0.18)
	btn.border_color = Color(0.6, 0.5, 0.3)
	btn.set_border_width_all(2)
	btn.set_corner_radius_all(4)
	btn.set_content_margin_all(8)
	t.set_stylebox("normal", "Button", btn)

	var btn_hover := btn.duplicate()
	btn_hover.bg_color = Color(0.45, 0.36, 0.22)
	btn_hover.border_color = Color(0.8, 0.7, 0.4)
	t.set_stylebox("hover", "Button", btn_hover)

	var btn_disabled := btn.duplicate()
	btn_disabled.bg_color = Color(0.22, 0.2, 0.17)
	btn_disabled.border_color = Color(0.35, 0.32, 0.28)
	t.set_stylebox("disabled", "Button", btn_disabled)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.12, 0.1, 0.08, 0.9)
	panel.border_color = Color(0.4, 0.35, 0.25)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(4)
	panel.set_content_margin_all(8)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)

	var tab_panel := panel.duplicate()
	tab_panel.set_content_margin_all(10)
	t.set_stylebox("panel", "TabContainer", tab_panel)
	t.set_color("font_selected_color", "TabContainer", Color(1, 0.95, 0.8))
	t.set_color("font_unselected_color", "TabContainer", Color(0.6, 0.55, 0.45))

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.12, 0.1)
	bar_bg.border_color = Color(0.4, 0.35, 0.25)
	bar_bg.set_border_width_all(2)
	bar_bg.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.4, 0.7, 0.3)
	bar_fill.set_corner_radius_all(2)
	t.set_stylebox("fill", "ProgressBar", bar_fill)

	t.set_constant("separation", "HBoxContainer", 10)
	t.set_constant("separation", "VBoxContainer", 6)

	theme = t


func _on_item_restored(_item: Resource, _reward: float, _masterwork: bool) -> void:
	_update_counters()


func _update_counters() -> void:
	items_counter.text = "Items: %d" % GameManager.items_restored
	tier_label.text = "Tier %d" % GameManager.current_tier
