extends Control
## Главный HUD — объединяет все панели интерфейса.

@onready var items_counter: Label = $TopBar/HBox/ItemsCounter
@onready var tier_label: Label = $TopBar/HBox/TierLabel
@onready var license_button: Button = $TopBar/HBox/LicenseButton
@onready var new_items_icon: Label = $TopBar/HBox/NewItemsIcon
@onready var bottom_panel: TabContainer = $BottomPanel
@onready var settings_button: Button = $TopBar/HBox/SettingsButton
@onready var settings_popup = $SettingsPopup

var _new_icon_blink: float = 0.0


func _ready() -> void:
	_apply_theme()
	Events.item_restored.connect(_on_item_restored)
	Events.tier_unlocked.connect(_on_tier_unlocked)
	Events.game_loaded.connect(_on_game_loaded)
	license_button.pressed.connect(_on_license_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_popup.setup(self)
	_update_counters()
	_update_license_button()


func _on_settings_pressed() -> void:
	settings_popup.visible = not settings_popup.visible


func _process(delta: float) -> void:
	# Мигание иконки NEW
	if new_items_icon.visible:
		_new_icon_blink += delta * 3.0
		var alpha := 0.6 + 0.4 * sin(_new_icon_blink)
		new_items_icon.modulate = Color(1, 0.9, 0.3, alpha)


func _on_license_pressed() -> void:
	# Переключаемся на вкладку Progression
	for i in bottom_panel.get_tab_count():
		if bottom_panel.get_tab_title(i) == "Progression":
			bottom_panel.current_tab = i
			break


func _on_tier_unlocked(_tier: int) -> void:
	_update_counters()
	_update_license_button()
	# Показываем иконку NEW
	new_items_icon.visible = true
	_new_icon_blink = 0.0
	# Скрываем через 10 секунд
	get_tree().create_timer(10.0).timeout.connect(func() -> void: new_items_icon.visible = false)


func _on_item_restored(_item: Resource, _reward: float, _masterwork: bool) -> void:
	_update_counters()


func _on_game_loaded() -> void:
	_update_counters()
	_update_license_button()


func _update_counters() -> void:
	items_counter.text = "Items: %d" % GameManager.items_restored
	tier_label.text = "Tier %d" % GameManager.current_tier


func _update_license_button() -> void:
	var config := GameManager.economy_config as EconomyConfig
	if config == null:
		license_button.visible = false
		return

	if GameManager.current_tier >= 8:
		license_button.text = "MAX TIER"
		license_button.disabled = true
		return

	var next_tier := GameManager.current_tier + 1
	var cost: float
	if next_tier < config.tier_unlock_costs.size():
		cost = config.tier_unlock_costs[next_tier]
	else:
		cost = config.tier_unlock_costs[-1] * pow(3.0, next_tier - config.tier_unlock_costs.size() + 1)

	license_button.text = "Tier %d: $%s" % [next_tier, Format.money(cost)]
	license_button.tooltip_text = "Open Progression tab to buy Tier %d license" % next_tier


func _apply_theme() -> void:
	var theme_path := "res://assets/themes/game_theme.tres"
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path)
		return

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
